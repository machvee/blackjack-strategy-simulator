module Blackjack
  class GameAnnouncer
    #
    # output a brief status to STDOUT to inform a view of play information
    # sub-class this to show alternate output (e.g. SilentGameAnnouncer)
    #
    attr_reader  :table
    attr_reader  :dealer

    def initialize(table, options={})
      @table = table
      @dealer = table.dealer
    end

    def overview
    end

    def dealer_hand_status
    end

    def player_hand_status(bet_box, decision, opt_bet_amt=nil)
    end

    def hand_outcome(hand, action, amount=nil)
    end

    def play_by_play(klass, player, response)
    end

    def says(msg)
    end
  end

  class RoundsPlayedGameAnnouncer < GameAnnouncer
    def overview
      r = table.stats.rounds_played.count
      puts r if r % 1000 == 0
    end
  end

  class StdoutGameAnnouncer < GameAnnouncer
    def overview
      remaining = table.shoe.remaining_until_shuffle
      marker_status = if remaining.nil?
        ""
      elsif remaining == 0
        "at marker card"
      elsif remaining > 0
        " #{remaining} cards remain"
      else
        " #{remaining.abs} cards beyond"
      end

      says "#{table.name}: #{marker_status}, %5.1f%% tens" % table.shoe.current_ten_percentage

      table.each_player do |player|
        says "  #{player}"
      end
    end

    def dealer_hand_status
      if dealer.hand.flipped?
        bust_str = dealer.hand.bust? ? " BUST!" : ""
        says "Dealer has " + hand_val_str(dealer.hand) + bust_str
      else
        says "******* Round ##{table.stats.rounds_played.count}: Dealer's showing %s %s" % [dealer.showing, dealer.hand]
      end
    end

    def player_hand_status(bet_box, decision=nil, opt_bet_amt=nil)
      dec_s = Action.action_name(decision) 
      hvs = hand_val_str(bet_box.hand, bet_box.from_split?)
      if decision.nil? && opt_bet_amt.nil?
        says "%s has %s" % [bet_box.player_name, hvs]
      elsif opt_bet_amt.nil?
        says "%s %s for %s" % [bet_box.player_name, dec_s, hvs]
      else
        says "%s %s for $%s : has %s" % [bet_box.player_name, dec_s, opt_bet_amt, hvs]
      end
    end

    def hand_outcome(bet_box, outcome, amount=nil)
      msg = case outcome
        when Outcome::WON
          "%s WINS +$%.2f" % [bet_box.player_name, amount]
        when Outcome::LOST
          "%s LOST -$%.2f" % [bet_box.player_name, amount]
        when Outcome::INSURANCE_WON
          "%s WINS INSURANCE +$%.2f" % [bet_box.player_name, amount]
        when Outcome::INSURANCE_LOST
          "%s LOST INSURANCE -$%.2f" % [bet_box.player_name, amount]
        when Outcome::PUSH
          "%s PUSH" % [bet_box.player_name]
        when Outcome::BUST
          "%s HITS for %s and BUSTS -$%.2f" % [
            bet_box.player_name,
                   hand_val_str(bet_box.hand, bet_box.from_split?),
                                  amount]
        when Outcome::NONE
          nil
      end
      says msg
    end

    def play_by_play(klass, player, response)
      msg = case klass
        when NumHandsDecision
          case response
            when 0
              "%s SITS OUT" % player.name
            else
              nil
          end
        when BetAmountDecision
          "%s BETS $%.2f" % [player.name, response]
        when InsuranceDecision
          case response
            when Action::NO_INSURANCE
              "%s says NO INSURANCE" % player.name
            when Action::EVEN_MONEY
              "%s has Blackjack and takes EVEN MONEY" % player.name
            else
              nil
          end
        when InsuranceBetAmountDecision
           "%s takes INSURANCE for $%.2f" % [player.name, response]
        else
          nil
      end
      says msg
    end

    def says(msg)
      printer msg unless msg.nil?
    end

    private

    def printer(msg)
      puts "==> " + msg
    end

    def hand_val_str(hand, from_split=false)
      if hand.blackjack? && !from_split
        "BLACKJACK!"
      elsif !hand.soft? || (hand.soft? && (hand.hard_sum == hand.soft_sum || hand.hard_sum >= 17))
        hand.hard_sum.to_s
      else
        "#{hand.soft_sum}/#{hand.hard_sum}"
      end + " #{hand}"
    end
  end

end
