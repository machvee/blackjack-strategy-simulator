module Blackjack
  class InsuranceDecision < Decision

    VALID_ACTIONS = [
      Action::INSURANCE,
      Action::NO_INSURANCE,
      Action::EVEN_MONEY,
    ]

    def get_response(bet_box=nil)
      player.strategy.insurance?
    end

    def valid?(response, bet_box=nil)
      #
      # player must have blackjack in order to ask
      # for Action::EVEN_MONEY
      #
      # player must have bet_amount/2 in bank in order
      # take Action::INSURANCE
      #
      # Action::NO_INSURANCE is always valid
      #
      return [false, "Sorry, that's not a valid response"] unless VALID_ACTIONS.include?(response)

      case response
        when Action::INSURANCE
          if !player.balance_check(bet_box.bet_amount/2.0)
            [false, "Player has insufficient funds to make an insurance bet"]
          end
        when Action::EVEN_MONEY
          if bet_box.hand.blackjack?
            [true, "%s has Blackjack and takes EVEN MONEY" % player.name]
          else
            [false, "Player must have Blackjack to request even money"]
          end
        when Action::NO_INSURANCE
          [true, "%s says NO INSURANCE" % player.name]
      end
    end
  end
end
