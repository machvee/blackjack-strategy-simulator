module Blackjack
  class PlayerStats
    include CounterMeasures
    attr_reader :player

    counters :hands,        :hands_won,        :hands_lost,
             :splits,       :splits_won,       :splits_lost,
             :double_downs, :double_downs_won, :double_downs_lost,
             :soft_doubles, :soft_doubles_won, :soft_doubles_lost,
             :busts,        :blackjacks

    def initialize(player)
      @player = player
    end

    def reset
      reset_counters
    end
  end
end
