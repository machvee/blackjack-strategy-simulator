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
    FACES=[TWO, THREE, FOUR,
           FIVE, SIX, SEVEN,
           EIGHT, NINE, TEN,
           JACK, QUEEN, KING,
           ACE]
    FACE_CARDS=[JACK, QUEEN, KING]

    attr_reader   :face
    attr_reader   :suit

    FACE_DOWN=false
    FACE_UP=true

    attr_reader :faces  # FACE_UP, FACE_DOWN

    def initialize(face, suit, direction=FACE_DOWN)
      valid?(suit, face)
      @face = face
      @suit = suit
      @faces = direction
    end

    def face_value
      @_fv ||= self.class.face_to_value(face)
    end

    def suit_value
      @_sv ||= SUITS.index(suit)
    end

    def facing(direction)
      #
      # change a cards orientation to FACE_UP or FACE_DOWN (direction)
      @faces = direction
    end

    def to_s
      face + suit
    end

    def inspect
      to_s
    end

    def up
      facing(FACE_UP)
      self
    end

    def down
      facing(FACE_DOWN)
      self
    end

    def face_up?
      faces == FACE_UP
    end

    def face_down?
      faces == FACE_DOWN
    end

    def ace?
      face == ACE
    end

    def face_card?
      FACES.include?(face)
    end

    def print_row(n)
      case n
        when 0
          CARD_TOP
        when 1,4
          face_up? ? SUIT_PATTERNS[suit][n-1] % face : "| x   x |"
        when 2,3
          face_up? ? SUIT_PATTERNS[suit][n-1] : "|   x   |"
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
      cmp = suit_value <=> anOther.suit_value
      cmp.zero? ? face_value <=> anOther.face_value : cmp
    end

    def ==(anOther)
      suit_value == anOther.suit_value &&
      face_value == anOther.face_value 
    end

    def self.all(direction=FACE_DOWN)
      a = []
      SUITS.each do |s|
        FACES.each do |f|
          a << new(f, s, direction)
        end
      end
      a
    end

    def self.from_face_suit(fs, direction=Card::FACE_UP)
      face = fs[0..-2]
      suit = fs[-1]
      new(face, suit, direction)
    end

    def self.make(*face_suits)
      #
      # builds an array of Cards from the args
      #
      # usage: Card.make("AC", "JD", "4D", "JS")
      #
      face_suits.inject([]) do |h, fs|
        h << from_face_suit(fs)
      end
    end

    def self.face_to_value(face)
      FACES.index(face) + 2
    end

    private

    def valid?(suit, face)
      raise "#{suit} is not a valid suit (use one of #{SUITS})" unless SUITS.include?(suit)
      raise "#{face} is not a valid face (use one of #{FACES})" unless FACES.include?(face)
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
    attr_reader :card_class
    attr_reader :value # used by subclasses to hold hand value

    def initialize(card_source, card_array=[], card_class=Card)
      @card_source = card_source
      @cards = []
      @card_class = card_class
      @value = nil
      add(card_array)
    end

    def insert(offset, card)
      @cards.insert(offset, card)
      update_value
      self
    end

    def add(cards)
      @cards += cards.flatten
      update_value
      self
    end

    def remove(how_many, direction)
      raise "too few cards remaining" if how_many > length
      removed_cards = @cards.slice!(0, how_many).each {|c| c.facing(direction)}
      update_value
      removed_cards
    end

    def update_value
      #
      # override in subclass if desired to set @value
      #
      self
    end

    def set(*face_suits)
      cards_to_add = card_class.make(*face_suits)
      @cards = []
      add(cards_to_add)
      self
    end

    def self.make(*face_suits)
      h = new(nil)
      h.set(*face_suits)
      h
    end

    def shuffle
      @cards.shuffle!
      self
    end

    def shuffle_up(num_times=1)
      num_times.times {shuffle; split}
      self
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
      self.class.new(remove(how_many, direction))
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

    def order
      @cards.sort!
    end

    def face_sort
      @cards.sort {|a,b| FACES.index(a.face) <=> FACES.index(b.face)}
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
    def initialize(num_decks=1, direction=Card::FACE_DOWN, card_class=Card)
      cards = []
      num_decks.times {cards += card_class.all(direction)}
      super(nil, cards, card_class)
    end
  end
end
