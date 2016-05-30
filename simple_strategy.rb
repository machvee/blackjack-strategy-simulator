module Blackjack
  class SimpleStrategy < PlayerHandStrategy
    #
    # takes easy/recommended/default actions, leaving more important
    # decisions to sub-classes
    #
    def stay?
      player.bank.balance >= table.config[:minimum_bet] ? Action::PLAY : Action::LEAVE
    end

    def num_bets
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
      [bet_box.bet_amount, player.bank.balance].min
    end
  end
end
