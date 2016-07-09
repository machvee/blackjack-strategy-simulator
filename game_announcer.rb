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

    def play_by_play(step, player, response)
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
      says "%s %s %s%s" % [
        bet_box.player_name,
        decision.nil? ? "has" : Action.action_name(decision),
        opt_bet_amt.nil? ? "" : "for $#{opt_bet_amt} : ",
        hand_val_str(bet_box.hand, bet_box.from_split?)
      ]
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
          "%s HITS %s, and BUSTS -$%.2f" % [
            bet_box.player_name,
                   hand_val_str(bet_box.hand, bet_box.from_split?),
                                  amount]
        when Outcome::NONE
          nil
      end
      says msg
    end

    def play_by_play(msg)
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
