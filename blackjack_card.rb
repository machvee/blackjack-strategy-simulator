require 'cards/ascii_deck'

module Blackjack
  class BlackjackCard < Cards::AsciiCard

    ACE_SOFT_VALUE=1
    ACE_HARD_VALUE=11
    SOFT_DIFFERENCE=(ACE_HARD_VALUE-ACE_SOFT_VALUE)

    def face_value
      soft_value
    end

    def soft_value
      BlackjackCard.custom_value_of_face(face)
    end

    def hard_value
      case face
        when Cards::ACE
          ACE_HARD_VALUE
        else
          face_value
      end
    end

    def self.custom_value_of_face(card_face)
      case card_face
        when Cards::ACE
          ACE_SOFT_VALUE
        when *Cards::FACE_CARDS
          BlackjackCard.face_to_value(Cards::TEN)
        else
          BlackjackCard.face_to_value(card_face)
      end
    end

    def ten?
      BlackjackCard.custom_value_of_face(face) == 10
    end
  end


  class BlackjackHand < Cards::Collection
    #
    # custom Cards subclass has builtin knowledge of blackjack
    # hands sums
    #
    TWENTYONE = 21

    attr_reader  :soft_sum
    attr_reader  :hard_sum

    def update_value
      @value = calc_hard_soft_sums
      @soft_sum = value.first
      @hard_sum = value.last
      self
    end

    def blackjack?
      length == 2 && hard_sum == TWENTYONE
    end

    def twentyone?
      hard_sum == TWENTYONE
    end

    def bust?
      soft_sum > TWENTYONE 
    end

    def hittable?
      #
      # in most casinos, the dealer must no longer allow a hit
      # when the player has a soft 21
      #
      soft_sum < TWENTYONE 
    end

    def pair?
      return false unless length == 2 
      return false if cards[0].ten? && cards[0].face != cards[1].face
      cards[0].hard_value == cards[1].hard_value
    end

    def soft?
      has_ace?
    end

    def has_ace?
      any? {|c| c.ace?}
    end

    private 

    def num_aces
      count {|c| c.ace?}
    end

    def sum
      inject(0) {|t, c| t += c.soft_value}
    end

    def sum_non_aces
      inject(0) {|t, c| t += c.ace? ? 0 : c.hard_value}
    end

    def calc_hard_soft_sums
      na = num_aces 
      if na == 0
        s = sum
        return [s,s]
      end

      sna = sum_non_aces

      soft = sna + na
      hard = sna + na + BlackjackCard::SOFT_DIFFERENCE

      [soft, hard > TWENTYONE ? soft : hard]
    end
  end

  class DealerHand < BlackjackHand
    def up_card
      cards[0]
    end

    def hole_card
      cards[1]
    end

    def peek
      hole_card.face_value
    end

    def flip
      hole_card.up if hole_card.face_down?
    end

    def flipped?
      hole_card.face_up?
    end
  end

  class BlackjackDeck < Cards::AsciiDeck
    attr_reader  :markeroff
    attr_reader  :marker_placement_segment
    attr_reader  :marker_placement_offset

    def initialize(options={})
      @marker_placement_segment = options[:marker_card_segment]
      @marker_placement_offset = options[:marker_card_offset]
      super(options)
      remove_marker_card
    end

    def get_deck_cards(options)
      BlackjackCard.deck(options[:orientation])
    end

    def deal(destination, num_cards, orientation)
      raise "needs marker card placed" if markeroff.nil?
      super
    end

    def place_marker_card(marker_offset=nil)
      #
      # marker_offset is the number of cards from the *back of the deck to place
      # the marker card.  A specific marker_offset must be valid.
      #
      @markeroff = marker_offset||random_marker_offset
      raise "invalid marker card placement [#{marker_card_placement_range}]" unless valid_marker_offset?
      markeroff
    end

    def counts
      #
      # return {face_val: count_in_deck, ..., face_val: count_in_deck} up until the markeroff is reached, if non-nil
      #
      freq = Hash[Cards::FACES.map{|f| BlackjackCard.custom_value_of_face(f)}.uniq.zip([0]*Cards::FACES.length)]
      stop_at = markeroff.nil? ? length : length - markeroff
      each_with_index do |c,i|
        break if stop_at == i
        freq[c.face_value] += 1
      end
      freq
    end

    def valid_marker_offset?
      marker_card_placement_range.include?(markeroff)
    end

    def beyond_marker?
      #
      # if the marker was never placed, the marker is the
      # end of the deck
      #
      markeroff && (count < markeroff)
    end

    def remaining_until_shuffle
      [0, count - (markeroff.nil? ? 0 : markeroff)].max
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
        num_cards = count
        marker_off_center = (num_cards * marker_placement_segment).floor
        offset = (num_cards * marker_placement_offset).floor
        (marker_off_center - offset)..(marker_off_center + offset)
      )
    end

    def random_marker_offset
      prng.rand(marker_card_placement_range)
    end

    def remove_marker_card
      @markeroff = nil
    end

    def inspect
      markeroff.nil? ? super : inspect_with_marker
    end

    def inspect_with_marker
      off = count - markeroff
      self[0..off] + ["||"] + self[(off+1)..-1]
    end
  end
end
