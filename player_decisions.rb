module Blackjack
  class PlayerDecisions
    #
    # player decisions that precede a bet being made
    # in a bet_box
    #
    def initialize(player)
      @decisions = {
        stay:        StayDecision.new(player),
        num_hands:   NumHandsDecision.new(player),
        bet_amount:  BetAmountDecision.new(player)
      }
    end

    def [](name)
      @decisions.fetch(name)
    end

    def update(outcome, amount_wagered, amount_won_lost)
      @decisions.each_pair {|k,d| d.stats.update(outcome, amount_wagered, amount_won_lost) }
    end
  end
end
