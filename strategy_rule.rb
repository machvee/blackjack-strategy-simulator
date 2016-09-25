module Blackjack
  class StrategyRule
    attr_reader  :decision
    attr_reader  :name
    attr_reader  :stats

    def initialize(name)
      @name = name
      @stats = OutcomeStat.new
    end

    def update(outcome, amount_wagered, amount_won_or_lost)
      @stats.update(outcome, amount_wagered, amount_won_or_lost)
    end

    def to_s
      name
    end

    def print
      @stats.print
    end
  end
end
