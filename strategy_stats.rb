module Blackjack

  class StrategyStats
    attr_reader  :chain
    attr_reader  :player
    attr_reader  :rules

    def initialize
      @chain = Set.new
    end

    def add(rule)
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
  end
end
