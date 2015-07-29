require 'cards'
require 'player_hand_strategy'

module Blackjack
  class Dealer

    include Cards

    attr_accessor   :hand
    attr_reader     :table

    def initialize(table)
      @table = table
      @validator = StrategyValidator(table)
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
      prompt_player_strategy_and_validate(:play) do
        player.strategy.play?
      end
    end

    def ask_insurance?(player, bet_box)
      prompt_player_strategy_and_validate(:insurance, player, bet_box) do
        player.strategy.insurance?(bet_box)
      end
    end

    def ask_decision(player, bet_box)
      prompt_player_strategy_and_validate(:decision, player, bet_box) do
        player.strategy.decision(bet_box, dealer.up_card, table.other_hands(player_hand))
      end
    end

    def ask_bet_amount(player)
      prompt_player_strategy_and_validate(:bet_amount, player) do
        player.strategy.bet_amount
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
      valid_input = case strategy_step
        when :play
          @validator.validate_play?(player, response)
        when :insurance
          @validator.validate_insurance?(player, bet_box, response)
        when :bet_amount
          @validator.validate_bet_amount(player, response)
        when :decision
          @validator.validate_decision(player, bet_box, response)
      end

      error_message = case strategy_step
        when :insurance
          if !player_hand.blackjack?
            "Player must have Blackjack to request EVEN_MONEY for insurance?"
          end
        when :decision
      end

    end

    def error_message(strategy_step, response)
      case strategy_step
        when :bet_amount
          "#{response} is an invalid bet amount"
        else
          bad_resp_const = Action.constants.find {|c| Action.const_get(c) == response}
          "Action::#{bad_resp_const} is an invalid response for Strategy##{strategy_step}"
      end
    end

  end
end
