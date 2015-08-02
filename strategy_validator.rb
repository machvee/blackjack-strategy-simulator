require 'player_hand_strategy'

module Blackjack
  class StrategyValidator

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

    def validate_play?(player, response)
      #
      # player must have minimum bet amount in bank in order to
      # place a bet
      #
      if !STRATEGY_VALID_INPUT_HASH[:play].include?(response)
        [false, "Sorry, that's not a valid response"]
      elsif player.bank.current_balance < table.config[:minimum_bet]
        [false, "Player has insufficient funds to make a #{table.config[:minimum_bet]} minimum bet"]
      else
        [true, nil]
      end
    end

    def validate_insurance?(bet_box, response)
      #
      # player must have blackjack in order to ask
      # for Action::EVEN_MONEY
      #
      # player must have current_bet/2 in bank in order
      # take Action::INSURANCE
      #
      # Action::NO_INSURANCE is always valid
      #
      if !STRATEGY_VALID_INPUT_HASH[:insurance].include?(response)
        [false, "Sorry, that's not a valid response"]
      else
        player = bet_box.player
        valid_resp, error_message =
          case response
          when Action::INSURANCE
            if player.bank.current_balance < bet_box.current_bet/2.0
              [false, "Player has insufficient funds to make an insurance bet"]
            end
          when Action::EVEN_MONEY
            if !bet_box.hand.blackjack?
              [false, "Player must have Blackjack to request even money"]
            end
          end
          valid_resp.nil? ? [true, nil] : [valid_resp, error_message]
      end
    end


    def validate_bet_amount(player, bet_amount)
      valid_bet_amount = table.config[:minimum_bet]..table.config[:maximum_bet]

      if player.bank.current_balance < table.config[:minimum_bet]
        [false, "Player has insufficient funds to make a #{table.config[:minimum_bet]} minimum bet"]
      elsif !valid_bet_amount.include?(bet_amount)
        [false, "Player bet must be between #{valid_bet_amount.min} and #{valid_bet_amount.max}"]
      else
        [true, nil]
      end
    end

    def validate_decision(bet_box, response)

      # its a programming error to ask for a decision on a bet_box already split
      raise "this bet_box has been split" if bet_box.split?

      if !STRATEGY_VALID_INPUT_HASH[:decision].include?(response)
        [false, "Sorry, that's not a valid response"]
      else
        player = bet_box.player
        valid_resp, error_message =
          case response
          when Action::SURRENDER 
            #
            # can the player surrender?
            #
            if !table.config[:player_surrender] 
              [false, "This table does not allow player to surrender"]
            elsif bet_box.hand.length > 2 || bet_box.from_split?
              [false, "Player may surrender on initial two cards dealt"]
            end
          when Action::SPLIT
            #
            # can the player split?
            #
            # TODO: need to enforce hand max splits from table.config
            #
            if player.bank.current_balance < bet_box.current_bet
              [false, "Player has insufficient funds to split the hand"]
            elsif !valid_split_hand?(bet_box.hand)
              [false, "Player can only split cards that are identical in value"]
            end
          when Action::DOUBLE_DOWN
            #
            # can the player double down? (assumes double for less)
            #
            if player.bank.current_balance == 0 
              [false, "Player has insufficient funds to double down"]
            elsif !valid_double_hand?(bet_box.hand)
              [false, "Player can only double down on hands of #{valid_double_hand_values}"]
            end
          when Action::HIT
            #
            # can the player hit?
            #
            if !bet_box.hand.hittable?
              [false, "Player hand can no longer be hit after hard 21"]
            end
          end
          valid_resp.nil? ? [true, nil] : [valid_resp, error_message]
      end
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

    def valid_double_hand_values
      table.config[:double_down_on].map(&:to_s).join(', ')
    end
  end
end
