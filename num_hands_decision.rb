module Blackjack
  class NumHandsDecision < Decision

    private

    def get_response
      player.strategy.num_hands
    end

    def valid?(response)
      #
      # player must have minimum bet amount * num_hands in bank in order to
      # place a bet and ask for only the number of bets that are legal for this 
      # table and have bet_boxes available
      #
      num_hands = response
      max_available_boxes = table.bet_boxes.num_available_for(player)
      max_possible_bets = table.config[:max_player_bets]
      min_bet = table.config[:minimum_bet]

      if num_hands < 0
        [false, "You must enter a number between 0-#{max_available_boxes}"]
      elsif num_hands > max_possible_bets
        [false, "You can only make up to #{max_possible_bets} bets at this table"]
      elsif num_hands > max_available_boxes
        [false, "There %s only %d bet box%s available" % [
            max_available_boxes == 1 ? 'is' : 'are',
            max_available_boxes,
            max_available_boxes == 1 ? '' : 'es'
          ]]
      elsif !player.balance_check(min_bet*num_hands)
        [false, "Player has insufficient funds to make %d bet%s of %d" % [
          num_hands,
          num_hands == 1 ? "" : "s",
          min_bet
        ]]
      else
        [true, nil]
      end
    end
  end
end
