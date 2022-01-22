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
    "#{date} #{size} #{operator} #{'%.2f' % format_price} #{format_discount}"
  end

  def year_month
    date.strftime('%Y-%m')
  end

  def large_la_poste?
    operator == :LP && size == :L
  end

  private

  def format_price
    return price - discount if discount.positive?

    price
  end

  def format_discount
    discount.positive? ? '%.2f' % discount : '-'
  end
end
