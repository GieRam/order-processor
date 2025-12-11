# frozen_string_literal: true

module DiscountRules
  class LowestSPrice
    def initialize(order, _counts)
      @order = order
    end

    def self.call(order, _counts)
      new(order, _counts).call
    end

    def call
      return 0 unless applicable?

      discount
    end

    private

    attr_reader :order

    def applicable?
      order.size == :S
    end

    def discount
      order.price - LOWEST_S_PRICE
    end
  end
end
