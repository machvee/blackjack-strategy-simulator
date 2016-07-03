module Blackjack
  class NumBetsDecision < Decision

    private

    def get_response(bet_box=nil)
      player.strategy.num_bets
    end

    def valid?(response, bet_box=nil)
      #
      # player must have minimum bet amount * num_bets in bank in order to
      # place a bet and ask for only the number of bets that are legal for this 
      # table and have bet_boxes available
      #
      max_available_boxes = table.bet_boxes.num_available_for(player)
      max_possible_bets = table.config[:max_player_bets]
      min_bet = table.config[:minimum_bet]

      if num_bets < 0
        [false, "You must enter a number between 0-#{max_available_boxes}"]
      elsif num_bets > max_possible_bets
        [false, "You can only make up to #{max_possible_bets} bets at this table"]
      elsif num_bets > max_available_boxes
        [false, "There %s only %d bet box%s available" % [
            max_available_boxes == 1 ? 'is' : 'are',
            max_available_boxes,
            max_available_boxes == 1 ? '' : 'es'
          ]]
      elsif !player.balance_check(min_bet*num_bets)
        [false, "Player has insufficient funds to make %d bet%s of %d" % [
          num_bets,
          num_bets == 1 ? "" : "s",
          min_bet
        ]]
      else
        [true, nil]
      end
    end
  end
end
