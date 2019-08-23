# frozen_string_literal: true

require 'ddlambda'

describe DDLambda do
  it 'should return the same value as returned by wrap' do
    event = '1'
    context = '2'
    res = DDLambda.wrap(event, context) do
      { result: 100 }
    end
    expect(res[:result]).to be 100
  end
  it 'should raise an error if the block raises an error' do
    error_raised = false
    begin
      DDLambda.wrap(event, context) do
        raise 'Error'
      end
    rescue StandardError
      error_raised = true
    end
    expect(error_raised).to be true
  end
end