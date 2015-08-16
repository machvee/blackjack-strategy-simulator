module Blackjack
  class Player

    attr_reader   :name
    attr_reader   :table
    attr_reader   :strategy_class
    attr_reader   :strategy
    attr_reader   :bank
    attr_reader   :stats

    DEFAULT_OPTIONS = {
      start_bank: 500,
      strategy_class: PromptPlayerHandStrategy
    }

    def initialize(name, options={})
      opts = DEFAULT_OPTIONS.merge(options)
      @name = name
      @hands = []
      @table = nil
      @strategy_class = opts[:strategy_class]
      @bank = Bank.new(opts[:start_bank])
      @stats = PlayerStats.new(self)
    end

    def join(table, desired_seat_position=nil)
      @table = table
      table.join(self, desired_seat_position)
      @strategy = strategy_class.new(table, self)
      self
    end

    def leave_table
      @table.leave(self)
      @table = nil
      @strategy = nil
      self
    end

    def make_bet(bet_amount, alt_bet_box=nil)
      (alt_bet_box||bet_box).bet(self, bet_amount)
      stats.hands.incr
      self
    end

    def won_bet(bet_box)
      bet_box.take_winnings
      stats.hands_won.incr
      self
    end

    def lost_bet(bet_box)
      stats.hands_lost.incr
      self
    end

    def push_bet(bet_box)
      bet_box.take_down_bet
      stats.pushes.incr
      self
    end

    def blackjack(bet_box)
      stats.blackjacks.incr
      self
    end

    def surrendered(bet_box)
      stats.surrenders.incr
      self
    end

    def busted(bet_box)
      stats.busts.incr
      self
    end

    def make_insurance_bet(bet_box, bet_amount)
      bet_box.insurance_bet(bet_amount)
      stats.insurances.incr
      self
    end

    def won_insurance_bet(bet_box)
      bet_box.take_insurance
      stats.insurances_won.incr
      self
    end

    def lost_insurance_bet(bet_box)
      stats.insurances_lost.incr
      self
    end

    def make_double_down_bet(bet_box, double_down_bet_amount)
      stats.double_downs.incr
      bank.transfer_to(bet_box.box, double_down_bet_amount)
      self
    end

    def won_double_down_bet(bet_box)
      stats.double_downs_won.incr
      self
    end

    def make_split_bet(bet_box, bet_amount)
      bet_box.bet(self, bet_amount)
      stats.splits.incr
      stats.splits.incr # double split count for two hand results
      stats.hands.incr  # one additional hand is created for each split
      self
    end

    def bet_box
      table.bet_boxes.dedicated_to(self)
    end

    def reset
      stats.reset
      bank.reset
    end

    def inspect
      to_s
    end

    def to_s
      "#{name} - $#{bank.balance} (#{up_down})"
    end

    def up_down
      amt = bank.balance - bank.initial_deposit 
      return "EVEN" if amt.zero?
      return "+#{amt}" if amt > 0
      return "-#{amt.abs}"
    end
  end
end
