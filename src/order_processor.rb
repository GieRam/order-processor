# frozen_string_literal: true

require 'date'
require './src/order'
require './src/invalid_order'
require './src/constants'
require './src/counts_repository'
require './src/discount_rules/lowest_s_price'
require './src/discount_rules/large_la_poste'

class OrderProcessor
  attr_reader :counts, :lowest_s_price, :orders_file

  DISCOUNT_RULES = [
    DiscountRules::LowestSPrice,
    DiscountRules::LargeLaPoste
  ].freeze

  def initialize(orders_file = 'input.txt')
    @orders_file = orders_file
    @counts = CountsRepository.new
  end

  def run
    File.readlines(orders_file)
        .map { |line| line.split(SEPARATOR) }
        .map { |order_args| Order.from(order_args) }
        .each { |order| apply_discount(order) }
        .each { |order| puts order }
  end

  private

  def apply_discount(order)
    discount = DISCOUNT_RULES.map { |rule| rule.call(order, counts) }.max
    limit_discount(order, discount)
  end

  def limit_discount(order, discount)
    monthly_total = counts.monthly_total_for(order.year_month) + discount
    discount -= (monthly_total - MONTHLY_DISCOUNT_LIMIT) if monthly_total >= MONTHLY_DISCOUNT_LIMIT
    counts.add_monthly_total(order.year_month, discount)
    order.discount = discount
  end
end
