require 'cards'

module Blackjack
  class DeckWithCutCard < Cards::Deck

    attr_reader  :cutoff

    def place_cut_card(cut_offset=nil)
      @cutoff = cut_offset||random_cut_offset
      raise "invalid cut card placement" if @cutoff <=0 || @cutoff >= (cards.length-1)
    end

    def needs_shuffle?
      beyond_cut?
    end

    def beyond_cut?
      cutoff && cards.count < cutoff
    end

    private

    def random_cut_offset
      #
      # put the cut card near the back 25% of the deck +/- 10% (15-35%)
      #
      num_cards = cards.length
      ten_percent = (num_cards * 0.10).floor
      (num_cards * 0.25).floor + rand(-ten_percent..ten_percent)
    end

  end
end
