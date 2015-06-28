require 'cards'

module Blackjack
  class Cards::Card

    ACE_SOFT_VALUE=1
    ACE_HARD_VALUE=11

    def face_value
      case face
        when ACE
          ACE_SOFT_VALUE
        when *FACE_CARDS
          value_from_FACES('10')
        else
          value_from_FACES(face)
      end
    end

    def soft_value
      face_value
    end

    def hard_value
      case face
        when ACE
          ACE_HARD_VALUE
        else
          face_value
      end
    end

    private

    def value_from_FACES(card_face)
      FACES.index(card_face) + 2
    end
  end
end
