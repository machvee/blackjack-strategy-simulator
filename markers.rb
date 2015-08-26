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
      return unless unpaid_markers.any?

      limit_to_pay_back = max_amount.nil? ? player.bank.balance : max_amount
      total_amount_paid_back = 0

      unpaid_markers.each do |marker|
        amt_to_pay = marker[:amount]
        if total_amount_paid_back + amt_to_pay > limit_to_pay_back
          amt_to_pay = total_amount_paid_back + amt_to_pay - limit_to_pay_back
          marker[:amount] -= amt_to_pay
        else
          marker[:paid] = true
        end
        player.bank.transfer_to(table.house, amt_to_pay)
        total_amount_paid_back += amt_to_pay
        break if total_amount_paid_back == limit_to_pay_back
      end
    end

    private

    def unpaid_markers_for_player(player)
      markers.select {|h| h[:player] == player && !h[:paid]}
    end
  end
end
