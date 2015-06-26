require 'cards'

module Blackjack
  class HandEvaluator
    include Cards

    ACE_HIGH = 11
    ACE_LOW =  1
    TEN = Card::TEN.to_i
    TWENTYONE = (TEN+ACE_HIGH)

    attr_reader  :hand

    def initialize(hand)
      @hand = hand.order
    end

    def is_blackjack?
      hand.count == 2 && high_val == TWENTYONE
    end

    def has_ace?
      ace_count > 0
    end

    def soft?
      has_ace?
    end

    def splitable?
      hand.count == 2 && (face_val(hand[0]) == face_val(hand[1]))
    end

    def high_val
      #
      # Only one Card::ACE counts as ACE_HIGH, the rest as ACE_LOW
      #
      first_ace = true
      hand.inject(0) do |t, c|
        t += if c.face == Card::ACE && first_ace
          first_ace = false
          high_face_val(c)
        else
          low_face_val(c)
        end
      end
    end

    def low_val
      hand.inject(0) {|t, c| t += low_face_val(c)}
    end

    private

    def ace_count
      @_acnt ||= hand.count {|c| c.face == Card::ACE}
    end

    def high_face_val(c)
      face_val(c, ACE_HIGH)
    end

    def low_face_val(c)
      face_val(c, ACE_LOW)
    end

    def face_val(c, ace_val=ACE_LOW)
      case c.face
        when Card::ACE
          ace_val
        when Card::TEN, Card::JACK, Card::QUEEN, Card::KING
          TEN
        else # '2' - '9'
          c.face.to_i
      end
    end
  end
end
