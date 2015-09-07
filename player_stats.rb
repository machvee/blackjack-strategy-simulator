module Blackjack
  class PlayerStats
    include CounterMeasures
    attr_reader :player
    attr_reader :hands
    attr_reader :doubles
    attr_reader :splits
    attr_reader :insurances

    counters :surrenders, :markers

    def initialize(player)
      @player = player

      @hands = HistoHandStats.new("Hands")
      @doubles = HistoHandStats.new("Doubles")
      @splits = HistoHandStats.new("Splits")
      @insurances = HistoHandStats.new("Insurances")
    end

    def reset
      reset_counters

      hands.reset
      doubles.reset
      splits.reset
      insurances.reset
    end

    def print
      puts "\n%s %s %s" % ["="*16, player.name, '='*16]

      hands.print
      doubles.print
      splits.print
      insurances.print

      print_misc
    end

    private

    def print_misc
      return if counters.values.all?(&:zero?)
      puts "==>   Misc:"
      counters.each_pair do |key, value|
        next if value == 0
        puts "==>     %12.12s: %6d" % [key, value]
      end
    end
  end
end
