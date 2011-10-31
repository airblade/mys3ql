require 'mys3ql/config'
require 'mys3ql/mysql'
require 'mys3ql/s3'

module Mys3ql
  class Conductor

    def self.run(options)
      conductor = Conductor.new(options['config'])
      conductor.debug = options[:debug]

      if options['full']
        conductor.full
      elsif options['incremental']
        conductor.incremental
      end
    end

    def initialize(config_file = nil)
      @config = Config.new(config_file)
      @mysql = Mysql.new @config
      @s3 = S3.new @config
    end

    def full
      @mysql.dump
      @s3.push_dump_to_s3 @mysql.dump_file
      @mysql.clean_up_dump
      @s3.delete_bin_logs_on_s3
    end

    def incremental
      @s3.push_bin_logs_to_s3
    end

    def debug=(val)
      @config.debug = val
    end
  end
end
