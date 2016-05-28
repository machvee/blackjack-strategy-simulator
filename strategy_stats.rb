module Blackjack

  class OutcomeStat
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


  class StatsChain
    attr_reader  :chain
    attr_reader  :player

    def initialize(player)
      @player = player
      @chain = []
    end

    def add(name)
      chain << player.strategy.stats.get(name)
      self
    end

    def pop
      chain.pop
    end

    def update(outcome, amount_wagered, amount_won_or_lost)
      chain.each {|o| o.update(outcome, amount_wagered, amount_won_or_lost)}
      chain.clear
      self
    end
  end


  class StrategyStats
    attr_reader  :outcome_stats

    def initialize
      @outcome_stats = Hash.new {|h,k| h[k] = OutcomeStat.new(k)}
    end

    def get(name)
      outcome_stats[name]
    end

    def print
      #
      # iterate over outcome stats end call print
      #
      outcome_stats.each {|k,o| o.print}
    end

  end
end
