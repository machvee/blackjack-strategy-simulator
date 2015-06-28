module Blackjack
  class GamePlay
    #
    # 1. dealer examines his up card
    # 2. if 10 he looks at bottom card for A, if A he
    #    flips his blackjack and all players lose, unless player has natural 21
    # 3. If dealer has A showing, he asks for insurance, and those with natural 21 push or take even money
    # 4. If not a blackjack, he takes the insurance bets
    # 5. He asks each player in sequence if:
    # 6. If player has a 2 card hand:
    #   a. Player can indicate they want a Hit
    #      Dealer deals them a card from the deck
    #   b. Player can indicate if they want to Double Down
    #      Player must have legal 2-card hand and funds.
    #      He adds up to 100% of the bet, and Dealer deals one card
    #   c. Player can indicate they want to Split a pair
    #      Player places additional bet equal to current bet.
    #      Dealer divides cards and if Aces, deals one card to each
    #      If non-Ace split, Dealer plays each hand as starting from 5.
    #      (there may be limits on how many times cards may be split)
    # 7. If a players busts, Dealer takes the cards and bet
    #    Dealer moves to next player, if any
    # 7. If Stand, moves on to the next player
    # 8. If a player hits, he deals one card.
    # 9. If a player 
    #
    attr_reader   :table
    attr_reader   :dealer
    attr_reader   :players

    def initialize(table, dealer, players)
      @table =  table
      @dealer = dealer
      @players = players
    end

  end
end
