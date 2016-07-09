module Blackjack
  class PlayDecision < Decision
    #
    # What Action to take when dealer ask player how he wants to play his hand
    #

    VALID_ACTIONS = [
      Action::HIT,
      Action::STAND,
      Action::SPLIT,
      Action::DOUBLE_DOWN,
      Action::SURRENDER
    ]

    def valid?(response, bet_box=nil)
      #
      # its a programming error to ask to validate a decision on an
      # already split bet_box.  decisions should be asked instead on the
      # bet_boxes returned by the bet_box.split_boxes.each
      #
      raise "this bet_box has been split" if bet_box.split?
      return [false, "Sorry, that's not a valid response"] unless VALID_ACTIONS.include?(response)

      case response
        when Action::SURRENDER 
          validate_surrender(bet_box)
        when Action::SPLIT
          validate_split(bet_box)
        when Action::DOUBLE_DOWN
          validate_double_down(bet_box)
        when Action::HIT
          validate_hit(bet_box)
      end || [true, nil]
    end

    def get_response(bet_box=nil)
      player.strategy.play(bet_box, table.dealer.up_card, table.other_hands)
    end

    private

    def validate_surrender(bet_box)
      if !table.config[:player_surrender] 
        [false, "This table does not allow player to surrender"]
      elsif bet_box.hand.length > 2 || bet_box.from_split?
        [false, "Player may surrender on initial two cards dealt"]
      end
    end

    def validate_split(bet_box)
      if !player.balance_check(bet_box.bet_amount)
        [false, "Player has insufficient funds to split the hand"]
      elsif !valid_split_hand?(bet_box.hand)
        [false, "Player can only split cards that are identical in value"]
      elsif !bet_box.can_split?
        [false, "The hand in this bet box can't be split"]
      end
    end

    def validate_double_down(bet_box)
      if !player.balance_check(1)
        [false, "Player has insufficient funds to double down"]
      elsif !valid_double_hand?(bet_box.hand)
        [false, "Player can only double down on hands of #{valid_double_hand_values}"]
      end
    end

    def validate_hit(bet_box)
      if !bet_box.hand.hittable?
        [false, "Player hand can no longer be hit after hard 21"]
      end
    end

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
