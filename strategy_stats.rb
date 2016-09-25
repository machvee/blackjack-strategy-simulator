module Blackjack

  class StrategyStats
    attr_reader  :chain
    attr_reader  :player
    attr_reader  :rules

    def initialize
      @rules = Set.new
      @chain = Set.new
    end

    def add(rule)
      rules << rule
      chain << rule
      self
    end

    def pop
      chain.pop
    end

    def update(outcome, amount_wagered, amount_won_or_lost)
      chain.each {|rule| rule.update(outcome, amount_wagered, amount_won_or_lost)}
      chain.clear
      self
    end

    def print
      #
      # iterate over the rules and output stats
      #
      rules.each {|r| r.print}
    end
  end
end
