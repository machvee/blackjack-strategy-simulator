module Blackjack
  class PlayerStats
    include CounterMeasures
    attr_reader :player
    attr_reader :hands
    attr_reader :doubles
    attr_reader :splits
    attr_reader :insurances
    attr_reader :bets

    attr_reader :current_ten_percentage

    counters :surrenders, :markers

    def initialize(player)
      @player = player

      @hands = HistoStats.new("Hands", HandStats)
      @doubles = HistoStats.new("Doubles", HandStats)
      @splits = HistoStats.new("Splits", HandStats)
      @insurances = HistoStats.new("Insurances", HandStats)
      @bets = HistoStats.new("Bets", BetStats)
      @current_ten_percentage = 0.0
    end

    def reset
      reset_counters

      hands.reset
      doubles.reset
      splits.reset
      insurances.reset
      bets.reset
    end

    def init_hand
      @current_ten_percentage = player.table.shoe.current_ten_percentage
    end

    def print
      puts "\n%s %s %s" % ["="*16, player.name.upcase, '='*16]

      hands.percentage_print
      doubles.percentage_print
      splits.percentage_print
      insurances.percentage_print
      bets.print

      print_misc
    end

    def double_stats
      doubles.stats_for(current_ten_percentage)
    end

    def split_stats
      splits.stats_for(current_ten_percentage)
    end

    def hand_stats
      hands.stats_for(current_ten_percentage)
    end

    def insurance_stats
      insurances.stats_for(current_ten_percentage)
    end

    def bet_stats
      bets.stats_for(current_ten_percentage)
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
