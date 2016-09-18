module Blackjack
  class DealerStats
    attr_reader     :hand
    attr_reader     :bust
    attr_reader     :dealer

    def initialize(dealer)
      @dealer = dealer
      @hand = HandStats.new
      @bust = BustStats.new(dealer)
    end

    def player_lost
      hand.won.incr
    end

    def player_won
      hand.lost.incr
    end

    def player_push
      hand.pushed.incr
    end

    def blackjack
      hand.blackjacks.incr
    end

    def print
      print_header
      hand.print
      bust.print
    end

    def reset
      hand.reset
      bust.reset
    end

    private

    def print_header
      puts "\n"
      puts ("="*16) + " DEALER " + ("="*16)
    end

  end
end
