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
      # --master-data=2         include the current binary log coordinates in the log file
      # --delete-master-logs    delete binary log files
      cmd  = "#{@config.bin_path}mysqldump"
      cmd += ' --quick --single-transaction --create-options --no-tablespaces'
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

    # flushes logs, yields each bar the last to the block
    def each_bin_log(&block)
      # FLUSH LOGS    Closes and reopens any log file, including binary logs,
      #               to which the server is writing.  For binary logs, the sequence
      #               number of the binary log file is incremented by one relative to
      #               the previous file.
      #               https://dev.mysql.com/doc/refman/5.7/en/flush.html#flush-logs
      #               https://dev.mysql.com/doc/refman/5.7/en/flush.html#flush-binary-logs
      execute 'flush logs'
      Dir.glob("#{@config.bin_log}.[0-9]*")
         .sort_by { |f| f[/\d+/].to_i }
         .slice(0..-2)  # all logs except the last, which is newly created
         .each do |log_file|
        yield log_file
      end
    end

    #
    # restore
    #

    def restore(file)
      run "gunzip -c #{file} | #{@config.bin_path}mysql #{cli_options}"
    end

    def apply_bin_logs(*files)
      return if files.empty?
      cmd  = "#{@config.bin_path}mysqlbinlog --database=#{@config.database} #{files.join ' '}"
      cmd += " | #{@config.bin_path}mysql -u'#{@config.user}'"
      cmd += " -p'#{@config.password}'" if @config.password
      cmd += " -h #{@config.host}" if @config.host
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
      cmd += " -h #{@config.host}" if @config.host
      cmd += " #{@config.database}"
    end

    def execute(sql)
      run %Q(#{@config.bin_path}mysql -e "#{sql}" #{cli_options})
    end

  end
end
