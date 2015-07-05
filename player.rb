module Blackjack
  class Player

    attr_reader   :name
    attr_reader   :hands
    attr_reader   :table
    attr_reader   :current_hand
    attr_accessor :strategy

    def initialize(name)
      @name = name
      @hands = []
      @current_hand = nil
      @table = nil
      @strategy = nil
    end

    def join(table, desired_seat_position=nil)
      table.join(self, desired_seat_position)
      @table = table
      hands.clear
      self
    end

    def leave_table
      @table = nil
    end

    def make_bet(amount)
      hand << PlayerHand.new(self, amount)
    end
  end
end
