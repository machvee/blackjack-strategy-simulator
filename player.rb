module Blackjack
  class Player

    attr_reader  :name

    def initialize(name, strategy)
      @name = name
      @strategy = strategy
    end
  end
end
