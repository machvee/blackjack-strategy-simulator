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

    private

    def get_response
      player.strategy.play(bet_box, table.dealer.up_card, table.other_hands(bet_box))
    end

    def valid?(response)
      #
      # its a programming error to ask to validate a decision on an
      # already split bet_box.  decisions should be asked instead on the
      # bet_boxes returned by the bet_box.split_boxes.each
      #
      raise "this bet_box has been split" if bet_box.split?
      return [false, "Sorry, that's not a valid response"] unless VALID_ACTIONS.include?(response)

      valid_resp, error_message = case response
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
          if !player.balance_check(bet_box.bet_amount)
            [false, "Player has insufficient funds to split the hand"]
          elsif !bet_box.hand.pair?
            [false, "Player can only split cards that are identical in value"]
          elsif !bet_box.can_split?
            [false, "The hand in this bet box can't be split"]
          end
        when Action::DOUBLE_DOWN
          #
          # can the player double down? (assumes double for less)
          #
          if !player.balance_check(1)
            [false, "Player has insufficient funds to double down"]
          elsif !bet_box.hand_doublable?
            [false, "Player can only double down on two-card hands#{valid_double_hand_values}"]
          elsif !bet_box.from_split_and_double_allowed?
            [false, "Player not allowed double down after split on this table"]
          end
        when Action::HIT
          #
          # can the player hit?
          #
          if !bet_box.hand.hittable?
            [false, "Player hand can no longer be hit after hard 21"]
          end
        end || [true, nil]

      [valid_resp, error_message]
    end

    def valid_double_hand_values
      ddo = table.config[:double_down_on]
      ddo.empty? ?  "" : " of #{ddo.map(&:to_s).join(', ')}"
    end
  end
end
