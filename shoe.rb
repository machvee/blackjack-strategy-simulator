module Blackjack
  class Shoe

    include Cards

    NUM_SPLIT_AND_SHUFFLES=25

    attr_reader  :decks
    attr_reader  :cutoff

    def initialize(num_decks)
      @decks = Deck.new(num_decks)
      shuffle
    end

    def place_cut_card(cut_offset=nil)
      @cutoff = cut_offset||random_cut_offset
      raise "invalid cut card placement" if cutoff <=0 || cutoff >= (decks.length-1)
    end

    def needs_shuffle?
      beyond_cut?
    end

    def deal_one_up(destination)
      decks.deal(destination, 1, Card::FACE_UP)
    end

    def deal_one_down(destination)
      decks.deal(destination, 1, Card::FACE_DOWN)
    end

    def shuffle
      remove_cut_card
      decks.shuffle_up(NUM_SPLIT_AND_SHUFFLES)
    end

    private

    def remove_cut_card
      @cutoff = nil
    end

    def beyond_cut?
      cutoff && decks.count < cutoff
    end

    def random_cut_offset
      #
      # put the cut card near the back 25% of the deck +/- 10% (15-35%)
      #
      num_cards = decks.length
      ten_percent = (num_cards * 0.10).floor
      (num_cards * 0.25).floor + rand(-ten_percent..ten_percent)
    end
  end

  class SingleDeckShoe < Shoe
    def initialize
      super(6)
    end
  end

  class TwoDecksShoe < Shoe
    def initialize
      super(6)
    end
  end

  class SixDeckShoe < Shoe
    def initialize
      super(6)
    end
  end
end
