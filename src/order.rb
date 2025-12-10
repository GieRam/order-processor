# frozen_string_literal: true

require './src/constants'
require './src/invalid_order'

# Contains details for an item to be sent via parcel service.
class Order
  attr_reader :date, :size, :operator, :price
  attr_accessor :discount

  def initialize(date, size, operator)
    @date = date
    @size = size
    @operator = operator
    @price = PROVIDERS[operator][size]
  end

  def self.from(order_args)
    return InvalidOrder.new(order_args) unless valid?(order_args)

    Order.new(Date.iso8601(order_args[0]), order_args[1].to_sym, order_args[2].to_sym)
  end

  def self.valid?(order_args)
    Date.iso8601(order_args[0]) &&
      SIZES.include?(order_args[1].to_sym) &&
      PROVIDERS.keys.include?(order_args[2].to_sym)
  rescue ArgumentError
    false
  end

  def to_s
    "#{date} #{size} #{operator} #{formatted_price} #{formatted_discount}"
  end

  def year_month
    date.strftime('%Y-%m')
  end

  def large_la_poste?
    operator == :LP && %i[L XL].include?(size)
  end

  private

  def formatted_price
    format_amount(price - discount || 0)
  end

  def formatted_discount
    discount.positive? ? format_amount(discount) : '-'
  end

  def format_amount(amount)
    '%.2f' % amount.to_f
  end
end
