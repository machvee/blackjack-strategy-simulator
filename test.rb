require 'minitest/autorun'
require 'blackjack_card'

describe Cards::Card, "A single Blackjack Ace Card" do 
  before do
    @ace_spades = Cards::Card.new('A', 'S')
  end

  it "should have 'A' as its value" do
    @ace_spades.face.must_equal 'A'
    @ace_spades.ace?.must_equal true
  end

  it "should have 'S' as its suit" do
    @ace_spades.suit.must_equal 'S'
  end

  it "should have a default direction facing down" do
    @ace_spades.face_down?.must_equal true
    @ace_spades.face_up?.must_equal false
  end

  it "should have soft value of 1 for 'A'" do 
    @ace_spades.face_value.must_equal 1
    @ace_spades.soft_value.must_equal 1
  end

  it "should have hard value of 11 for 'A'" do 
    @ace_spades.hard_value.must_equal 11
  end
end

describe Cards::Card, "A single Blackjack Face Card" do 
  before do
    @jack_clubs = Cards::Card.new('J', 'C')
  end

  it "should have 'J' as its value" do
    @jack_clubs.face.must_equal 'J'
    @jack_clubs.ace?.must_equal false
  end

  it "should have 'C' as its suit" do
    @jack_clubs.suit.must_equal 'C'
  end

  it "should have 10 for its hard and soft values" do
    @jack_clubs.face_value.must_equal 10
    @jack_clubs.soft_value.must_equal 10
    @jack_clubs.hard_value.must_equal 10
  end

end


describe Cards::Card, "A deck of Blackjack Cards" do 

  before do
    @deck = Cards::Card.all
  end

  it "must have 52 cards" do
    @deck.length.must_equal 52
  end

  it "must have all four suits" do
    @deck.map(&:suit).uniq.length.must_equal 4
    @deck.map(&:suit).uniq.sort.must_equal ['C', 'D', 'H', 'S']
  end

  it "must have all 13 cards in each suit" do
    @deck.group_by(&:suit).each_pair do |s, faces|
      faces.map(&:face).must_equal [*'2'..'9', '10', 'J', 'Q', 'K', 'A']
    end
  end

end
