module Blackjack
  class OutcomeStat
    #
    # holds incremental wins/losses/pushes etc. and $ amount won/lost
    # for a strategy rule
    #
    include CounterMeasures

    attr_reader  :name  # name of stat e.g. "decision.pairs.A.A" or "bet_amount.25"

    counters  :total,   # number of times this decision used across all play
              :won,     # number of hands this decision led to a win (dealer lower hand/bust)
              :lost,    # number of hands this decision led to a loss (dealer better hand)
              :pushed,  # number of hands this decision led to a push
              :busted,  # number of hands this decision led to a bust
              :wagered, # dollor amount of bets wagered where this decision was used to determine outcome
              :winnings # dollar amount of winnings/losses this decision led to

    def initialize(name)
      @name = name
    end

    def update(outcome, amount_wagered, amount_won_or_lost)

      total.incr
      wagered.add(amount_wagered)

      case outcome
        when Outcome::WON
          won.incr
          winnings.add(amount_won_or_lost)
        when Outcome::LOST
          lost.incr
          winnings.sub(amount_won_or_lost)
        when Outcome::PUSH
          pushed.incr
        when Outcome::BUST
          busted.incr
          winnings.sub(amount_won_or_lost)
        when Outcome::INSURANCE_WON
        when Outcome::INSURANCE_LOST
        else
          raise "unknown outcome #{outcome}"
      end
    end

    def print
      puts "#{name}: #{counters}"
    end

    def reset
      reset_counters
    end
  end
end

