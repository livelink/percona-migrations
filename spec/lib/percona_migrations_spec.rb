require 'spec_helper'

RSpec.describe PerconaMigrations do
  describe '::allow_sql?' do
    it 'is true by default' do
      expect(subject.allow_sql?).to eq(true)
    end

    it 'can be set to false' do
      subject.allow_sql = false

      expect(subject.allow_sql?).to eq(false)

      subject.allow_sql = true
    end
  end

  describe '::database_config' do
    it 'throws an exception if not set' do
      expect { subject.database_config }.to raise_exception
    end

    it 'returns config' do
      config = { 'username' => 'test' }
      subject.database_config = config

      expect(subject.database_config).to eq(config)

      subject.database_config = nil
    end
  end

  describe '::config' do
    before do
      subject.instance_eval { @config = @config.class.new }
    end
    it 'yields a block' do
      expect { |b| subject.config(&b) }.to yield_control.once
    end
    it 'allows config to be set' do
      subject.config { |c| c.max_load = 'Threads_running=25' }
      expect(subject.config.max_load).to eq('Threads_running=25')
    end
    it 'ignores unset values' do
      expect(subject.config.retries).to be(nil)
    end
    it 'returns no arguments by default' do
      expect(subject.pt_schema_tool_args).to be_empty
    end

    context 'with boolean config' do
      before do
        subject.config do |c|
          c.statistics = true
          c.drop_old_table = false
        end
      end
      it 'returns arguments' do
        expect(subject.pt_schema_tool_args).to eq('--no-drop-old-table --statistics')
      end
    end
    context 'with config' do
      before do
        subject.config do |c|
          c.max_load = 'Threads_running=25'
        end
      end
      it 'returns arguments' do
        expect(subject.pt_schema_tool_args).to eq('--max-load Threads_running\\=25')
      end
    end
  end

  describe '::pt_schema_tool_args' do
    before do
      subject.instance_eval { @config = @config.class.new }
      subject.config do |c|
        c.statistics = true
        c.drop_old_table = false
      end
    end

    it 'returns arguments, overriding any conflicting config settings' do
      options = { drop_new_table: false }
      expect(subject.pt_schema_tool_args(options: options)).to eq(
        '--no-drop-new-table --no-drop-old-table --statistics'
      )
    end

    it 'returns arguments, overriding any conflicting config settings' do
      options = { drop_old_table: true, drop_new_table: false }
      expect(subject.pt_schema_tool_args(options: options)).to eq(
        '--no-drop-new-table --drop-old-table --statistics'
      )
    end
  end
end
