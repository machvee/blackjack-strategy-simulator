module Blackjack
  class PlayerStats
    include CounterMeasures
    attr_reader :player

    counters :hands,         :hands_won,        :hands_lost,   :hands_pushed,   :hands_busted,
             :splits,        :splits_won,       :splits_lost,  :splits_pushed,  :splits_busted,
             :doubles,       :doubles_won,      :doubles_lost, :doubles_pushed,
             :insurances,    :insurances_won,   :insurances_lost,
             :blackjacks,    :surrenders,       :markers

    def initialize(player)
      @player = player
    end

    def reset
      reset_counters
    end
  end
end
