module Blackjack
  class PlayerStats
    include CounterMeasures
    attr_reader :player
    attr_reader :hands
    attr_reader :doubles
    attr_reader :splits

    counters :insurances, :insurances_won, :insurances_lost, :surrenders, :markers

    def initialize(player)
      @player = player
      @hands = HandStats.new("hands")
      @doubles = HandStats.new("double downs")
      @splits = HandStats.new("splits")
    end

    def reset
      reset_counters
      hands.reset
      doubles.reset
      splits.reset
    end

    def print
      puts "==>  Stats for: #{player.name}"
      hands.print
      doubles.print
      splits.print
      print_misc
    end

    private

    def print_misc
      puts "==>    misc:"
      counters.each_pair do |key, value|
        puts "==>    %20.20s: %6d" % [key, value]
      end
    end
  end
end
