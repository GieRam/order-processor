require './src/invalid_order'

RSpec.describe InvalidOrder do
  let(:order_args) { ['2015-02-29', 'XS', 'LP'] }
  subject(:invalid_order) { described_class.new(order_args) }

  describe '#to_s' do
    it 'returns the original order line with Ignored appended' do
      expect(invalid_order.to_s).to eq('2015-02-29 XS LP Ignored')
    end
  end

  describe '#year_month' do
    it 'returns false' do
      expect(invalid_order.year_month).to eq(false)
    end
  end

  describe '#large_la_poste?' do
    it 'returns false' do
      expect(invalid_order.large_la_poste?).to eq(false)
    end
  end

  describe '#discount' do
    it 'defaults to 0' do
      expect(invalid_order.discount).to eq(0)
    end

    it 'can be set to another value' do
      invalid_order.discount = 5.0
      expect(invalid_order.discount).to eq(5.0)
    end
  end

  describe '#size' do
    it 'defaults to false' do
      expect(invalid_order.size).to eq(false)
    end

    it 'can be set to another value' do
      invalid_order.size = :S
      expect(invalid_order.size).to eq(:S)
    end
  end
end
