module Blackjack
  class HandStatsBucket
    #
    #                       marker card V
    #
    # ||||T||||||TTT|T|||||||TTTT|TTTT||m||||||||||
    #      remaining till shuffle
    #
    #  T - a ten
    #  count of T's / remaining till shuffle is the ten percentage
    #
    #  keep stats in buckets of ten percentages
    #
    attr_reader :name
    attr_reader :min
    attr_reader :max
    attr_reader :stats

    def initialize(name, min, max)
      @name = name
      @min = min
      @max = max
      @stats = HandStats.new(name)
    end

    def within?(value)
      min <= value && max >= value
    end

    def reset
      stats.reset
    end

    def print
      return if stats.none?
      puts "==> %s [%5.1f-%5.1f]" % [name, min, max]
      stats.print
      puts ""
    end
  end
end
