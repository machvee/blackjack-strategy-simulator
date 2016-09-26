module Blackjack
  class CustomBetAmountStrategy < BasicStrategy
    def bet_amount
      random(1..20) * table.config[:minimum_bet]
    end
  end
end
