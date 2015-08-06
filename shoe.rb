require 'blackjack_card'
require 'counter_measures'

module Blackjack
  class Shoe

    include Cards
    include CounterMeasures

    attr_reader  :decks
    attr_reader  :cutoff
    attr_reader  :options
    attr_reader  :discard_pile

    counters  :num_shuffles, :cards_dealt

    DEFAULT_OPTIONS = {
      cut_card_segment: 0.25,
      cut_card_offset:  0.05,
      split_and_shuffles: 25,
      num_decks_in_shoe:   1
    }

    def initialize(options={})
      @options = DEFAULT_OPTIONS.merge(options)
      @decks = Deck.new(@options[:num_decks_in_shoe])
      @discard_pile = Cards.new(decks)
      shuffle
    end

    def new_hand
      Cards.new(discard_pile)
    end

    def place_cut_card(cut_offset=nil)
      @cutoff = cut_offset||random_cut_offset
      raise "invalid cut card placement" if cutoff <=0 || cutoff >= (decks.length-1)
      self
    end

    def needs_shuffle?
      @force_shuffle || beyond_cut?
    end

    def deal_one_up(destination)
      deal_one(destination, Card::FACE_UP)
    end

    def deal_one_down(destination)
      deal_one(destination, Card::FACE_DOWN)
    end

    def remaining
      #
      # number of cards remaining in shoe, included beyond cut_card
      #
      decks.length
    end

    def discarded
      #
      # number of cards in the discard pile
      #
      discard_pile.length
    end

    def shuffle
      discard_pile.fold
      remove_cut_card
      decks.shuffle_up(options[:split_and_shuffles])
      num_shuffles.incr
      @force_shuffle = false
      self
    end

    def force_shuffle
      @force_shuffle = true
      self
    end

    def inspect
      self.class.name
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
      raise "needs cut card placed" if @cutoff.nil?
      raise "needs shuffle" if needs_shuffle?
      decks.deal(destination, 1, orientation)
      destination.sum_hand
      cards_dealt.incr
      self
    end
  end

  class OneDeckShoe < Shoe
    def initialize(options={})
      super(options.merge(num_decks_in_shoe: 1))
    end
  end

  class TwoDeckShoe < Shoe
    def initialize(options={})
      super(options.merge(num_decks_in_shoe: 2))
    end
  end

  class FourDeckShoe < Shoe
    def initialize(options={})
      super(options.merge(num_decks_in_shoe: 4))
    end
  end

  class SixDeckShoe < Shoe
    def initialize(options={})
      super(options.merge(num_decks_in_shoe: 6))
    end
  end

  class EightDeckShoe < Shoe
    def initialize(options={})
      super(options.merge(num_decks_in_shoe: 8))
    end
  end
end
