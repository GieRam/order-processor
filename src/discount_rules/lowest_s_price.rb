module DiscountRules
  class LowestSPrice
    def initialize(order, _counts)
      @order = order
    end

    def self.call(order, counts)
      new(order, counts).call
    end

    def call
      return 0 unless applies?

      order.price - LOWEST_S_PRICE
    end

    private

    attr_reader :order

    def applies?
      order.size == :S
    end
  end
end
