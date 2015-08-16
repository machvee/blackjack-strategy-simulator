require 'blackjack_card'
require 'counter_measures'

module Blackjack
  class Shoe

    include CounterMeasures

    attr_reader  :decks
    attr_reader  :cutoff
    attr_reader  :config
    attr_reader  :discard_pile

    counters  :num_shuffles, :cards_dealt

    DEFAULT_OPTIONS = {
      cut_card_segment: 0.25, # cut_offset must be in this last % of the deck
      cut_card_offset:  0.05,
      split_and_shuffles: 25,
      num_decks_in_shoe:   1
    }

    def initialize(options={})
      @config = DEFAULT_OPTIONS.merge(options)
      @decks = BlackjackDeck.new(config[:num_decks_in_shoe])
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

    def place_cut_card(cut_offset=nil)
      #
      # cut_offset is the number of cards from the *back of the deck to place
      # the cut card.  A specific cut_offset must be valid.
      #
      @cutoff = cut_offset||random_cut_offset
      raise "invalid cut card placement [#{cut_card_placement_range}]" unless valid_cut_offset?(cutoff)
      cutoff
    end

    def needs_shuffle?
      @force_shuffle || beyond_cut?
    end

    def deal_one_up(destination)
      deal_one(destination, BlackjackCard::FACE_UP)
    end

    def deal_one_down(destination)
      deal_one(destination, BlackjackCard::FACE_DOWN)
    end

    def remaining
      #
      # total number of cards remaining in shoe even beyond the cut card
      #
      decks.length
    end

    def remaining_until_shuffle
      #
      # number of cards remaining in shoe until the cut card is reached
      #
      remaining - cutoff
    end

    def discarded
      #
      # number of cards in the discard pile
      #
      discard_pile.length
    end

    def shuffle
      discard_pile.fold # brings discards back in to decks
      remove_cut_card
      decks.shuffle_up(config[:split_and_shuffles])
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

    def valid_cut_offset?(cut_offset)
      cut_card_placement_range.include?(cut_offset)
    end

    def remove_cut_card
      @cutoff = nil
    end

    def beyond_cut?
      cutoff && decks.count < cutoff
    end

    def cut_card_placement_range
      #
      # return an offset that is equal to the number of cards behind the
      # cut card
      #                +0.05   -0.05
      #    +---------------------------+
      #    |             |  25%  |     |
      #    +-----------------+---------+
      #                cutoff range
      #
      @_ccp_range ||= (
        #
        # e.g.
        #   2 Decks shoe
        #   num_cards = 104
        #   cut_off_cetner = (104 * 0.25).floor = 26
        #   offset = (104 * 0.05).floor = 5
        #   (26-5)..(26+5)
        #
        #   21..31 is the valid cut_card_placement_range
        #
        num_cards = decks.length
        cut_off_center = (num_cards * config[:cut_card_segment]).floor
        offset = (num_cards * config[:cut_card_offset]).floor
        (cut_off_center - offset)..(cut_off_center + offset)
      )
    end

    def random_cut_offset
      rand(cut_card_placement_range)
    end

    def deal_one(destination, orientation)
      raise "needs cut card placed" if @cutoff.nil?
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
end
