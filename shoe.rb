require 'blackjack_card'
require 'counter_measures'

module Blackjack
  class Shoe
    include CounterMeasures

    attr_reader  :num_decks
    attr_reader  :decks
    attr_reader  :config
    attr_reader  :discard_pile

    counters  :num_shuffles, :cards_dealt
    measures  :hands_dealt

    DEFAULT_OPTIONS = {
      split_and_shuffles:  25,
      num_decks:           1,
      prng:                Random.new
    }

    def initialize(options={})
      @config = DEFAULT_OPTIONS.merge(options)
      @num_decks = config[:num_decks]
      @decks = BlackjackDeck.new(config)
      @discard_pile = Cards::Collection.new([], decks)
      shuffle
    end

    def new_player_hand
      #
      # returns an empty BlackjackHand that will naturally discard
      # to the discard pile when folded
      #
      BlackjackHand.new([], discard_pile)
    end

    def new_dealer_hand
      DealerHand.new([], discard_pile)
    end

    def place_marker_card(marker_offset=nil)
      decks.marker.place_card(marker_offset) 
    end

    def needs_shuffle?
      @force_shuffle || decks.marker.beyond_marker?
    end

    def deal_one_up(destination)
      deal_one(destination, Cards::FACE_UP)
    end

    def deal_one_down(destination)
      deal_one(destination, Cards::FACE_DOWN)
    end

    def remaining
      #
      # total number of cards remaining in shoe even beyond the marker card
      #
      decks.length
    end

    def remaining_until_shuffle
      #
      # number of cards remaining in shoe until the marker card is reached
      # or 0 if beyond marker
      #
      decks.marker.remaining_until_shuffle
    end

    def discarded
      #
      # number of cards in the discard pile
      #
      discard_pile.length
    end

    def shuffle
      hands_dealt.commit
      discard_pile.fold
      decks.marker.remove_card
      decks.shuffle_up(config[:split_and_shuffles])
      num_shuffles.incr
      @force_shuffle = false
      self
    end

    def counts
      decks.counts
    end

    def current_ten_percentage
      tens_remaining = counts[10]
      r = remaining_until_shuffle
      r == 0 ? 0.0 : (100.0 * (tens_remaining * 1.0)/r)
    end

    def force_shuffle
      @force_shuffle = true
      self
    end

    def inspect
      decks.inspect
    end

    private

    def deal_one(destination, orientation)
      decks.deal(destination, 1, orientation)
      cards_dealt.incr
      self
    end
  end

  class OneDeckShoe < Shoe
    def initialize(options={})
      super(options.merge(num_decks: 1))
    end
  end

  class TwoDeckShoe < Shoe
    def initialize(options={})
      super(options.merge(num_decks: 2))
    end
  end

  class FourDeckShoe < Shoe
    def initialize(options={})
      super(options.merge(num_decks: 4))
    end
  end

  class SixDeckShoe < Shoe
    def initialize(options={})
      super(options.merge(num_decks: 6))
    end
  end

  class EightDeckShoe < Shoe
    def initialize(options={})
      super(options.merge(num_decks: 8))
    end
  end

  class ContinuousShuffleShoe < FourDeckShoe
    def needs_shuffle?
      #
      # this basically reshuffles the deck after each round
      # is played
      #
      shuffle
      decks.marker.place_card
      false
    end
  end
end
