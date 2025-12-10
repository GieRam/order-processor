# frozen_string_literal: true

require './src/invalid_order'

RSpec.describe InvalidOrder do
  subject { described_class.new(['2025-01-01', 'S', 'LP']).to_s }

  it 'returns the expected output' do
    expect(subject).to eq('2025-01-01 S LP Ignored')
  end
end