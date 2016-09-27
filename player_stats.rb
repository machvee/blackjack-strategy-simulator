module Blackjack
  class PlayerStats
    include CounterMeasures
    attr_reader :player
    attr_reader :hand_stats
    attr_reader :double_stats
    attr_reader :split_stats
    attr_reader :insurance_stats
    attr_reader :bet_stats

    attr_reader :current_ten_percentage

    counters :surrenders, :markers

    def initialize(player)
      @player     = player
      @hand_stats      = HandStats.new("Hands")
      @double_stats    = HandStats.new("Double")
      @split_stats     = HandStats.new("Split")
      @insurance_stats = HandStats.new("Insurance")
      @bet_stats       = BetStats.new("Bets")
    end

    def reset
      reset_counters

      hand_stats.reset
      double_stats.reset
      split_stats.reset
      insurance_stats.reset
      bet_stats.reset
    end

    def print
      puts "\n%s %s %s" % ["="*16, player.name.upcase, '='*16]

      hand_stats.print
      double_stats.print
      split_stats.print
      insurance_stats.print
      bet_stats.print

      print_misc
    end

    private

    def print_misc
      return if counters.values.all?(&:zero?)
      puts "\n"
      puts "MISC"
      counters.each_pair do |key, value|
        next if value == 0
        puts "  %12s: %6d" % [key, value]
      end
    end
  end
end
