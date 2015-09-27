module Blackjack
  class Player

    attr_reader   :name
    attr_reader   :table
    attr_reader   :strategy_class
    attr_reader   :strategy
    attr_reader   :bank
    attr_reader   :buy_in
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
      @bank = Bank.new(0)
      @buy_in = 0
      @stats = PlayerStats.new(self)
    end

    def join(table, desired_seat_position=nil)
      @table = table
      table.join(self, desired_seat_position)
      buy_chips(config[:start_bank])
      @strategy = strategy_class.new(table, self, config[:strategy_options])
      self
    end

    def marker_for(amount)
      raise "you have to join a table in order to get a marker" if table.nil?
      table.get_marker(self, amount)
      @buy_in += amount
      stats.markers.incr
      self
    end

    def buy_chips(amount)
      table.buy_chips(self, amount)
      @buy_in += amount
      self
    end

    def repay_any_markers(max_amount=nil)
      amt_repaid = table.repay_markers(self, max_amount)
      @buy_in -= amt_repaid
      self
    end

    def leave_table
      repay_any_markers
      table.leave(self)
      @table = nil
      @strategy = nil
      self
    end

    def make_bet(bet_amount, bet_box=default_bet_box)
      #
      # called everytime a player puts money in a bet_box. For the 
      # start bet and for one side of split bets
      #
      bet_box.bet(self, bet_amount)
      stats.current_ten_percentage = table.shoe.current_ten_percentage
      stats.hand_stats.played.incr
      table.dealer.hand_stats.played.incr
      self
    end

    def won_bet(bet_box)
      stats.double_stats.won.incr if bet_box.double_down?
      bet_box.take_winnings
      stats.hand_stats.won.incr
      stats.split_stats.won.incr if bet_box.from_split?
      self
    end

    def lost_bet(bet_box)
      stats.hand_stats.lost.incr
      stats.split_stats.lost.incr if bet_box.from_split?
      stats.double_stats.lost.incr if bet_box.double_down?
      self
    end

    def push_bet(bet_box)
      stats.double_stats.pushed.incr if bet_box.double_down?
      bet_box.take_down_bet
      stats.hand_stats.pushed.incr
      stats.split_stats.pushed.incr if bet_box.from_split?
      self
    end

    def blackjack(bet_box, up_card)
      stats.hand_stats.blackjacks.incr
      self
    end

    def surrendered(bet_box)
      stats.surrenders.incr
      self
    end

    def busted(bet_box)
      stats.hand_stats.busted.incr
      stats.split_stats.busted.incr if bet_box.from_split?
      self
    end

    def make_insurance_bet(bet_box, bet_amount)
      bet_box.insurance_bet(bet_amount)
      stats.insurance_stats.played.incr
      self
    end

    def won_insurance_bet(bet_box)
      bet_box.take_insurance
      stats.insurance_stats.won.incr
      self
    end

    def lost_insurance_bet(bet_box)
      stats.insurance_stats.lost.incr
      self
    end

    def make_double_down_bet(bet_box, double_down_bet_amount)
      stats.double_stats.played.incr
      bank.transfer_to(bet_box.double, double_down_bet_amount)
      self
    end

    def make_split_bet(bet_amount, bet_box)
      bet_box.bet(self, bet_amount)
      stats.hand_stats.played.incr
      table.dealer.hand_stats.played.incr
      self
    end

    def default_bet_box
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
      amt = bank.balance - buy_in
      return "EVEN" if amt.zero?
      return "+$#{amt}" if amt > 0
      return "-$#{amt.abs}"
    end

  end
end
