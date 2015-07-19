module Blackjack
  class BetBox
    attr_reader :table
    attr_reader :player
    attr_reader :box
    attr_reader :hand
    attr_reader :split_bet_box

    include Cards

    def initialize(table)
      @table = table
      @box = Bank.new(0)
      reset
    end

    def available?
      player.nil?
    end

    def active?
      !available
    end

    def bet(player, bet_amount)
      raise "this bet_box is occupied" unless player.nil?
      @player = player

      player.bank.transfer_to(box, amount)

      @hand = Cards.new(table.shoe.decks)
    end

    def take_winnings
      box.transfer_to(player.bank, box.current_balance)
    end

    def split
      raise "player hand is already split" unless split_bet_box.nil?
      @split_bet_box = BetBox.new(table)
    end

    def <<(card)
      hand << card
    end

    def discard
      split_bet_box.discard unless split_bet_box.nil?
      hand.discard
      reset
    end

    def reset
      @player = nil
      @amount = 0
      @hand = nil
      @split_bet_box = nil
    end
  end
end
