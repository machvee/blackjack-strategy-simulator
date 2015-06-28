module Blackjack
  class DealerHandStrategy

    def initialize(table, hand)
    end

    #
    # subclass this to vary the dealer hitting strategy
    # e.g. some casinos require the dealer hit a soft 17
    #
    def decision
      #
      # dealer hits until > 17
      # dealer stands on soft 17
      # return Action::HIT or Action::STAND
      #
    end
  end
end
