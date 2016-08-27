require 'card'
require 'collection'

module Cards
  class Deck < Collection
    DECK_DEFAULTS = {
      num_decks: 1,
      orientation: FACE_DOWN
    }

    def initialize(options={})
      options = DECK_DEFAULTS.merge(options)
      cards=[]
      options[:num_decks].times {cards += get_deck_cards(options)}
      super(cards, nil, options)
    end

    private

    def get_deck_cards(options)
      # override in subclass
      Card.deck(options[:orientation])
    end
  end
end
