module Blackjack
  class BetAmountDecision < Decision

    def get_response(bet_box=nil)
      player.strategy.bet_amount(bet_box)
    end

    def valid?(response, bet_box=nil)
      bet_amount = response
      max_legal_bet = bet_box.bet_amount / 2.0
      legal_bet_range = 1..max_legal_bet

      if !legal_bet_range.include?(bet_amount)
        [false, "Player insurance bet must be between #{legal_bet_range.min} and #{legal_bet_range.max}"]
      else
        [true, "%s BETS $%.2f" % [player.name, response]]
      end
    end
  end
end
