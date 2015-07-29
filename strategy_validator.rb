module Blackjack
  class StrategyEvaluator

    YOU ARE HERE.  reverse this.  change to invalid_strategy_step? and have it return [false, nil] or [true, "reason why its not valid"]

    STRATEGY_VALID_INPUT_HASH = {
      play: [
        Action::LEAVE,
        Action::SIT_OUT,
        Action::BET
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

    attr_reader  :table

    def initialize(table)
      @table = table
    end

    def valid_play?(player)
      valid_responses = STRATEGY_VALID_INPUT_HASH[:play]
      #
      # player must have minimum bet amount in bank in order to
      # place a bet
      #
      if player.bank.current_balance < table.config[:minimum_bet]
        valid_responses.delete(Action::BET)
      end
      valid_responses
    end

    def validate_play?(player, response)
      valid_play?(player).include?(response)
    end

    def valid_insurance?(player, bet_box)
      #
      # player must have blackjack in order to ask
      # for Action::EVEN_MONEY
      #
      # player must have current_bet/2 in bank in order
      # take Action::INSURANCE
      #
      # Action::NO_INSURANCE is always valid
      #
      valid_responses = STRATEGY_VALID_INPUT_HASH[:insurance]
      valid_responses.delete(Action::INSURANCE) unless player.bank.current_balance >= bet_box.current_bet/2.0
      valid_responses.delete(Action::EVEN_MONEY) unless bet_box.hand.blackjack?
      valid_responses
    end

    def validate_insurance?(player, bet_box, response)
      valid_insurance?(player, bet_box).include?(response)
    end

    def valid_bet_amount
      table.config[:minimum_bet]..table.config[:maximum_bet]
    end

    def validate_bet_amount(player, bet_amount)
      player.bank.current_balance >= table.config[:minimum_bet] &&
        valid_bet_amount.include?(bet_amount)
    end

    def valid_decision(player, bet_box)
      valid_responses = STRATEGY_VALID_INPUT_HASH[:decision]
      #
      # can the player surrender?
      #
      valid_responses.delete(Action::SURRENDER) unless table.config[:player_surrender] && bet_box.hand.length == 2

      #
      # can the player split?
      #
      # TODO: need to enforce hand max splits from table.config
      valid_responses.delete(Action::SPLIT) unless player.bank.current_balance >= bet_box.current_bet && valid_split_hand?(bet_box.hand)

      #
      # can the player double down? (assumes double for less)
      #
      valid_responses.delete(Action::DOUBLE_DOWN) unless player.bank.current_balance == 0 && valid_double_hand?(bet_box.hand)

      #
      # can the player hit?
      #
      valid_responses.delete(Action::HIT) unless bet_box.hand.hittable?

      valid_responses
    end

    def validate_decision(player, bet_box, response)
      valid_decision(player, bet_box).include?(response)
    end

    private

    def valid_split_hand?(hand)
      hand.pair?
    end

    def valid_double_hand?(hand)
      double_down_on = table.config[:double_down_on]
      double_down_on.empty? ||
      double_down_on.include?(hand.hard_sum) ||
      double_down_on.include?(hand.soft_sum)
    end
  end
end
