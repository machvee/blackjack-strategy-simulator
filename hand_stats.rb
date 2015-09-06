module Blackjack
  class HandStats
    include CounterMeasures

    attr_reader  :name

    counters :played, :won, :pushed, :lost, :busted, :blackjacks_A, :blackjacks_10

    def initialize(name)
      @name = name
    end

    def reset
      reset_counters
    end

    def print
      puts "==>   #{name}:"
      counters.each_pair do |key, value|
        next if value == 0
        puts "==>     %13.13s: %6d [%6.2f%%]" % [key, value, value/(played.count*1.0) * 100.0]
      end
      puts ""
    end
  end
end
