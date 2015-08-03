require 'cards'

module Blackjack
  class Dealer

    include Cards

    attr_accessor   :hand
    attr_reader     :table

    def initialize(table)
      @table = table
      @validator = StrategyValidator.new(table)
    end

    def deal_one_card_face_up_to_bet_active_bet_box
      table.bet_boxes.each_active do |bet_box|
        table.shoe.deal_one_up(bet_box.hand)
      end
    end

    def deal_up_card
      @hand = Cards.new(table.shoe.decks)
      table.shoe.deal_one_up(hand)
    end

    def deal_hole_card
      table.shoe.deal_one_down(hand)
    end

    def ask_play?(player)
      prompt_player_strategy_and_validate(:play, player) do
        player.strategy.play?
      end
    end

    def ask_insurance?(bet_box)
      prompt_player_strategy_and_validate(:insurance, bet_box.player, bet_box) do
        player.strategy.insurance?(bet_box)
      end
    end

    def ask_decision(bet_box)
      prompt_player_strategy_and_validate(:decision, bet_box.player, bet_box) do
        player.strategy.decision(bet_box, dealer.up_card, table.other_hands(bet_box.hand))
      end
    end

    def ask_bet_amount(player)
      prompt_player_strategy_and_validate(:bet_amount, player) do
        player.strategy.bet_amount
      end
    end

    def ask_insurance_bet_amount(bet_box)
      prompt_player_strategy_and_validate(:insurance_bet_amount, bet_box.player, bet_box) do
        player.strategy.insurance_bet_amount(bet_box)
      end
    end

    def ask_double_down_bet_amount(bet_box)
      prompt_player_strategy_and_validate(:double_down_bet_amount, bet_box.player, bet_box) do
        player.strategy.double_down_bet_amount(bet_box)
      end
    end

    def up_card
      hand[0]
    end

    def hole_card
      hand[1]
    end

    def flip_hole_card
      hole_card.up if hole_card.face_down?
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
