module Blackjack
  class Player

    attr_reader  :name
    attr_reader  :hands
    attr_reader  :table
    attr_reader  :current_hand

    def initialize(name, strategy)
      @name = name
      @strategy = strategy
      @hands = []
      @current_hand = nil
      @table = nil
    end

    def join(table)
      @table.join(name)
      @table = table
      hands.clear
    end

    def make_bet(amount)
      hand << PlayerHand.new(self, amount)
    end
  end
end
