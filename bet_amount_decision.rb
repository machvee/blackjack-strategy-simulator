module Blackjack
  class BetAmountDecision < Decision

    private

    def get_response
      player.strategy.bet_amount
    end

    def valid?(response)
      bet_amount = response
      legal_bet_range = table.config[:minimum_bet]..table.config[:maximum_bet]
      if !legal_bet_range.include?(bet_amount)
        [false, "Player bet must be between #{legal_bet_range.min} and #{legal_bet_range.max}"]
      else
        [true, nil]
      end
    end
  end
end
