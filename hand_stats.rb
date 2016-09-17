module Blackjack
  class HandStats
    include CounterMeasures

    attr_reader  :name

    counters :played, :won, :pushed, :lost, :busted, :blackjacks

    def initialize(name=nil)
      @name = name
    end

    def reset
      reset_counters
      self
    end

    def print(group_name=nil)
      total = counters[:played]
      print_header
      counters.keys.each do |k|
        print_stat(k, total)
      end
    end

    def print_header
      puts "\n"
      puts name.upcase unless name.nil?
    end

    def print_stat(counter_name, total)
      puts "%12s: %s" % [counter_name, percentage_format(counters[counter_name], total)]
    end

    def percentage_format(value, total)
      total.zero? ? "          -      " : "%6d [%7.2f%%]" % [value, value/(total*1.0) * 100.0]
    end

    def print_stat_with_total(counter_name, counter_value=nil)
      value = counter_value||counters[counter_name]
      HandStats.format_stat_with_total(value, played.count)
    end

    def self.format_stat(value, total)
      self.format_stat_with_total(value, total)
    end

  end
end
