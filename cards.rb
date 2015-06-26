module Cards
  class Card
    #
    # ========================================
    #                C A R D
    # ========================================
    #
    include Comparable

    CLUBS='C'
    HEARTS='H'
    DIAMONDS='D'
    SPADES='S'

    CARD_TOP    = ".-------." # 0

    SUIT_PATTERNS = {
      HEARTS => [
        "|%2s_  _ |", # 1
        '| ( \/ )|',  # 2
        '|  \  / |',  # 3
        "|   \\/%2s|"  # 4
      ],
      DIAMONDS => [
        "|%2s /\\  |",
        '|  /  \ |',
        '|  \  / |',
        "|   \\/%2s|"
      ],
      CLUBS => [
        "|%2s _   |",
        "|  ( )  |",
        "| (_x_) |",
        "|   Y %2s|"
      ],
      SPADES => [
        "|%2s .   |",
        '|  / \  |',
        "| (_,_) |",
        "|   I %2s|"
      ]
    }

    CARD_BOTTOM = "`-------'" # 5

    NUM_PRINT_ROWS=6

    ACE   = 'A'
    TWO   = '2'
    THREE = '3'
    FOUR  = '4'
    FIVE  = '5'
    SIX   = '6'
    SEVEN = '7'
    EIGHT = '8'
    NINE  = '9'
    TEN   = '10'
    JACK  = 'J'
    QUEEN = 'Q'
    KING  = 'K'

    SUITS=[CLUBS, HEARTS, DIAMONDS, SPADES]
    FACES=[TWO, THREE, FOUR, FIVE, SIX, SEVEN, EIGHT, NINE,
           TEN, JACK, QUEEN, KING, ACE]


    attr_reader   :face
    attr_reader   :suit

    FACE_DOWN=false
    FACE_UP=true
    attr_reader :facing  # FACE_UP, FACE_DOWN

    def initialize(face, suit, direction=FACE_DOWN)
      @face = face
      @suit = suit
      @facing = direction
    end

    def facing(direction)
      @facing = direction
    end

    def self.for(face_index, suit_index, direction=FACE_DOWN)
      Card.new(FACES[face_index-2], SUITS[suit_index], direction)
    end

    def to_s
      @face + @suit
    end

    def inspect
      to_s
    end

    def up
      @facing = FACE_UP
      self
    end

    def down
      @facing = FACE_DOWN
      self
    end

    def print_row(n)
      case n
        when 0
          CARD_TOP
        when 1,4
          @facing == FACE_UP ? SUIT_PATTERNS[@suit][n-1] % @face : "| x   x |"
        when 2,3
          @facing == FACE_UP ? SUIT_PATTERNS[@suit][n-1] : "|   x   |"
        when 5
          CARD_BOTTOM
      end
    end

    def print
      NUM_PRINT_ROWS.times do |i|
        puts print_row(i)
      end
      nil
    end

    def <=>(anOther)
      cmp = SUITS.index(@suit) <=> SUITS.index(anOther.suit)
      cmp.zero? ? FACES.index(@face) <=> FACES.index(anOther.face) : cmp
    end

    def self.all(direction=FACE_DOWN)
      a = []
      SUITS.each do |s|
        FACES.each do |f|
          a << Card.new(f, s, direction)
        end
      end
      a
    end
  end


  class Cards
    #
    # ========================================
    #                C A R D S
    # ========================================
    #
    include Enumerable

    DFLT_MAX_CARDS_PRINTED_PER_LINE=7

    attr_reader :cards
    attr_reader :card_source

    def initialize(card_source, cards=[])
      @card_source = card_source
      @cards = cards
    end

    def self.make(*cards)
      # usage Cards.make(*%w{JC AS 4H 3D 2D})
      h = []
      cards.each do |fs|
        f=fs[0..-2]
        s=fs[-1..-1]
        h << Card.new(f,s, Card::FACE_UP)
      end
      new(nil, h)
    end

    def shuffle
      @cards.shuffle!
    end

    def shuffle_up(num_times=1)
      num_times.times {shuffle; split}
    end

    def facing(direction=Card::FACE_DOWN)
      @cards.each {|c| c.facing(direction)}
      self
    end

    def up
      facing(Card::FACE_UP)
    end

    def down
      facing(Card::FACE_DOWN)
    end

    def split
      #
      # pick a random spot in the middle third of the cards array
      # and divide and rejoin bottom to top
      #
      third = (length/3.0).floor
      split_at = third + rand(third+1)
      @cards = @cards.slice(split_at..-1) + @cards.slice(0,split_at)
      self
    end

    def deal(destination, num_cards, direction=Card::FACE_DOWN)
      destination.add(remove(num_cards, direction))
    end

    def deal_at(destination, offsets, direction=Card::FACE_DOWN)
      offsets.each {|off| destination.insert(off, remove(1, direction).first)}
    end

    def deal_cards(how_many=1, direction=Card::FACE_DOWN)
      #
      # create a new Cards object using how_many from this set
      #
      Cards.new(self, remove(how_many, direction))
    end

    def fold(direction=Card::FACE_DOWN)
      #
      # return @cards to the @card_source
      #
      deal(@card_source, length, direction)
    end

    def discard(offsets)
      #
      # remove the cards from this set at the offsets provided
      #
      removed=[]
      offsets.sort.each_with_index do |off,i|
        removed << @cards.delete_at(off-i)
      end
      @card_source.add(removed)
    end

    def add(cards)
      @cards += cards
    end

    def remove(how_many, direction)
      raise "too few cards remaining" if how_many > length
      @cards.slice!(0, how_many).each {|c| c.facing(direction)}
    end

    def insert(offset, card)
      @cards.insert(offset, card)
    end

    def order
      @cards.sort!
    end

    def face_sort
      @cards.sort {|a,b| Card::FACES.index(a.face) <=> Card::FACES.index(b.face)}
    end

    def length
      @cards.length
    end

    def to_s
      inspect
    end

    def inspect
      @cards.inspect
    end

    def [](index)
      @cards[index]
    end

    def each
      @cards.each do |card|
        yield card
      end
    end

    def print(max_per_line=DFLT_MAX_CARDS_PRINTED_PER_LINE)
      sep = "  "
      @cards.each_slice(max_per_line) do |set|
        Card::NUM_PRINT_ROWS.times do |i|
          puts set.map {|card| card.print_row(i)}.join(sep)
        end
      end
      nil
    end
  end

  class Deck < Cards
    #
    # ========================================
    #               D E C K
    # ========================================
    #
    def initialize(num_decks=1, direction=Card::FACE_DOWN)
      cards = []
      num_decks.times {cards += Card.all(direction)}
      super(nil, cards)
    end

    def deal_hands(num_hands, how_many_cards, direction=Card::FACE_DOWN)
      #
      # create Hands from this deck, dealing one card out at a time to each Hand
      # (remember to call Cards#fold on each hand to return them to this Deck)
      #
      hands=[]
      num_hands.times {hands << deal_cards(1, direction)}
      (how_many_cards-1).times do
        hands.each do |hand|
          deal(hand, 1, direction)
        end
      end
      hands
    end
  end
end
