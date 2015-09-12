module Blackjack
  class HandStats
    include CounterMeasures

    attr_reader  :name
    attr_reader  :buckets

    counters :played, :won, :pushed, :lost, :busted, :blackjacks

    def initialize(name)
      @name = name
    end

    def reset
      reset_counters
    end

    def print
      counters.each_pair do |key, value|
        next if value == 0
        puts "==>     %13.13s: %s" % [key, print_stat(key, value)]
      end
      puts ""
    end

    def print_stat(counter_name, counter_value=nil)
      value = counter_value||counters[counter_name]
      "%6d [%7.2f%%]" % [value, value/(played.count*1.0) * 100.0]
    end

    def none?
      counters.values.all?(&:zero?)
    end
  end
end
