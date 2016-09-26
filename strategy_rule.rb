module Blackjack
  class StrategyRule
    attr_reader  :decision
    attr_reader  :name
    attr_reader  :stats

    def initialize(name, decision)
      @name = name
      @decision = decision
      @stats = OutcomeStat.new(name)
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

    def inspect
      to_s
    end
  end
end
