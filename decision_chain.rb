module Blackjack
  class DecisionLink
    def initialize
    end

    def outcome(result, amount)
    end
  end

  class DecisionChain
    attr_reader  :chain
    def initialize
      @chain = []
    end

    def add(link)
      @chain << link
    end

    def evaluate
      @chain.each do |link|
        link.outcome(result, amount)
      end
    end
  end
end
