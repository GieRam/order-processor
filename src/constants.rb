# frozen_string_literal: true

# Provider: Prices in EUR.
# LP - La Poste
# MR - Mondial Relay
# S - Small, M - Medium, L - Large

SIZES = %i[S M L].freeze
L_LP_RULE_THRESHOLD = 3
PROVIDERS = {
  LP: {
    S: 1.5,
    M: 4.9,
    L: 6.9
  },
  MR: {
    S: 2,
    M: 3,
    L: 4
  }
}.freeze
LOWEST_S_PRICE = PROVIDERS.values.map { |prices| prices[:S] }.min
SEPARATOR = ' '
MONTHLY_DISCOUNT_LIMIT = 10
