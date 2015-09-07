module Blackjack
  class TableStats
    attr_reader  :table

    include CounterMeasures

    counters :players_seated, :rounds_played

    def initialize(table)
      @table = table
    end

    def reset
      reset_counters
    end

    def print
      puts "==>  rounds played: #{rounds_played.count}"
    end

  end
end
