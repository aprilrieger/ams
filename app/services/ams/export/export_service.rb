require_relative '../../../../lib/ams/aapb'

module AMS
  module Export
    class ExportService
      attr_reader :solr_documents
      attr_reader :format
      attr_reader :filename
      attr_reader :file_path
      attr_reader :s3_path
      attr_reader :object_type


      def initialize(solr_documents, options={}, format, filename)
        @solr_documents = solr_documents
        @format = format
        @filename = if filename.nil?
                      "export-#{Time.now.strftime('%m_%d_%Y_%H:%M')}.#{format}"
                    else
                      filename
                    end
        @object_type = options[:object_type] || nil
        @file_path = Tempfile.new([@filename, ".#{@format}"])
        @s3_path = nil
      end

      def process
        begin
          process_export
          yield
        ensure
          @file_path.close
          @file_path.unlink # deletes the temp file.
        end
      end

      def upload_to_s3
        Aws.config.update(
          region: 'us-east-1',
          credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY'], ENV['AWS_SECRET_KEY'])
        )
        s3 = Aws::S3::Resource.new(region: 'us-east-1')

        export_file = File.read(@file_path)
        # send file to s3
        obj = s3.bucket(ENV['S3_EXPORT_BUCKET']).object("#{ENV['S3_EXPORT_DIR']}/#{SecureRandom.uuid}/#{@filename}")
        File.open(@file_path, 'r') do |f|
          obj.upload_file(f, acl: 'public-read', content_disposition: 'attachment')
        end
        @s3_path = obj.public_url
      end

      def scp_to_aapb(user)
        # aapb_key_path = '-i /home/ec2-user/.ssh/aapb-zip-key.pem'
        aapb_key_path = ""
        filepath = @file_path.path
        filename = File.basename(@file_path.path)

        if aapb_key_path && AMS::AAPB.reachable? && filepath.present?
          aapb_host = AMS::AAPB.host
          output = []

          output << `scp #{aapb_key_path} #{filepath} ec2-user@#{aapb_host}:/home/ec2-user/ingest_zips/#{filename}`
          output << `ssh -t #{aapb_key_path} ec2-user@#{aapb_host} 'cd /home/ec2-user/ingest_zips && unzip -o #{filename}'`
          output << `ssh -t #{aapb_key_path} ec2-user@#{aapb_host} 'cd /var/www/aapb/current && RAILS_ENV=production ~/bin/bundle exec /usr/bin/ruby scripts/download_clean_ingest.rb --stdout-log --files /home/ec2-user/ingest_zips/*.xml'`

          # TODO clean the dir?
          #  && cd /home/ec2-user/ingest_zips && rm -v ./*

          # print and email
          Rails.logger.info output
          Ams2Mailer.scp_to_aapb_notification(user, output.join("\n\n")).deliver_later
        else
          raise "AAPB was unreachable! #{ENV['AAPB_HOST']}"
        end
        
      end
    end
  end
end
