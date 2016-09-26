module Blackjack
  class BetBoxDecisions
    #
    # Player decisions that are tied to a particular bet_box
    #
    def initialize(player, bet_box)
      @decisions = {
        play:                   PlayDecision.new(player, bet_box),
        insurance:              InsuranceDecision.new(player, bet_box),
        insurance_bet_amount:   InsuranceBetAmountDecision.new(player, bet_box),
        double_down_bet_amount: DoubleDownBetAmountDecision.new(player, bet_box)
      }
    end

    def [](name)
      @decisions.fetch(name)
    end
  end
end
