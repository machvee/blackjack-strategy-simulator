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

    def print(key=nil)
      counters.each_pair do |key, value|
        next if value == 0
        puts "==>     %13.13s: %6d [%6.2f%%]" % [key, value, value/(played.count*1.0) * 100.0]
      end
      puts ""
    end

    def none?
      counters.values.all?(&:zero?)
    end
  end
end
