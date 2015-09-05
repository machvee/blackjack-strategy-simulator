module Blackjack
  class HandStats
    include CounterMeasures

    attr_reader  :name

    counters :dealt, :won, :pushed, :lost, :busted, :ace_up_blackjacks, :ten_up_blackjacks

    def initialize(name)
      @name = name
    end

    def reset
      reset_counters
    end

    def print
      puts "==>  #{name}"
      counters.each_pair do |key, value|
        next if value == 0
        puts "==>    %20.20s: %6d [%6.2f%%]" % [key, value, value/(dealt.count*1.0) * 100.0]
      end
      puts ""
    end
  end
end
