module Cards
  CLUBS='C'
  HEARTS='H'
  DIAMONDS='D'
  SPADES='S'

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
  FACES=[
    TWO, THREE, FOUR, FIVE, SIX, SEVEN,
    EIGHT, NINE, TEN, JACK, QUEEN, KING, ACE
  ]
  FACE_CARDS=[JACK, QUEEN, KING]
  FACE_DOWN=false
  FACE_UP=true

  class Card
    #
    # ========================================
    #                C A R D
    # ========================================
    #
    include Comparable

    attr_reader   :face
    attr_reader   :suit
    attr_reader   :card_printer


    attr_reader :faces  # FACE_UP, FACE_DOWN

    def initialize(face, suit, orientation=FACE_DOWN)
      valid?(suit, face)
      @face = face
      @suit = suit
      @faces = orientation
      @card_printer = SimpleCardPrinter.new
    end

    def self.deck(orientation=FACE_DOWN)
      #
      # a standard 52 card array of this card class
      #
      [].tap do |a|
        SUITS.each do |s|
          FACES.each do |f|
            a << new(f, s, orientation)
          end
        end
      end
    end

    def self.make(*card_strings)
      #
      # an array of Cards from the card_string args
      #
      # usage: Card.make("AC", "JD", "4D", "JS")
      #
      card_strings.map {|card_string| from_s(card_string)}
    end

    def face_value
      @_fv ||= self.class.face_to_value(face)
    end

    def suit_value
      @_sv ||= SUITS.index(suit)
    end

    def facing(orientation)
      #
      # change a cards orientation to FACE_UP or FACE_DOWN (orientation)
      @faces = orientation
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

    def print(options={})
      card_printer.print(self, options)
    end

    def <=>(anOther)
      cmp = suit_value <=> anOther.suit_value
      cmp.zero? ? face_value <=> anOther.face_value : cmp
    end

    def ==(anOther)
      suit_value == anOther.suit_value &&
      face_value == anOther.face_value 
    end

    def self.from_s(card_string, orientation=FACE_UP)
      # "AC" => Card.new
      face = card_string[0..-2]
      suit = card_string[-1]
      new(face, suit, orientation)
    end

    def self.face_to_value(face)
      FACES.index(face) + 2
    end

    def to_s
      face_up? ? face + suit : 'XX'
    end

    def inspect
      to_s
    end

    private

    def valid?(suit, face)
      raise "#{suit} is not a valid suit (use one of #{SUITS})" unless SUITS.include?(suit)
      raise "#{face} is not a valid face (use one of #{FACES})" unless FACES.include?(face)
    end
  end

  class SimpleCardPrinter
    #
    # prints an array of cards
    #
    def print(cards, options)
      #
      # override in subclass
      #
      value = options.fetch(:value) {nil}
      puts [*cards].map {|c| "#{c}"}.join(" ") + (value.nil? ? "" : " #{value}")
    end
  end

end
