module Blackjack
  class StrategyRule
    #
    # StrategyRule   
    #
    def initialize(decision)
      @decision = decision
      @stats = StrategyStats.new
    end

    def name
      # override in subclass
    end

    def to_s
      name
    end

  end
end
