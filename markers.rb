module Blackjack
  class Markers
    attr_reader :table
    attr_reader :markers

    def initialize(table)
      @table = table
      @markers = []
    end

    def for_player(player)
      unpaid_markers_for_player(player)
    end

    def borrow(player, amount)
      markers << {player: player, amount: amount, paid: false}
      table.house.transfer_to(player.bank, amount)
    end

    def repay_markers(player, max_amount=nil)
      #
      # repay all markers (up to the optional amount) by transferring
      # from the player account to the house
      #
      unpaid_markers = unpaid_markers_for_player(player)
      return 0 unless unpaid_markers.any?

      valid?(player, max_amount)

      max_amount = max_amount.nil? ? player.bank.balance : max_amount
      amt_to_pay = max_amount

      unpaid_markers.each do |marker|
        amt_to_pay_marker = [amt_to_pay, marker[:amount]].min
        pay_marker(player, marker, amt_to_pay_marker)
        amt_to_pay -= amt_to_pay_marker
        break if amt_to_pay == 0
      end

      max_amount
    end

    private

    def pay_marker(player, marker, amount)
      marker[:amount] -= amount
      marker[:paid] = true if marker[:amount].zero?
      player.bank.transfer_to(table.house, amount)
    end

    def valid?(player, max_amount)
      if !max_amount.nil? && max_amount > player.bank.balance
        raise "player bank balance is only %d.  Unable to pay back %d" %
          [player.bank.balance, max_amount]
      end
    end

    def unpaid_markers_for_player(player)
      markers.select {|h| h[:player] == player && !h[:paid]}
    end
  end
end
