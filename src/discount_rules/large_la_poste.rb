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
      return 0 unless order.large_la_poste?

      counts.increment_l_lp_count(order.year_month)
      price
    end

    private

    attr_reader :order, :counts

    def price
      threshold_met? ? PROVIDER_PRICES[:LP][:L] : 0
    end

    def threshold_met?
      counts.l_lp_threshold?(order.year_month)
    end
  end
end

