require 'blackjack_card'
require 'counter_measures'

module Blackjack
  class Shoe
    include CounterMeasures

    attr_reader  :decks
    attr_reader  :markeroff
    attr_reader  :config
    attr_reader  :discard_pile

    counters  :num_shuffles, :cards_dealt

    DEFAULT_OPTIONS = {
      marker_card_segment: 0.25, # marker_offset must be in this last % of the deck
      marker_card_offset:  0.05,
      split_and_shuffles:  25,
      num_decks_in_shoe:   1,
      random:              Random.new
    }

    def initialize(options={})
      @config = DEFAULT_OPTIONS.merge(options)
      @prng = config[:random]
      @decks = BlackjackDeck.new(config[:num_decks_in_shoe], @prng)
      @discard_pile = Cards::Cards.new(decks)
      shuffle
    end

    def new_hand(hand_class=BlackjackHand)
      #
      # returns an empty BlackjackHand that will naturally discard
      # to the discard pile when folded
      #
      hand_class.new(discard_pile)
    end

    def place_marker_card(marker_offset=nil)
      #
      # marker_offset is the number of cards from the *back of the deck to place
      # the marker card.  A specific marker_offset must be valid.
      #
      @markeroff = marker_offset||random_marker_offset
      raise "invalid marker card placement [#{marker_card_placement_range}]" unless valid_marker_offset?(markeroff)
      markeroff
    end

    def needs_shuffle?
      @force_shuffle || beyond_marker?
    end

    def deal_one_up(destination)
      deal_one(destination, BlackjackCard::FACE_UP)
    end

    def deal_one_down(destination)
      deal_one(destination, BlackjackCard::FACE_DOWN)
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
      #
      remaining - (markeroff.nil? ? 0 : markeroff)
    end

    def discarded
      #
      # number of cards in the discard pile
      #
      discard_pile.length
    end

    def shuffle
      discard_pile.fold # brings discards back in to decks
      remove_marker_card
      decks.shuffle_up(config[:split_and_shuffles])
      num_shuffles.incr
      @force_shuffle = false
      self
    end

    def counts
      decks.counts(markeroff)
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
      self.class.name
    end

    private

    def valid_marker_offset?(marker_offset)
      marker_card_placement_range.include?(marker_offset)
    end

    def remove_marker_card
      @markeroff = nil
    end

    def beyond_marker?
      #
      # if the marker was never placed, the marker is the
      # end of the deck
      #
      markeroff && (decks.count < markeroff)
    end

    def marker_card_placement_range
      #
      # return an offset that is equal to the number of cards behind the
      # marker card
      #                +0.05   -0.05
      #    +---------------------------+
      #    |             |  25%  |     |
      #    +-----------------+---------+
      #                markeroff range
      #
      @_mcp_range ||= (
        #
        # e.g.
        #   2 Decks shoe
        #   num_cards = 104
        #   marker_off_cetner = (104 * 0.25).floor = 26
        #   offset = (104 * 0.05).floor = 5
        #   (26-5)..(26+5)
        #
        #   21..31 is the valid marker_card_placement_range
        #
        num_cards = decks.length
        marker_off_center = (num_cards * config[:marker_card_segment]).floor
        offset = (num_cards * config[:marker_card_offset]).floor
        (marker_off_center - offset)..(marker_off_center + offset)
      )
    end

    def random_marker_offset
      @prng.rand(marker_card_placement_range)
    end

    def deal_one(destination, orientation)
      raise "needs marker card placed" if @markeroff.nil?
      decks.deal(destination, 1, orientation)
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

  class ContinuousShuffleShoe < FourDeckShoe
    def needs_shuffle?
      #
      # this basically reshuffles the deck after each round
      # is played
      #
      shuffle
      place_marker_card
      false
    end
  end
end
