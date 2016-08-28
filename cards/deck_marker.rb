module Cards
  class DeckMarker
    attr_reader  :deck
    attr_reader  :offset
    attr_reader  :placement_segment
    attr_reader  :placement_offset

    DEFAULTS = {
      marker_card_segment: 0.25, # marker_offset must be in this last % of the deck
      marker_card_offset:  0.05
    }

    def initialize(deck, options={})
      options = DEFAULTS.merge(options)
      @deck = deck
      @placement_segment = options[:marker_card_segment]
      @placement_offset = options[:marker_card_offset]
      remove_card
    end

    def check
      raise "needs marker card placed" unless marker_placed?
    end

    def marker_placed?
      !offset.nil?
    end

    def place_card(offset=nil)
      #
      # offset is the number of cards from the *back of the deck to place
      # the card.  A specific offset must be valid.
      #
      @offset = offset||random_offset
      raise "invalid marker card placement [#{card_placement_range}]" unless valid_offset?
      offset
    end

    def valid_offset?
      card_placement_range.include?(offset)
    end

    def remaining_until_shuffle
      [0, deck.count - (marker_placed? ? offset : 0)].max
    end

    def beyond_marker?
      #
      # if the marker was never placed, the marker is the
      # end of the deck
      #
      offset && (deck.count < offset)
    end

    def card_placement_range
      #
      # return an offset that is equal to the number of cards behind the
      # marker card
      #                +0.05   -0.05
      #    +---------------------------+
      #    |             |  25%  |     |
      #    +-----------------+---------+
      #                offset range
      #
      @_mcp_range ||= (
        #
        # e.g.
        #   2 Decks shoe
        #   num_cards = 104
        #   off_cetner = (104 * 0.25).floor = 26
        #   offset = (104 * 0.05).floor = 5
        #   (26-5)..(26+5)
        #
        #   21..31 is the valid card_placement_range
        #
        num_cards = deck.count
        off_center = (num_cards * placement_segment).floor
        offset = (num_cards * placement_offset).floor
        (off_center - offset)..(off_center + offset)
      )
    end

    def random_offset
      deck.prng.rand(card_placement_range)
    end

    def remove_card
      @offset = nil
    end

    def inspect
      if marker_placed?
        off = deck.count - offset
        deck[0..off] + ["||"] + deck[(off+1)..-1]
      else
        "card removed"
      end
    end

  end
end
