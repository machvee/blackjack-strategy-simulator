module Blackjack
  class BetBox
    attr_reader :table
    attr_reader :player
    attr_reader :box
    attr_reader :hand
    attr_reader :position
    attr_reader :split_bet_box

    include Cards

    def initialize(table, player_seat_position)
      @table = table
      @box = Bank.new(0)
      @hand = table.new_hand
      @position = player_seat_position
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
      raise "player hand is already split" if split?
      @split_bet_box = BetBox.new(table, position)
    end

    def split?
      !@split_bet_box.nil?
    end

    def discard
      split_bet_box.discard unless split_bet_box.nil?
      hand.fold
      reset
    end

    def current_bet
      box.current_balance
    end

    def reset
      @player = nil
      @amount = 0
      @split_bet_box = nil
    end

    def inspect
      available? ? "Available BetBox #{position}" : "Dedicated BetBox #{position} for #{player.name}"
    end
  end
end
