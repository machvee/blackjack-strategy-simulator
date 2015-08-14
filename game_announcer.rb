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

    def says(str)
      printer str
    end

    def dealer_hand_status
      printer "Dealer has " + hand_val_str(dealer.hand)
    end

    def player_hand_status(bet_box)
      printer "%s has %s" % [bet_box.player.name, hand_val_str(bet_box.hand)]
    end

    def hand_outcome(hand, action)
    end

    private

    def printer(msg)
      puts "==> " + msg
    end

    def hand_val_str(hand)
      if !hand.soft? || (hand.soft? && (hand.hard_sum == hand.soft_sum))
        hand.hard_sum.to_s
      else
        "#{hand.soft_sum}/#{hand.hard_sum}"
      end
    end
  end

  class QuietGameAnnouncer < GameAnnouncer
    def says(str)
    end

    def dealer_hand_status
    end

    def player_hand_status(bet_box)
    end

    def hand_outcome(hand, action)
    end
  end
end
