require 'benchmark'

module AMS
  class << self
    # Accessor for logger used by AMS
    def logger
      @logger ||= Logger.new(STDOUT).tap do |logger|
        # Simplify the formatter to just be the message with newlines.
        logger.formatter = -> (_severity, _datetime, _progname, msg) { "\n#{msg}\n" }
        logger.level = ENV.fetch('AMS_LOG_LEVEL', Logger::WARN).to_i
      end
    end

    def reset_data!
      time = Benchmark.realtime do
        logger.info 'Checking to see if Fedora is working...'
        ensure_fedora_is_working
        logger.info 'Checking for migrations...'
        run_migrations!
        logger.info 'Cleaning the database...'
        clean_database!
        logger.info 'Cleaning the repository...'
        clean_solr_and_fedora!
        logger.info 'Flushing Redis cache...'
        flush_redis_cache!
        logger.info 'Loading seed data...'
        Seed.all
      end
      logger.info "Data reset complete in #{time.round(3)} seconds"
    end

    def seeds; Seed; end

    # private

      def fedora_status
        response = ActiveFedora.fedora.connection.head(ActiveFedora.fedora.base_uri)
        response.response.status.to_i
      rescue
        nil
      end

      def ensure_fedora_is_working
        r = fedora_status
        if r == nil
          raise "Fedora must be running"
        elsif !r.between?(200,399)
          raise "Fedora is not working properly, and is returning an HTTP status of #{fedora_status}"
        end
      end

      def clean_database!
        require 'database_cleaner'
        DatabaseCleaner.clean_with :truncation
      end

      def clean_solr_and_fedora!
        require 'active_fedora/cleaner'
        ActiveFedora::Cleaner.clean!
      end

      def run_migrations!
        ActiveRecord::Migration.migrate(:up) if ActiveRecord::Migration.check_pending!
      end

      def flush_redis_cache!
        Redis.new(host: ENV.fetch('REDIS_HOST', 'localhost'), port: '6379').flushall
      end


    module Seed
      class << self
        def all
          {
            admin_user: admin_user,
            admin_role: admin_role,
            aapb_admin_role: aapb_admin_role,
            admin_set: admin_set
          }
        end

        def admin_user
          user = User.find_by email: "wgbh_admin@wgbh-mla.org"
          return user if user
          User.create!(email: "wgbh_admin@wgbh-mla.org", password: "pppppp")
        end

        def admin_role
          role = Role.find_by name: 'admin'
          return role if role
          Role.create!(name:'admin', users: [admin_user])
        end

        def aapb_admin_role
          role = Role.find_by name: 'aapb-admin'
          return role if role
          Role.create!(name: 'aapb-admin', users: [admin_user])
        end

        def admin_set
          AdminSet.find_or_create_default_admin_set_id
        end
      end
    end
  end
end
