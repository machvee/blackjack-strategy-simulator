module Blackjack
  class Shoe
    require 'blackjack_card'
    require 'counters'

    include Cards
    include Counters

    attr_reader  :decks
    attr_reader  :cutoff
    attr_reader  :options
    attr_reader  :discard_pile

    counters  :num_shuffles, :hands_dealt, :cards_dealt

    DEFAULT_OPTIONS = {
      cut_card_segment: 0.25,
      cut_card_offset:  0.05,
      split_and_shuffles: 25,
      num_decks_in_shoe:   1
    }

    def initialize(options={})
      @options = DEFAULT_OPTIONS.merge(options)
      @decks = Deck.new(@options[:num_decks_in_shoe])
      @discard_pile = Cards.new(@decks)
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
      deal_one(destination, Card::FACE_UP)
    end

    def deal_one_down(destination)
      deal_one(destination, Card::FACE_DOWN)
    end

    def shuffle
      discard_pile.fold
      remove_cut_card
      decks.shuffle_up(options[:split_and_shuffles])
      incr_counter :num_shuffles
    end

    def discard(cards)
      discard_pile.add(cards)
      incr_counter :hands_dealt
    end

    private

    def remove_cut_card
      @cutoff = nil
    end

    def beyond_cut?
      cutoff && decks.count < cutoff
    end

    def random_cut_offset
      num_cards = decks.length
      offset_percentage = (num_cards * options[:cut_card_offset]).floor
      (num_cards * options[:cut_card_segment]).floor + rand(-offset_percentage..offset_percentage)
    end

    def deal_one(destination, orientation)
      decks.deal(destination, 1, orientation)
      incr_counter :cards_dealt
    end
  end

  class SingleDeckShoe < Shoe
    def initialize(options={})
      super(options.merge(num_decks_in_shoe: 1))
    end
  end

  class TwoDeckShoe < Shoe
    def initialize(options={})
      super(options.merge(num_decks_in_shoe: 2))
    end
  end

  class SixDeckShoe < Shoe
    def initialize(options={})
      super(options.merge(num_decks_in_shoe: 6))
    end
  end
end
