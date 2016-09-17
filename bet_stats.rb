module Blackjack
  class BetStats
    include CounterMeasures

    attr_reader  :name

    counters :wagered, :winnings

    def initialize(name)
      @name = name
    end

    def reset
      reset_counters
      self
    end

    def print
      counters.keys.each do |k|
        puts print_stat(k)
      end
    end

    def print_stat(counter_name, counter_value=nil)
      value = counter_value||counters[counter_name]
      BetStats.format_stat(value)
    end

    def self.format_stat(value)
      neg = value < 0 ? "()" : ""
      fmt_out = "%s$%.2f%s" % [neg[0], value.abs, neg[1]]
      "%16s" % fmt_out
    end

    def none?
      counters.values.all?(&:zero?)
    end
  end
end
