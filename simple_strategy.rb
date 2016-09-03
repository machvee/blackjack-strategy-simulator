module Blackjack
  class SimpleStrategy < PlayerHandStrategy
    #
    # takes easy/recommended/default actions, leaving more important
    # decisions to sub-classes
    #
    def stay?
      Action::PLAY
    end

    def num_hands
      1
    end

    def bet_amount(bet_box)
      table.config[:minimum_bet]
    end

    def insurance?(bet_box)
      bet_box.hand.blackjack? ? Action::EVEN_MONEY : Action::NO_INSURANCE
    end

    def insurance_bet_amount(bet_box)
      bet_box.bet_amount/2
    end

    def double_down_bet_amount(bet_box)
      bet_box.bet_amount
    end
  end
end
