module Blackjack

  class OutcomeStat
    include CounterMeasures
    counters  :total,   # number of times this decision used across all play
              :won,     # number of hands this decision led to a win (dealer lower hand/bust)
              :lost,    # number of hands this decision led to a loss (dealer better hand)
              :pushed,  # number of hands this decision led to a push
              :busted,  # number of hands this decision led to a bust
              :wagered, # dollor amount of bets wagered where this decision was used to determine outcome
              :winnings # dollar amount of winnings/losses this decision led to

    def reset
      reset_counters
    end
  end

  class StrategyStats

    #
    #    count - total number of times used during all play
    #    wins - when used, the hand won
    #      count - number of time used in a win
    #      amount - $ amount won
    #    lost - when used, the hand lost
    #      count - number of time used in a loss
    #      amount - $ amount lost
    #    push - when used, the hand pushed
    #      count - number of time used in a push
    #      amount - $ amount pushed
    # 
    # TODO: how to tabluate splits stats?   Splits yield more hands that
    #   individually have stats.  Sum all the stats up the split tree and
    #   put in the Split stat?
    #

    def initialize
      @stats_table = {
        # num_bets:               game_stat_hash,
        bet_amount:             game_stat_hash,
        insurance:              game_stat_hash,
        # insurance_bet_amount:   game_stat_hash,
        # double_down_bet_amount: game_stat_hash
        decision: {
          pairs: decision_stat_hash,
          soft:  decision_stat_hash,
          hard:  decision_stat_hash,
        }
      }
      @chain = []
    end

    def decision_stat(type, dealer_up_card, hand_value)
      @stats_table[:decision][type][dealer_up_value][hand_value]
    end

    def bet_amount_stat(bet_unit_multiple)
      @stats_table[:bet_amount][bet_unit_multiple]
    end

    def insurance_stat
      @stats_table[:insurance]
    end

    private

    def game_stat_hash
      Hash.new {|h,k| h[k] = OutcomeStat.new}
    end

    def decision_stat_hash
      Hash.new {|h,k| h[k] = game_stat_hash}
    end
  end
end
