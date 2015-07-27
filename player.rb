module Blackjack
  class Player

    attr_reader   :name
    attr_reader   :table
    attr_accessor :strategy
    attr_reader   :bank
    attr_reader   :stats

    DEFAULT_OPTIONS = {
      start_bank: 500
    }

    def initialize(name, options={})
      options.merge!(DEFAULT_OPTIONS)
      @name = name
      @hands = []
      @table = nil
      @strategy = nil
      @bank = Bank.new(options[:start_bank])
      @stats = PlayerStats.new(self)
    end

    def join(table, desired_seat_position=nil)
      @table = table
      table.join(self, desired_seat_position)
      self
    end

    def leave_table
      @table.leave(self)
      @table = nil
      self
    end

    def make_bet
      bet_box.bet(self, strategy.bet_amount)
      stats.hands.incr
      self
    end

    def bet_box
      table.bet_boxes.dedicated_to(self)
    end

    def reset
      stats.reset
      bank.reset
    end
  end
end
