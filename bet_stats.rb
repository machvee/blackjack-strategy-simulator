module Blackjack
  class BetStats
    #
    # Keeps track of how much a player has wagered and won in total
    #
    include CounterMeasures

    attr_reader  :name
    attr_reader  :buckets

    counters :wagered, :winnings

    def initialize(name)
      @name = name
    end

    def reset
      reset_counters
      self
    end

    def print_stat(counter_name, counter_value=nil)
      value = counter_value||counters[counter_name]
      BetStats.format_stat(value)
    end

    def self.format_stat(value)
      neg = value < 0 ? "()" : ""
      fmt_out = "%s$%d%s" % [neg[0], value.abs, neg[1]]
      "%16s" % fmt_out
    end

    def none?
      counters.values.all?(&:zero?)
    end
  end
end
