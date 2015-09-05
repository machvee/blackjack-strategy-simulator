module Blackjack
  class PlayerStats
    include CounterMeasures
    attr_reader :player

    counters :hands,         :hands_won,        :hands_pushed,     :hands_lost,          :hands_busted,
             :split_hands,   :split_hands_won,  :split_hands_lost, :split_hands_pushed,  :split_hands_busted,
             :doubles,       :doubles_won,      :doubles_lost,     :doubles_pushed,
             :insurances,    :insurances_won,   :insurances_lost,
             :blackjacks,    :surrenders,       :markers

    def initialize(player)
      @player = player
    end

    def reset
      reset_counters
    end

    def output
      puts "==>  Stats for: #{player.name}"
      hands = player.stats.hands.count
      player.stats.counters.each_pair do |key, value|
        puts "==>    %20.20s: %6d [%6.2f%%]" % [key, value, value/(hands*1.0) * 100.0]
      end
    end
  end
end
