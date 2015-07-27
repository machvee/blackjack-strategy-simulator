require 'cards'
require 'player_hand_strategy'

module Blackjack
  class Dealer

    include Cards

    attr_accessor   :hand
    attr_reader     :table

    def initialize(table)
      @table = table
      init_response_validator
    end

    def deal_one_card_face_up_to_bet_active_bet_boxes
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

    def ask_insurance?(player, player_hand)
      prompt_player_strategy_and_validate(:insurance) do
        player.strategy.insurance?(player_hand)
      end
    end

    def ask_decision(player, player_hand)
      prompt_player_strategy_and_validate(:decision) do
        player.strategy.decision(player_hand, dealer.up_card, table.other_hands(player_hand))
      end
    end

    def ask_bet_amount(player)
      prompt_player_strategy_and_validate(:bet_amount) do
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

    def prompt_player_strategy_and_validate(strategy_step)
      while(true) do
        response = yield
        success, message = validate_step_response(strategy_step, response)
        break if success
        player.strategy.error(strategy_step, message)
      end
      response
    end

    STRATEGY_VALID_INPUT_HASH = {
      play: [
        Action::LEAVE,
        Action::SIT_OUT,
        Action::PLAY
      ],
      insurance: [
        Action::INSURANCE,
        Action::NO_INSURANCE,
        Action::EVEN_MONEY
      ],
      decision: [
        Action::HIT,
        Action::STAND,
        Action::SPLIT,
        Action::DOUBLE_DOWN,
        Action::SURRENDER
      ]
    }

    def init_response_validator
      @validator_hash = STRATEGY_VALID_INPUT_HASH.merge(bet_amount: table.config[:minimum_bet]..table.config[:maximum_bet])
    end

    def validate_step_response(strategy_step, response)
      valid_input = @validator_hash[strategy_step].include?(response)
      message = valid_input ? nil : error_message(strategy_step, response)

      [valid_input, message]
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
