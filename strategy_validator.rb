require 'player_hand_strategy'

module Blackjack
  class StrategyValidator

    STRATEGY_VALID_INPUT_HASH = {
      num_bets: [
        Action::LEAVE,
        Action::SIT_OUT,
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

    def validate_num_bets(player, num_bets)
      return [true, nil] if STRATEGY_VALID_INPUT_HASH[:num_bets].include?(num_bets)
      #
      # player must have minimum bet amount * num_bets in bank in order to
      # place a bet and ask for only the number of bets that are legal for this 
      # table and have bet_boxes available
      #
      max_available_boxes = table.bet_boxes.num_available_for(player)
      max_possible_bets = table.config[:max_player_bets]
      min_bet = table.config[:minimum_bet]

      if num_bets < Action::LEAVE
        [false, "You must enter a number between 1-#{max_available_boxes}"]
      elsif num_bets > max_possible_bets
        [false, "You can only make up to #{max_possible_bets} bets at this table"]
      elsif num_bets > max_available_boxes
        [false, "There %s only %d bet box%s available" % [
            max_available_boxes == 1 ? 'is' : 'are',
            max_available_boxes,
            max_available_boxes == 1 ? '' : 'es'
          ]]
      elsif player.bank.balance < (min_bet*num_bets)
        [false, "Player has insufficient funds to make %d bet%s of %d" % [
          num_bets,
          num_bets == 1 ? "" : "s",
          min_bet
        ]]
      else
        [true, nil]
      end
    end

    def validate_insurance?(bet_box, response)
      #
      # player must have blackjack in order to ask
      # for Action::EVEN_MONEY
      #
      # player must have bet_amount/2 in bank in order
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
            if player.bank.balance < bet_box.bet_amount/2.0
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
      if player.bank.balance < table.config[:minimum_bet]
        [false, "Player has insufficient funds to make a #{table.config[:minimum_bet]} minimum bet"]
      elsif !valid_bet_amount.include?(bet_amount)
        [false, "Player bet must be between #{valid_bet_amount.min} and #{valid_bet_amount.max}"]
      else
        [true, nil]
      end
    end

    def validate_insurance_bet(bet_box, bet_amount)
      max_legal_bet = bet_box.bet_amount / 2.0
      legal_bet_range = 1..max_legal_bet
      if !legal_bet_range.include?(bet_amount)
        [false, "Player insurance bet must be between #{legal_bet_range.min} and #{legal_bet_range.max}"]
      else
        [true, nil]
      end
    end

    def validate_double_down_bet(bet_box, bet_amount)
      max_legal_bet = bet_box.bet_amount
      legal_bet_range = 1..max_legal_bet
      if !legal_bet_range.include?(bet_amount)
        [false, "Player double bet must be between #{legal_bet_range.min} and #{legal_bet_range.max}"]
      else
        [true, nil]
      end
    end

    def validate_decision(bet_box, response)
      #
      # its a programming error to ask to validate a decision on an
      # already split bet_box.  decisions should be asked instead on the
      # bet_boxes returned by the bet_box.split_boxes.each
      #
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
            if player.bank.balance < bet_box.bet_amount
              [false, "Player has insufficient funds to split the hand"]
            elsif !valid_split_hand?(bet_box.hand)
              [false, "Player can only split cards that are identical in value"]
            end
          when Action::DOUBLE_DOWN
            #
            # can the player double down? (assumes double for less)
            #
            if player.bank.balance == 0 
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
