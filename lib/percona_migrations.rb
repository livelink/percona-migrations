require 'percona_migrations/version'
require 'percona_migrations/runners'
require 'percona_migrations/helper_methods'

require 'active_record'
require 'logger'
require 'shellwords'

module PerconaMigrations
  extend self

  @allow_sql = true

  @config = Struct.new('PerconaConfig',
                       :charset,
                       :check_interval,
                       :check_alter,
                       :check_plan,
                       :check_replication_filters,
                       :check_slave_lag,
                       :chunk_index,
                       :chunk_index_columns,
                       :chunk_size,
                       :chunk_size_limit,
                       :chunk_time,
                       :critical_load,
                       :default_engine,
                       :defaults_file,
                       :drop_new_table,
                       :drop_old_table,
                       :lock_wait_timeout,
                       :max_lag,
                       :max_load,
                       :pid,
                       :print,
                       :progress,
                       :quiet,
                       :recurse,
                       :recursion_method,
                       :retries,
                       :set_vars,
                       :statistics,
                       :swap_tables
                       ).new

  attr_writer :database_config, :allow_sql, :logger

  def config
    if block_given?
      yield @config
    else
      @config
    end
  end

  def pt_schema_tool_args(options: {})
    @config.members.map do |key|
      val = options.key?(key) ? options[key] : config[key]
      arg = key.to_s.gsub(/_/,'-')

      case val
      when nil
        nil
      when true
        "--#{arg}"
      when false
        "--no-#{arg}"
      else
        "--#{arg} #{Shellwords.escape(val)}"
      end
    end.compact.join(' ')
  end

  def database_config
    @database_config || raise('PerconaMigrations.database_config is not set.')
  end

  def allow_sql?
    !!@allow_sql
  end

  def logger
    unless defined? @logger
      @logger = Logger.new($stdout)
      @logger.formatter = proc do |severity, datetime, progname, msg|
        "[percona-migrations] #{msg}\n"
      end
    end

    @logger
  end
end
