module Blackjack
  class Player

    DEFAULT_START_BANK=500

    attr_reader   :name
    attr_reader   :table
    attr_accessor :strategy
    attr_reader   :bank
    attr_reader   :stats

    def initialize(name, start_bank=DEFAULT_START_BANK)
      @name = name
      @hands = []
      @current_hand = nil
      @table = nil
      @strategy = nil
      @bank = Bank.new(start_bank)
      @stats = PlayerStats.new(self)
    end

    def join(table, desired_seat_position=nil)
      @table = table
      table.join(self, desired_seat_position)
      self
    end

    def leave_table
      @table = nil
    end

    def make_bet
      bet_box.bet(self, strategy.bet_amount)
      stats.hands.incr
    end

    def bet_box
      table.bet_box_for(self)
    end

    def reset
      stats.reset
      bank.reset
    end
  end
end
