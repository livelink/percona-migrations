module PerconaMigrations
  module Runners
    class Percona < Base
      COMMAND = 'pt-online-schema-change'

      def self.available?
        !percona_command.empty?
      end

      def self.percona_command
        @percona_command ||= %x(which #{COMMAND}).chop
      end

      def run
        params = [
          PerconaMigrations.pt_schema_tool_args(options: @options),
          "--alter '#{@commands.join(', ')}'",
          "-h #{database_config['host']}",
          "-P #{database_config['port']}",
          "-u #{database_config['username']}",
          "D=#{database_config['database']},t=#{@table_name}"
        ]

        password = database_config['password']
        if password && !password.empty?
          params << "-p $PASSWORD"
        end

        run_command(params.reject(&:empty?).join(' '), { 'PASSWORD' => password })
      end

      private

      def database_config
        PerconaMigrations.database_config
      end

      def run_command(params, env_vars = {})
        %w(dry-run execute).each do |mode|
          cmd = "#{self.class.percona_command} #{params} --#{mode}"

          log "Running percona command: \"#{cmd}\""

          unless system(env_vars, cmd)
            raise "Percona command failed: #{$?}"
          end
        end
      end
    end
  end
end
