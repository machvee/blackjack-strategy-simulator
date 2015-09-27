module Blackjack

  class Insurance
    attr_reader   :table
    attr_reader   :dealer

    def initialize(table)
      @table = table
      @dealer = table.dealer
    end

    def ask_players_if_they_want_insurance
      table.bet_boxes.each_active do |bet_box|
        player = bet_box.player

        response = dealer.ask_player_insurance?(bet_box)

        case response
          when Action::NO_INSURANCE
            next
          when Action::INSURANCE
            insurance_bet_amt = dealer.ask_player_insurance_bet_amount(bet_box)
            player.make_insurance_bet(bet_box, insurance_bet_amt)
          when Action::EVEN_MONEY
            #
            # pay even money and clear this hand out now
            #
            if bet_box.hand.blackjack?
              dealer.player_won(bet_box, Table::EVEN_MONEY_PAYOUT)
              bet_box.discard
            end
        end
      end
    end

    def payout_any_insurance_bets
      table.bet_boxes.each_active do |bet_box|
        if bet_box.insurance.balance > 0
          winnings = dealer.money.pay_insurance(bet_box)
          table.game_announcer.hand_outcome(bet_box, Outcome::INSURANCE_WON, winnings)
          bet_box.player.won_insurance_bet(bet_box)
        end
      end
    end

    def collect_insurance_bets
      table.bet_boxes.each_active do |bet_box|
        if bet_box.insurance.balance > 0
          table.game_announcer.hand_outcome(bet_box, Outcome::INSURANCE_LOST, bet_box.insurance.balance)
          bet_box.player.lost_insurance_bet(bet_box)
          dealer.money.collect_insurance_bet(bet_box)
        end
      end
    end

  end
end
