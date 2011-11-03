require 'mys3ql/shell'

module Mys3ql
  class Mysql
    include Shell

    def initialize(config)
      @config = config
    end

    #
    # dump
    #

    def dump
      cmd  = "#{@config.bin_path}mysqldump"
      cmd += ' --quick --single-transaction --create-options'
      cmd += ' --flush-logs --master-data=2 --delete-master-logs' if binary_logging?
      cmd += cli_options
      cmd += " | gzip > #{dump_file}"
      run cmd
    end

    def dump_file
      @dump_file ||= "#{timestamp}.sql.gz"
    end

    def delete_dump
      File.delete dump_file
      log "mysql: deleted #{dump_file}"
    end

    #
    # bin_logs
    #

    # flushes logs, loops over each one yielding it to the block
    def each_bin_log(&block)
      execute 'flush logs'
      logs = Dir.glob("#{@config.bin_log}.[0-9]*").sort_by { |f| f[/\d+/].to_i }
      logs_to_backup = logs[0..-2]  # all logs except the last, which is in use
      logs_to_backup.each do |log_file|
        yield log_file
      end
      execute "purge master logs to '#{File.basename(logs[-1])}'"
    end

    #
    # restore
    #

    def restore(file)
      run "gunzip -c #{file} | #{@config.bin_path}mysql #{cli_options}"
    end

    def apply_bin_log(file)
      cmd  = "#{@config.bin_path}mysqlbinlog --database=#{@config.database} #{file}"
      cmd += " | #{@config.bin_path}mysql -u'#{@config.user}'"
      cmd += " -p'#{@config.password}'" if @config.password
      run cmd
    end

    private

    def timestamp
      Time.now.utc.strftime "%Y%m%d%H%M"
    end

    def binary_logging?
      @config.bin_log && @config.bin_log.length > 0
    end

    def cli_options
      cmd  = " -u'#{@config.user}'"
      cmd += " -p'#{@config.password}'" if @config.password
      cmd += " #{@config.database}"
    end

    def execute(sql)
      run %Q(#{@config.bin_path}mysql -e "#{sql}" #{cli_options})
    end

  end
end
