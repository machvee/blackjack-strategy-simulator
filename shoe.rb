module Blackjack
  class Shoe

    include Cards

    attr_reader  :decks
    attr_reader  :cutoff
    attr_reader  :options
    attr_reader  :discard_pile

    DEFAULT_OPTIONS = {
      cut_card_segment: 0.25,
      cut_card_offset:  0.05,
      split_and_shuffles: 25,
      num_decks_in_shoe:   1
    }

    def initialize(table, options={})
      @table = table
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
      decks.deal(destination, 1, Card::FACE_UP)
    end

    def deal_one_down(destination)
      decks.deal(destination, 1, Card::FACE_DOWN)
    end

    def shuffle
      discard_pile.fold
      remove_cut_card
      decks.shuffle_up(options[:split_and_shuffles])
    end

    def discard(cards)
      discard_pile.add(cards)
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
  end

  class SingleDeckShoe < Shoe
    def initialize(table, options={})
      super(table, options.merge(num_decks_in_shoe: 1))
    end
  end

  class TwoDeckShoe < Shoe
    def initialize(table, options={})
      super(table, options.merge(num_decks_in_shoe: 2))
    end
  end

  class SixDeckShoe < Shoe
    def initialize(table, options={})
      super(table, options.merge(num_decks_in_shoe: 6))
    end
  end
end
