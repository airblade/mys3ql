require 'yaml'

module Mys3ql
  class Config

    def initialize
      @config = YAML.load_file config_file
    rescue Errno::ENOENT
      $stderr.puts "missing ~/.mys3ql config file"
      exit 1
    end

    #
    # MySQL
    #

    def user
      mysql['user']
    end

    def password
      mysql['password']
    end

    def database
      mysql['database']
    end

    def bin_path
     mysql['bin_path']
    end

    def bin_log
      mysql['bin_log']
    end

    #
    # S3
    #

    def access_key_id
      s3['access_key_id']
    end

    def secret_access_key
      s3['secret_access_key']
    end

    def bucket
      s3['bucket']
    end

    private

    def mysql
      @config['mysql']
    end

    def s3
      @config['s3']
    end

    def config_file
      File.join "#{ENV['HOME']}", '.mys3ql'
    end
  end
end
