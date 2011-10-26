require 'mys3ql/version'
require 'mys3ql/config'
require 'fog'

module Mys3ql
  extend self

  def usage
    <<END
usage:
  mys3ql full    - full backup, push to S3
  mys3ql inc     - push bin logs to S3
END
  end

  def configure
    @config = Config.new
  end

  def debugging?
    true
  end

  def debug(message)
    puts message if debugging?
  end

  def execute(command)
    debug "#{command}"
    success = system command
    unless success
      $stderr.puts "failure: #{command}: #{$?}"
      exit 1
    end
  end

  #
  # MySQL
  #

  def timestamp
    Time.now.utc.strftime "%Y%m%d%H%M"
  end

  def dump_file
    @dump_file ||= "#{timestamp}.sql.gz"
  end

  def binary_logging?
    @config.bin_log && @config.bin_log.length > 0
  end

  def dump
    cmd  = "#{@config.bin_path}mysqldump -u'#{@config.user}'"
    cmd += " -p'#{@config.password}'" if @config.password
    cmd += " --quick --single-transaction --create-options"
    cmd += ' --flush-logs --master-data=2 --delete-master-logs' if binary_logging?
    cmd += " #{@config.database} | gzip > #{dump_file}"
    execute cmd
  end

  def clean_up_dump
    File.delete dump_file
    debug "deleted #{dump_file}"
  end

  #
  # S3
  #

  def s3
    @s3 ||= begin
      s = Fog::Storage.new(
        :provider              => 'AWS',
        :aws_secret_access_key => @config.secret_access_key,
        :aws_access_key_id     => @config.access_key_id
      )
      debug 'connected to s3'
      s
    end
  end

  def bucket
    @directory ||= begin
      d = s3.directories.get @config.bucket  # assume bucket exists
      debug "opened bucket #{@config.bucket}"
      d
    end
  end

  # returns Fog::Storage::AWS::File if we pushed, nil otherwise.
  def push_to_s3(local_file_name, s3_key)
    unless bucket.files.head(s3_key)
      s3_file = bucket.files.create(
        :key    => s3_key,
        :body   => File.open(local_file_name),
        :public => false
      )
      debug "pushed #{local_file_name} to #{s3_key}"
      s3_file
    end
  end

  def push_dump_to_s3
    key = "#{@config.database}/dumps/#{dump_file}"
    copy_key = "#{@config.database}/dumps/latest.sql.gz"
    s3_file = push_to_s3 dump_file, key
    if s3_file
      s3_file.copy @config.bucket, copy_key
      debug "copied #{key} to #{copy_key}"
    end
  end

  def push_bin_logs_to_s3
    if binary_logging?
      Dir["#{@config.bin_log}/*"].each do |file|
        name = File.basename file
        key = "#{@config.database}/bin_logs/#{name}"
        push_to_s3 file, key
      end
    end
  end

  def delete_bin_logs_on_s3
    bucket.files.all(:prefix => "#{@config.database}/bin_logs/").each do |file|
      file.destroy
      debug "destroyed #{file.key}"
    end
  end

  #
  # Coordination
  #

  def run(args)
    abort usage unless args.length == 1 && %w[ full inc ].include?(args.first)
    configure
    command = args.first
    if command == 'full'
      full
    else
      incremental
    end
  end

  def full
    dump
    push_dump_to_s3
    clean_up_dump
    delete_bin_logs_on_s3
  end

  def incremental
    push_bin_logs_to_s3
  end
end
