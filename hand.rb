module Blackjack
  class PlayerHand
    attr_reader  :player
    attr_reader  :hand
    attr_reader  :bet_amount
    #
    # each player_hand has a hand and a bet amount
    # a split creates a new player hand for the player
    #
    def initialize(player, bet_amount)
      @player = player
      @bet_amount = bet_amount
    end
  end
end
