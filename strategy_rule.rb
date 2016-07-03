module Blackjack
  class StrategyRule
    #
    # StrategyRule - encapsulates the logic used to make a given player decision.
    # The strategy rule has a strategy proc thats passed a Decision:: constant and
    # args.  It also has a to_s which is a unique string representation of the rule
    # used later to indentify outcome statistics kept for this rule
    #
    def initialize(decision, &block)
      @decision = decision
      @decision_proc = block
    end

    def run(*args)
      @decision_proc.call(args)
    end

    def to_s
      # override in subclass
    end
  end
end
