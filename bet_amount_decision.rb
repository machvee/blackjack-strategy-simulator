module Blackjack
  class BetAmountDecision < Decision

    private

    def get_response(bet_box=nil)
      player.strategy.bet_amount(bet_box)
    end

    def valid?(response, bet_box=nil)
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
