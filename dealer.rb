module Blackjack
  class Dealer

    attr_accessor   :hand
    attr_reader     :table
    attr_reader     :soft_hit_limit

    def initialize(table)
      @table = table
      @validator = StrategyValidator.new(table)
      @soft_hit_limit = table.config[:dealer_hits_soft_17] ? 17 : 16
      @hand = table.new_dealer_hand
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
      self
    end

    def deal_card_to_hand
      table.shoe.deal_one_up(hand)
      self
    end

    def collect(bet_box)
      #
      # call to transfer losing bet_box bet to house
      #
      bet_box.box.transfer_to(table.house, bet_box.bet_amount)
      self
    end

    def pay(bet_box, payout_odds)
      #
      # transfer winnings from the house account to
      # the bet_box.box based on the payout_odds and
      # the bet_box bet_amount
      #
      # payout_odds is an array of ints
      #  [3,2]  payout 3 for every 2
      #  [1,1]  payout 1 for every 1
      #
      pay_this  = payout_odds[0]
      for_every = payout_odds[1]
      amount = (bet_box.bet_amount / for_every) * pay_this
      table.house.transfer_to(bet_box.box, amount)
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

    def ask_player_play?(player)
      prompt_player_strategy_and_validate(:play, player) do
        player.strategy.play?
      end
    end

    def ask_player_insurance?(bet_box)
      player = bet_box.player
      prompt_player_strategy_and_validate(:insurance, bet_box.player, bet_box) do
        player.strategy.insurance?(bet_box)
      end
    end

    def ask_player_decision(bet_box)
      player = bet_box.player
      prompt_player_strategy_and_validate(:decision, bet_box.player, bet_box) do
        player.strategy.decision(bet_box, up_card, table.other_hands(bet_box))
      end
    end

    def ask_player_bet_amount(player)
      prompt_player_strategy_and_validate(:bet_amount, player) do
        player.strategy.bet_amount
      end
    end

    def ask_player_insurance_bet_amount(bet_box)
      player = bet_box.player
      prompt_player_strategy_and_validate(:insurance_bet_amount, bet_box.player, bet_box) do
        player.strategy.insurance_bet_amount(bet_box)
      end
    end

    def ask_player_double_down_bet_amount(bet_box)
      player = bet_box.player
      prompt_player_strategy_and_validate(:double_down_bet_amount, bet_box.player, bet_box) do
        player.strategy.double_down_bet_amount(bet_box)
      end
    end

    def up_card
      hand.up_card
    end

    def hole_card
      hand.hole_card
    end

    private

    def prompt_player_strategy_and_validate(strategy_step, player, bet_box=nil)
      while(true) do
        response = yield
        success, message = validate_step_response(strategy_step, response, player, bet_box)
        break if success
        player.strategy.error(strategy_step, message)
      end
      response
    end

    def validate_step_response(strategy_step, response, player, bet_box)
      valid_input, error_message = case strategy_step
        when :play
          @validator.validate_play?(player, response)
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
