# frozen_string_literal: true

module DiscountRules
  class LargeLaPoste
    def initialize(order, counts)
      @order = order
      @counts = counts
    end

    def self.call(order, counts)
      new(order, counts).call
    end

    def call
      return 0 unless order.large_la_poste? # Applies when order is large la poste

      counts.increment_l_lp_count(order.year_month) *
      counts.l_lp_threshold?(order.year_month) ? large_package_price : 0
    end

    private

    attr_reader :order, :counts

    def large_package_price
      price = 0
      PROVIDER_PRICES.each do |provider, prices|
        if provider == :LP && prices.keys.include?(order.size)
          price = prices[order.size]
        end
      end
      price
    end
  end
end