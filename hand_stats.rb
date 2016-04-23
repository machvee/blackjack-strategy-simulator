module Blackjack
  class HandStats
    #
    # keeps track of a players total hands played, won, pushed, lost, busted, etc. 
    #
    include CounterMeasures

    attr_reader  :name
    attr_reader  :buckets

    counters :played, :won, :pushed, :lost, :busted, :blackjacks

    def initialize(name)
      @name = name
    end

    def reset
      reset_counters
      self
    end

    def print_stat(counter_name, counter_value=nil)
      print_stat_with_total(counter_name, counter_value)
    end

    def print_stat_with_total(counter_name, counter_value=nil)
      value = counter_value||counters[counter_name]
      HandStats.format_stat_with_total(value, played.count)
    end

    def self.format_stat(value, total)
      self.format_stat_with_total(value, total)
    end

    def self.format_stat_with_total(value, total)
      total.zero? ? "          -      " : "%6d [%7.2f%%]" % [value, value/(total*1.0) * 100.0]
    end

    def none?
      counters.values.all?(&:zero?)
    end
  end
end
