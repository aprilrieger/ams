require 'redis'
config = YAML.safe_load(ERB.new(IO.read(Rails.root.join('config', 'redis.yml'))).result)[Rails.env].with_indifferent_access
Redis.current = begin
                  Redis.new(config.merge(thread_safe: true))
                rescue
                  nil
                end
