module Blackjack
  class Dealer

    class MoneyHandler
      #
      # all dealers interaction with house/player chips and cash
      # is encapsulated here
      #
      attr_reader  :table
      attr_reader  :dealer
      attr_reader  :house
      attr_reader  :cash

      def initialize(table, dealer)
        @dealer = dealer
        @house = table.house
        @cash = table.cash
      end

      def buy_chips(player, amount)
        cash.credit(amount)
        house.transfer_to(player.bank, amount)
      end

      def collect_bet(bet_box)
        #
        # call to transfer losing bet_box bet to house
        #
        collect_house_winnings(bet_box.box)
        collect_house_winnings(bet_box.double) if bet_box.double_down?
      end

      def pay_bet(bet_box, payout_odds)
        #
        # transfer winnings from the house account to
        # the bet_box.box based on the payout_odds and
        # the bet_box bet_amount
        #
        # payout_odds is an array of ints
        #  [3,2]  payout 3 for every 2
        #  [1,1]  payout 1 for every 1
        #
        pay_account(bet_box.box, payout_odds) +
        pay_account(bet_box.double, payout_odds)
      end

      def collect_insurance(bet_box)
        collect_house_winnings(bet_box.insurance)
      end

      def pay_insurance(bet_box)
        pay_account(bet_box.insurance, Table::INSURANCE_PAYOUT)
      end

      private
      
      def pay_account(account, payout_odds)
        bet_amount = account.balance
        return 0 if bet_amount.zero?
        pay_this  = payout_odds[0]
        for_every = payout_odds[1]
        amount = (bet_amount / for_every) * pay_this
        house.transfer_to(account, amount)
        amount
      end

      def collect_house_winnings(from_account)
        from_account.transfer_to(house, from_account.balance)
        self
      end

    end

    include CounterMeasures

    attr_accessor   :hand
    attr_reader     :table
    attr_reader     :money
    attr_reader     :soft_hit_limit

    counters        :player_hands_dealt, :hands_won, :hands_pushed, :hands_lost, :hands_busted, :ace_up_blackjacks, :ten_up_blackjacks

    def initialize(table)
      @table = table
      @validator = StrategyValidator.new(table)
      @soft_hit_limit = table.config[:dealer_hits_soft_17] ? 17 : 16
      @hand = table.new_dealer_hand
      @money = MoneyHandler.new(table, self)
    end

    def deal_one_card_face_up_to_each_active_bet_box
      table.bet_boxes.each_active do |bet_box|
        deal_card_face_up_to(bet_box)
      end
      self
    end

    def deal_card_face_up_to(bet_box)
      table.shoe.deal_one_up(bet_box.hand)
    end

    def deal_up_card
      table.shoe.deal_one_up(hand)
      self
    end

    def check_player_hand_busted?(bet_box)
      bet_box.hand.bust?
    end

    def deal_hole_card
      table.shoe.deal_one_down(hand)
      self
    end

    def flip_hole_card
      hand.flip
      table.game_announcer.dealer_hand_status
      self
    end

    def deal_card_to_hand
      table.shoe.deal_one_up(hand)
      table.game_announcer.dealer_hand_status
      self
    end

    def busted?
      hand.bust?
    end

    def hit?
      !busted? &&                                           # don't hit if already busted
        ((hand.soft? && hand.hard_sum <= soft_hit_limit) || # hit if soft 16 (or if configured, soft 17) or less
        (!hand.soft? && hand.hard_sum < 17))                # hit if hard hand < 17
    end

    def play_hand
      while hit? do
        deal_card_to_hand
      end
      self
    end

    def discard_hand
      hand.fold
      self
    end

    def ask_player_num_bets(player)
      prompt_player_strategy_and_validate(:num_bets, nil, player) do
        player.strategy.num_bets
      end
    end

    def ask_player_insurance?(bet_box)
      prompt_player_strategy_and_validate(:insurance, bet_box) do
        bet_box.player.strategy.insurance?(bet_box)
      end
    end

    def ask_player_decision(bet_box)
      prompt_player_strategy_and_validate(:decision, bet_box) do
        bet_box.player.strategy.decision(bet_box, up_card, table.other_hands(bet_box))
      end
    end

    def ask_player_bet_amount(player, bet_box)
      prompt_player_strategy_and_validate(:bet_amount, bet_box, player) do
        player.strategy.bet_amount
      end
    end

    def ask_player_insurance_bet_amount(bet_box)
      prompt_player_strategy_and_validate(:insurance_bet_amount, bet_box) do
        bet_box.player.strategy.insurance_bet_amount(bet_box)
      end
    end

    def ask_player_double_down_bet_amount(bet_box)
      prompt_player_strategy_and_validate(:double_down_bet_amount, bet_box) do
        bet_box.player.strategy.double_down_bet_amount(bet_box)
      end
    end

    def player_lost(bet_box)
      table.game_announcer.hand_outcome(bet_box, Outcome::LOST, bet_box.bet_amount)
      bet_box.player.lost_bet(bet_box)
      money.collect_bet(bet_box)
    end

    def player_won(bet_box, payout)
      winnings = money.pay_bet(bet_box, payout)
      table.game_announcer.hand_outcome(bet_box, Outcome::WON, winnings)
      bet_box.player.won_bet(bet_box)
    end

    def player_push(bet_box)
      table.game_announcer.hand_outcome(bet_box, Outcome::PUSH)
      bet_box.player.push_bet(bet_box)
    end

    def up_card
      hand.up_card
    end

    def showing
      up_card.ace? ? 'A' : up_card.hard_value.to_s
    end

    def hole_card
      hand.hole_card
    end

    def print_stats
      puts "==>  Stats for:  Dealer"
      hands = player_hands_dealt.count
      counters.each_pair do |key, value|
        puts "==>    %20.20s: %6d [%6.2f%%]" % [key, value, value/(hands*1.0) * 100.0]
      end
      puts ""
    end

    private

    def prompt_player_strategy_and_validate(strategy_step, bet_box, opt_player=nil)
      player = opt_player||bet_box.player
      while(true) do
        response = yield
        success, message = validate_step_response(strategy_step, response, bet_box, player)
        break if success
        player.strategy.error(strategy_step, message)
      end

      table.game_announcer.play_by_play(strategy_step, player, response)

      response
    end

    def validate_step_response(strategy_step, response, bet_box, player)
      valid_input, error_message = case strategy_step
        when :num_bets
          @validator.validate_num_bets(player, response)
        when :insurance
          @validator.validate_insurance?(bet_box, response)
        when :bet_amount
          @validator.validate_bet_amount(player, response)
        when :insurance_bet_amount
          @validator.validate_insurance_bet_amount(bet_box, response)
        when :double_down_bet_amount
          @validator.validate_double_down_bet_amount(bet_box, response)
        when :decision
          @validator.validate_decision(bet_box, response)
      end
      [valid_input, error_message]
    end
  end
end
