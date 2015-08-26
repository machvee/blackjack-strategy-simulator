module Blackjack
  class Player

    attr_reader   :name
    attr_reader   :table
    attr_reader   :strategy_class
    attr_reader   :strategy
    attr_reader   :bank
    attr_reader   :stats
    attr_reader   :config

    DEFAULT_OPTIONS = {
      start_bank: 500,
      strategy_class: PromptPlayerHandStrategy,
      strategy_options: {}
    }

    def initialize(name, options={})
      @config = DEFAULT_OPTIONS.merge(options)
      @name = name
      @hands = []
      @table = nil
      @strategy_class = config[:strategy_class]
      @bank = Bank.new(config[:start_bank])
      @stats = PlayerStats.new(self)
    end

    def join(table, desired_seat_position=nil)
      @table = table
      table.join(self, desired_seat_position)
      @strategy = strategy_class.new(table, self, config[:strategy_options])
      self
    end

    def marker_for(amount)
      raise "you have to join a table in order to get a marker" if table.nil?
      table.get_marker(self, amount)
      stats.markers.incr
    end

    def repay_any_markers(max_amount=nil)
      table.repay_markers(self, max_amount)
    end

    def leave_table
      repay_any_markers
      table.leave(self)
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
      stats.splits_won.incr if bet_box.from_split?
      stats.doubles_won.incr if bet_box.from_double_down?
      self
    end

    def lost_bet(bet_box)
      stats.hands_lost.incr
      stats.splits_lost.incr if bet_box.from_split?
      stats.doubles_lost.incr if bet_box.from_double_down?
      self
    end

    def push_bet(bet_box)
      bet_box.take_down_bet
      stats.hands_pushed.incr
      stats.splits_pushed.incr if bet_box.from_split?
      stats.doubles_pushed.incr if bet_box.from_double_down?
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
      stats.hands_busted.incr
      stats.splits_busted.incr if bet_box.from_split?
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
      stats.doubles.incr
      bank.transfer_to(bet_box.box, double_down_bet_amount)
      self
    end

    def make_split_bet(bet_box, bet_amount)
      bet_box.bet(self, bet_amount)
      stats.splits.incr
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

    def inspect
      to_s
    end

    def to_s
      "#{name} - $#{bank.balance} (#{up_down})"
    end

    def up_down
      amt = bank.balance - bank.initial_deposit 
      return "EVEN" if amt.zero?
      return "+$#{amt}" if amt > 0
      return "-$#{amt.abs}"
    end
  end
end
