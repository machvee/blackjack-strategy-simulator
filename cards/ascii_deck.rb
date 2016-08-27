require 'ascii_card'
require 'deck'

module Cards
  class AsciiDeck < Deck
    def get_deck_cards(options)
      AsciiCard.deck(options)
    end
  end
end
