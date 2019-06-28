require 'sidekiq/api'
require 'open3'

module AMS
  class ToggleSidekiq
    attr_reader :env, :project_dir

    def initialize(logger: nil, env: nil, project_dir: nil)
      self.logger = logger if logger
      configure_redis
      @env = env || ENV['RAILS_ENV'] || 'development'
      @project_dir = project_dir || File.expand_path('../../../', __FILE__)
    end

    def is_running?
      sidekiq_pids.count > 0
    end

    def turn_on(count: 3, reset: true)
      turn_off if reset && is_running?
      logger.info "Turning on Sidekiq..."
      count = count.to_i
      logger.info "Starting #{count} Sidekiq processes..."
      count.times { start_sidekiq_process }
      wait_for_processes_to_start(count: count)
      logger.info "Started #{sidekiq_pids.count} Sidekiq processes."
    end

    def turn_off
      logger.info "Turning off Sidekiq..."
      if is_running?
        quiet_all_processes
        wait_for_workers_to_finish
        stop_all_processes
      end
      logger.info "Sidekiq turned off, hoo-ray!"
    end

    protected

      def logger=(logger)
        raise ArgumentError, "Logger object expected but #{logger.class} was given" unless logger.is_a? Logger
        @logger = logger
      end

      def logger
        @logger ||= Logger.new(STDOUT)
      end

    private

      def start_sidekiq_process
        fork do
          Dir.chdir project_dir do
            run_command start_sidekiq_cmd
            Process.daemon
          end
        end
        logger.info "Started Sidekiq processor in forked process."
      end


      def quiet_all_processes
        logger.info "Quieting #{sidekiq_pids.count} Sidekiq processes..."
        sidekiq_pids.each do |pid|
          run_command quiet_sidekiq_cmd(pid)
        end
        logger.info "#{sidekiq_pids.count} Sidekiq processes quieted."
      end

      def wait_for_processes_to_start(count:)
        loop do
          break if sidekiq_pids.count == count
          logger.info "#{sidekiq_pids.count} of #{count} Sidekiq processes started. Waiting..."
          sleep 3
        end
      end

      def wait_for_workers_to_finish
        workers = Sidekiq::Workers.new
        return if workers.count == 0
        while workers.count > 0
          logger.info "Waiting for #{workers.count} workers to finish..."
          sleep 10
        end
        logger.info "All workers finished."
      end

      def stop_all_processes
        count = sidekiq_pids.count
        logger.info "Stopping #{count} Sidekiq processes..."
        sidekiq_pids.each do |pid|
          run_command stop_sidekiq_cmd(pid)
        end
        while sidekiq_pids.count > 0 do
          logger.info 'stopping...'
          sleep 2
        end
        logger.info "#{count} Sidekiq processes stopped."
      end

      # Runs a system command with some nice logging around it.
      def run_command(command)
        logger.info "Running: #{command}"
        `#{command}`
      end

      def start_sidekiq_cmd
        "bundle exec sidekiq -e #{env} > log/sidekiq.log 2>&1"
      end

      def stop_sidekiq_cmd(pid)
        "kill #{pid}"
      end

      def quiet_sidekiq_cmd(pid)
        "kill -TSTP #{pid}"
      end

      def sidekiq_pids
        # NOTE: This command has been tested on OSX and Amazon linux.
        `ps aux | egrep 'sidekiq.*\[[0-9]+ of [0-9]+ busy\]' | awk '{print $2}'`.split(/\s/)
      end

      def configure_redis
        Sidekiq.configure_server do |s|
          s.redis = redis_conn
        end
        Sidekiq.configure_client do |s|
          s.redis = redis_conn
        end
      end

      def redis_conn
        @redis_conn ||= { url: "redis://#{ENV.fetch('REDIS_SERVER', 'localhost')}:6379/", network_timeout: 5 }
      end
  end
end
