module Cards
  class Collection
    #
    # ========================================
    #           C O L L E C T I O N 
    # ========================================
    #
    # A collection of Card class objects. 
    # Base class for classes like Hand, Deck and Shoe
    #
    include Enumerable

    attr_reader :cards
    attr_reader :parent
    attr_reader :options

    attr_reader :value  # used by subclasses to hold 'value' of collection

    DEFAULTS = {
      shuffles: 1,
      prng:     Random.new
    }

    def initialize(card_array=[], parent=nil, options={})
      @cards = []
      @parent = parent
      @value = nil
      @options = DEFAULTS.merge(options)
      add(card_array)
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

    def set(*cards)
      @cards.clear
      add(cards)
    end

    def insert(offset, card)
      @cards.insert(offset, card)
      update_value
      self
    end

    def update_value
      #
      # override in subclass if desired to set @value
      #
      self
    end

    def shuffle
      @cards.shuffle!(random: prng)
      self
    end

    def shuffle_up(num_times=default_shuffles)
      num_times.times {shuffle; split}
      self
    end

    def facing(direction=FACE_DOWN)
      @cards.each {|c| c.facing(direction)}
      self
    end

    def up
      facing(FACE_UP)
    end

    def down
      facing(FACE_DOWN)
    end

    def split
      #
      # pick a random spot in the middle third of the cards array
      # and divide and rejoin bottom to top
      #
      third = (length/3.0).floor
      split_at = third + prng.rand(third+1)
      @cards = @cards.slice(split_at..-1) + @cards.slice(0,split_at)
      self
    end

    def deal(destination, num_cards, direction=FACE_DOWN)
      destination.add(remove(num_cards, direction))
    end

    def deal_at(destination, offsets, direction=FACE_DOWN)
      offsets.each {|off| destination.insert(off, remove(1, direction).first)}
    end

    def deal_cards(how_many=1, direction=FACE_DOWN)
      #
      # create a new Collection object using how_many from this set
      #
      self.class.new(remove(how_many, direction))
    end

    def fold(direction=FACE_DOWN)
      raise "there is no parent collection" if parent.nil?
      #
      # return @cards to the parent
      #
      deal(parent, length, direction)
      self
    end

    def discard(offsets)
      #
      # remove the cards from this set at the offsets provided
      #
      removed=[]
      offsets.sort.each_with_index do |off,i|
        removed << @cards.delete_at(off-i)
      end
      parent.add(removed) if parent.present?
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

    def print(options={})
      @cards.first.card_printer.print(@cards, options) unless @cards.empty?
    end

    private

    def prng
      options[:prng]
    end

    def default_shuffles
      options[:shuffles]
    end

  end

end
