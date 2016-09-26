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
    attr_reader   :decision
    attr_reader   :rules

    DEFAULT_OPTIONS = {
      start_bank: 500,
      strategy_class: PromptPlayerHandStrategy,
      strategy_options: {},
      auto_marker: false
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
      @rules = []
    end

    def join(table, desired_seat_position=nil)
      @table = table
      table.join(self, desired_seat_position)
      buy_chips(config[:start_bank])
      @strategy = strategy_class.new(
        table,
        self,
        config[:strategy_options]
      )
      @decision = PlayerDecisions.new(self)
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
      @decision = nil
      self
    end

    def make_bet(bet_amount, bet_box=default_bet_box)
      #
      # called every time a player puts money in a bet_box at the start of a round
      #
      balance_check(bet_amount)
      bet_box.bet(self, bet_amount)
      stats.init_hand
      stats.hand_stats.played.incr
      table.dealer.stats.hand.played.incr
      stats.bet_stats.wagered.add(bet_amount)
      self
    end

    def won_bet(bet_box, winnings)
      stats.double_stats.won.incr if bet_box.doubled_down?
      stats.bet_stats.winnings.add(winnings)
      bet_box.player_decision.update(Outcome::WON, bet_box.total_player_bet, winnings)
      decision.update(Outcome::WON, bet_box.total_player_bet, winnings)
      bet_box.take_winnings
      stats.hand_stats.won.incr
      stats.split_stats.won.incr if bet_box.from_split?
      self
    end

    def lost_bet(bet_box)
      stats.hand_stats.lost.incr
      stats.bet_stats.winnings.sub(bet_box.total_player_bet)
      bet_box.player_decision.update(Outcome::LOST, bet_box.total_player_bet, bet_box.total_player_bet)
      decision.update(Outcome::LOST, bet_box.total_player_bet, bet_box.total_player_bet)
      stats.split_stats.lost.incr if bet_box.from_split?
      stats.double_stats.lost.incr if bet_box.doubled_down?
      self
    end

    def busted(bet_box)
      stats.hand_stats.busted.incr
      bet_box.player_decision.update(Outcome::BUST, bet_box.total_player_bet, bet_box.total_player_bet)
      decision.update(Outcome::BUST, bet_box.total_player_bet, bet_box.total_player_bet)
      stats.split_stats.busted.incr if bet_box.from_split?
      stats.bet_stats.winnings.sub(bet_box.total_player_bet)
      self
    end

    def push_bet(bet_box)
      stats.double_stats.pushed.incr if bet_box.doubled_down?
      bet_box.player_decision.update(Outcome::PUSH, bet_box.total_player_bet, 0)
      decision.update(Outcome::PUSH, bet_box.total_player_bet, 0)
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

      balance_check(double_down_bet_amount)
      bank.transfer_to(bet_box.double, double_down_bet_amount)

      stats.bet_stats.wagered.add(double_down_bet_amount)
      self
    end

    def default_bet_box
      table.bet_boxes.dedicated_to(self)
    end

    def balance_check(amount)
      if config[:auto_marker] && !bank.balance_check(amount)
        marker_for([bank.initial_deposit, amount].max)
      end
      bank.balance_check(amount)
    end

    def new_rule(name, decision)
      StrategyRule.new(name, decision).tap do |rule|
        @rules << rule
      end
    end

    def print_rules
      @rules.select {|r| r.stats.total.count > 0}.each {|r| r.print}
    end

    def reset
      stats.reset
      bank.reset
    end

    def inspect
      to_s
    end

    def to_s
      "%s has $%.2f (%s)" % [name, bank.balance, up_down]
    end

    def up_down
      amt = bank.balance - buy_in
      return "EVEN" if amt.zero?
      return "+$%.2f" % amt if amt > 0
      return "-$%.2f" % amt.abs
    end

  end
end
