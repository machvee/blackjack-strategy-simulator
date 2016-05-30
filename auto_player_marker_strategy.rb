module Blackjack
  class AutoPlayerMarkerStrategy < SimpleDelegator
    #
    # will get a marker for at least twice what the player needs in his 
    # default bet_box so his funds are available for at least doubling
    # or splitting
    #

    def initialize(strategy)
      super
    end

    def stay?
      player_needs(num_bets * bet_amount(player.default_bet_box)*2)
      super
    end

    private 

    def player_needs(amount)
      if player.bank.balance < amount
        player.marker_for([player.bank.initial_deposit, amount].max)
      end
    end
  end
end
