module Blackjack
  class StayDecision < Decision
    #
    # stay at the table and PLAY or cash-out and LEAVE
    #
    VALID_ACTIONS = [
      Action::PLAY,
      Action::LEAVE
    ]

    private

    def get_response
      player.strategy.stay?
    end

    def valid?(response)
      return [false, "Sorry, that's not a valid response"] unless VALID_ACTIONS.include?(response)
      return [false, "Player has insufficient funds to make a bet"] if !player.balance_check(table.config[:minimum_bet])
      [true, nil]
    end
  end
end
