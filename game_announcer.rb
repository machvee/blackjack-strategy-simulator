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

    def player_hand_status(bet_box)
    end

    def hand_outcome(hand, action, winnings=nil)
    end

    def play_by_play(step, player, response)
    end

    def says(msg)
    end
  end

  class StdoutGameAnnouncer < GameAnnouncer
    def overview
      says "#{table.name}: #{table.shoe.remaining_until_shuffle} cards remain"
      table.each_player do |player|
        says "  #{player}"
      end
    end

    def dealer_hand_status
      if dealer.hand.flipped?
        bust_str = dealer.hand.bust? ? " BUST!" : ""
        says "Dealer has " + hand_val_str(dealer.hand) + bust_str
      else
        says "Dealer's showing %s %s" % [dealer.showing, dealer.hand]
      end
    end

    def player_hand_status(bet_box)
      says "%s has %s" % [bet_box.player.name, hand_val_str(bet_box.hand)]
    end

    def hand_outcome(bet_box, outcome, winnings=nil)
      msg = case outcome
        when Outcome::WON
          "%s WINS %d" % [ bet_box.player.name, winnings ]
        when Outcome::LOST
          "%s LOST" % [ bet_box.player.name]
        when Outcome::PUSH
          "%s PUSH" % [ bet_box.player.name]
        when Outcome::BUST
          "%s BUSTS" % [ bet_box.player.name]
        when Outcome::NONE
          nil
      end
      says msg
    end

    def play_by_play(step, player, response)
      msg = case step
        when :num_bets
          case response
            when Action::SIT_OUT
              "%s sits this one out" % player.name
            else
              nil
          end
        when :bet_amount
          "%s bets %s" % [player.name, response]
        when :insurance
          case response
            when Action::NO_INSURANCE
              "%s says No Insurance" % player.name
            when Action::EVEN_MONEY
              "%s has Blackjack and takes Even Money" % player.name
            else
              nil
          end
        when :insurance_bet_amount
           "%s takes Insurance for %d" % [player.name, response]
        when :double_down_bet_amount
           "%s double downs with %d" % [player.name, response]
        when :decision
          player.name + case response
            when Action::HIT
              " HITS"
            when Action::STAND
              " STANDS"
            when Action::SPLIT
              " SPLITS"
            when Action::DOUBLE_DOWN
              " DOUBLE DOWNS"
            when Action::SURRENDER
              " SURRENDERS"
          end
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

    def hand_val_str(hand)
      if hand.blackjack?
        "BLACKJACK!"
      elsif !hand.soft? || (hand.soft? && (hand.hard_sum == hand.soft_sum))
        hand.hard_sum.to_s
      else
        "#{hand.soft_sum}/#{hand.hard_sum}"
      end + " #{hand}"
    end
  end

end
