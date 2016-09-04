module Blackjack
  class PlayerDecisions

    def initialize(player)
      @decisions = {
        stay:                   StayDecision.new(player),
        play:                   PlayDecision.new(player),
        num_hands:              NumHandsDecision.new(player),
        bet_amount:             BetAmountDecision.new(player),
        insurance:              InsuranceDecision.new(player),
        insurance_bet_amount:   InsuranceBetAmountDecision.new(player),
        double_down_bet_amount: DoubleDownBetAmountDecision.new(player)
      }
    end

    def [](name)
      @decisions.fetch(name)
    end
  end
end
