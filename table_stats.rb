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
      puts "==>  avg hands/shuffle: #{table.shoe.hands_dealt.average}"
      puts "==>  seed: #{table.seed}"
    end

  end
end
