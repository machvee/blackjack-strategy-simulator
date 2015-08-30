module Blackjack
  class PlayerStats
    include CounterMeasures
    attr_reader :player

    counters :hands,         :hands_won,        :hands_lost,       :hands_pushed,        :hands_busted,
             :split_hands,   :split_hands_won,  :split_hands_lost, :split_hands_pushed,  :split_hands_busted,
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
