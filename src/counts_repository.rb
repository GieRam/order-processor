# frozen_string_literal: true

require './src/constants'

# Holds counts necessary for order processing.
# In a production application I would use a database such as Redis to hold this data.
class CountsRepository
  def initialize
    @counts = {
      l_lp_count: {},
      monthly_total: {}
    }.freeze
  end

  def l_lp_count(year_month)
    counts[:l_lp_count][year_month] ||= 0
  end

  def l_lp_threshold?(year_month)
    counts[:l_lp_count][year_month] == L_LP_RULE_THRESHOLD
  end

  def increment_l_lp_count(year_month)
    counts[:l_lp_count][year_month] = l_lp_count(year_month) + 1
  end

  def monthly_total(year_month)
    counts[:monthly_total][year_month] ||= 0
  end

  def add_monthly_total(year_month, discount)
    counts[:monthly_total][year_month] += discount
  end

  private

  attr_reader :counts
end
