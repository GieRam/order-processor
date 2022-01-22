# frozen_string_literal: true

require './src/constants'

# NullObject pattern
class InvalidOrder
  attr_accessor :discount, :size

  def initialize(order_args)
    @line = order_args.join(SEPARATOR)
    @size = false
    @discount = 0
  end

  def year_month
    false
  end

  def large_la_poste?
    false
  end

  def to_s
    "#{line} Ignored"
  end

  private

  attr_reader :line
end
