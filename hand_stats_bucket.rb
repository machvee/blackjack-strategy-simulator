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
    attr_reader :range_string

    def initialize(name, min, max)
      @name = name
      @min = min
      @max = max
      @range_string = "( %s - %s )" % ["%d" % min,"%d" % max]
      @stats = HandStats.new(name)
    end

    def within?(value)
      value <= max
    end

    def reset
      stats.reset
    end
  end
end
