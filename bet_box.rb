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
      @hand = table.new_hand
      reset
    end

    def dedicated?
      #
      # bet box has a seated player in front of it
      #
      !table.seated_players[position].nil?
    end

    def available?
      #
      # adjacent seated players may place a bet here
      # when its available?
      #
      !dedicated? && player.nil?
    end

    def active?
      #
      # A player has a bet in this bet box
      # adjacent seated players may not place a bet here
      # when its active?
      #
      !player.nil?
    end

    def bet(player, bet_amount)
      #
      # player makes a bet
      #
      @player = player
      player.bank.transfer_to(box, bet_amount)
    end

    def take_winnings
      box.transfer_to(player.bank, box.current_balance)
    end

    def split
      raise "player hand is already split" unless split_bet_box.nil?
      @split_bet_box = BetBox.new(table)
    end

    def discard
      split_bet_box.discard unless split_bet_box.nil?
      hand.fold
      reset
    end

    def current_bet
      box.current_balance
    end

    def position
      @pos ||= table.bet_boxes.index(self)
    end

    def reset
      @player = nil
      @amount = 0
      @split_bet_box = nil
    end
  end
end
