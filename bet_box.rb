module Blackjack
  class BetBox
    attr_reader :table
    attr_reader :player
    attr_reader :bet_amount
    attr_reader :hand

    include Cards

    def initialize(table)
      @table = table
      reset
    end

    def bet(player, bet_amount)
      @player = player
      @bet_amount = bet_amount
      @hand = Cards.new(table.shoe.decks)
    end

    def <<(card)
      hand << card
    end

    def discard
      hand.discard
      reset
    end

    def reset
      @player = nil
      @bet_amount = 0
      @hand = nil
    end
  end
end
