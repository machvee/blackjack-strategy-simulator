module Blackjack

  class DecisionLink
    def outcome(result, amount)
      # result:
      #   Outcome::WON
      #   Outcome::LOST
      #   Outcome::PUSH
      #   Outcome::BUST
      #
      # amount player has won (winnings only) or lost (total bet amount)
      #
    end
  end

  class DecisionChain
    attr_reader  :chain
    attr_reader  :player

    def initialize(player)
      @player = player
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
