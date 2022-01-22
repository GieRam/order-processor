# frozen_string_literal: true

require 'date'
require './src/order'
require './src/invalid_order'
require './src/constants'
require '../src/counts_repository'

class OrderProcessor
  attr_reader :counts, :lowest_s_price, :orders_file

  DISCOUNT_RULES = {
    ->(order) { order.size == :S } => ->(order, _counts) { order.price - LOWEST_S_PRICE },
    ->(order) { order.large_la_poste? } => lambda do |order, counts|
      counts.increment_l_lp_count(order.year_month)
      counts.l_lp_threshold?(order.year_month) ? PROVIDERS[:LP][:L] : 0
    end,
    ->(_order) { true } => ->(_order, _counts) { 0 }
  }.freeze

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
    rule = DISCOUNT_RULES.find { |predicate, _rule| predicate.call(order) }[1]
    limit_discount(order, rule.call(order, counts))
  end

  def l_lp_predicate(order)
    order.large_la_poste? && counts[:l_lp_count][order.year_month] == 2
  end

  def limit_discount(order, discount)
    monthly_total = counts.monthly_total(order.year_month) + discount
    discount -= (monthly_total - MONTHLY_DISCOUNT_LIMIT) if monthly_total >= MONTHLY_DISCOUNT_LIMIT
    counts.add_monthly_total(order.year_month, discount)
    order.discount = discount
  end
end
