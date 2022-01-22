# frozen_string_literal: true

require './src/order_processor'

RSpec.describe OrderProcessor do
  subject { described_class.new.run }

  let(:expected_output) { File.read('output.txt') }

  it 'prints expected output' do
    expect { subject }.to output(expected_output).to_stdout
  end
end
