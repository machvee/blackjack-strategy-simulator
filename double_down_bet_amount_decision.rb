module Blackjack
  class DoubleDownBetAmountDecision < Decision

    def get_response(bet_box=nil)
      player.strategy.double_down_bet_amount(bet_box)
    end

    def valid?(response, bet_box=nil)
      bet_amount = response
      max_legal_bet = bet_box.bet_amount
      legal_bet_range = 1..max_legal_bet

      if !legal_bet_range.include?(bet_amount)
        [false, "Player double bet must be between #{legal_bet_range.min} and #{legal_bet_range.max}"]
      else
        [true, nil]
      end
    end
  end
end
