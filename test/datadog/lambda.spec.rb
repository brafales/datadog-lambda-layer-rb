# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

require 'datadog/lambda'
require_relative './lambdacontext'

describe Datadog::Lambda do
  ctx = LambdaContext.new
  context 'enhanced tags' do
    it 'recognizes a cold start' do
      expect(Datadog::Lambda.gen_enhanced_tags(ctx)[:cold_start]).to eq(true)
    end
  end
  context 'with a handler that raises an error' do
    subject { Datadog::Lambda.wrap(event, context) { raise 'Error' } }
    let(:event) { '1' }
    let(:context) { ctx }

    it 'should raise an error if the block raises an error' do
      expect { subject }.to raise_error
    end
  end
  context 'enhanced tags' do
    it 'recognizes an error as having warmed the environment' do
      expect(Datadog::Lambda.gen_enhanced_tags(ctx)[:cold_start]).to eq(false)
    end
  end
  context 'with a succesful handler' do
    subject { Datadog::Lambda.wrap(event, context) { { result: 100 } } }
    let(:event) { '1' }
    let(:context) { ctx }

    it 'should return the same value as returned by the block' do
      expect(subject[:result]).to be 100
    end
  end
  context 'trace_context' do
    it 'should return the last trace context' do
      event = {
        'headers' => {
          'x-datadog-trace-id' => '12345',
          'x-datadog-parent-id' => '45678',
          'x-datadog-sampling-priority' => '2'
        }
      }
      Datadog::Lambda.wrap(event, ctx) do
        { result: 100 }
      end
      expect(Datadog::Lambda.trace_context).to eq(
        trace_id: '12345',
        parent_id: '45678',
        sample_mode: 2
      )
    end
  end
  context 'enhanced tags' do
    it 'makes tags from a Lambda context' do
      ctx = LambdaContext.new
      expect(Datadog::Lambda.gen_enhanced_tags(ctx)).to eq(
        account_id: '172597598159',
        cold_start: false,
        functionname: 'hello-dog-ruby-dev-helloRuby25',
        memorysize: 128,
        region: 'us-east-1',
        runtime: 'Ruby 2.5.7'
      )
    end
  end
  context 'metric' do
    it 'prints a custom metric' do
      now = Time.utc(2008, 7, 8, 9, 10)

      # rubocop:disable Metrics/LineLength
      output = '{"e":1215508200,"m":"m1","t":["dd_lambda_layer:datadog-ruby25","t.a:val","t.b:v2"],"v":100}'
      # rubocop:enable Metrics/LineLength
      expect(Time).to receive(:now).and_return(now)
      expect do
        Datadog::Lambda.metric('m1', 100, "t.a": 'val', "t.b": 'v2')
      end.to output("#{output}\n").to_stdout
    end
    it 'prints a custom metric with a custom timestamp' do
      custom_time = Time.utc(2008, 7, 8, 9, 11)
      # rubocop:disable Metrics/LineLength
      output = '{"e":1215508260,"m":"m1","t":["dd_lambda_layer:datadog-ruby25","t.a:val","t.b:v2"],"v":100}'
      expect do
        Datadog::Lambda.metric('m1', 100, time: custom_time, "t.a": 'val', "t.b": 'v2')
      end.to output("#{output}\n").to_stdout
      # rubocop:enable Metrics/LineLength
    end
  end
end

# rubocop:enable Metrics/BlockLength
