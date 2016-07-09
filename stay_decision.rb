module Blackjack
  class StayDecision < Decision
    #
    # stay at the table and PLAY or cash-out and LEAVE
    #
    VALID_ACTIONS = [
      Action::PLAY,
      Action::LEAVE
    ]

    def get_response(bet_box=nil)
      player.strategy.stay?
    end

    def valid?(response, bet_box=nil)
      return [false, "Sorry, that's not a valid response"] unless VALID_ACTIONS.include?(response)
      return [false, "Player has insufficient funds to make a bet"] if !player.balance_check(table.config[:minimum_bet])
      [true, nil]
    end
  end
end
