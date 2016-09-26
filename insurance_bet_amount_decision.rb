module Blackjack
  class InsuranceBetAmountDecision < Decision

    private

    def get_response
      player.strategy.insurance_bet_amount(bet_box)
    end

    def valid?(response)
      bet_amount = response
      max_legal_bet = bet_box.bet_amount / 2.0
      legal_bet_range = 1..max_legal_bet
      if !legal_bet_range.include?(bet_amount)
        [false, "Player insurance bet must be between #{legal_bet_range.min} and #{legal_bet_range.max}"]
      else
        [true, nil]
      end
    end
  end
end
