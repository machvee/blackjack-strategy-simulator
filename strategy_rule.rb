module Blackjack
  class StrategyRule
    #
    # StrategyRule   
    #
    attr_reader  :decision
    attr_reader  :name

    def initialize(name, decision)
      @name = name
      @decision = decision
      @stats = StrategyStats.new
    end

    def to_s
      name
    end

  end
end
