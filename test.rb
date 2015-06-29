require 'minitest/autorun'
require 'blackjack_card'

describe Cards::Card, "A Card" do 
  before do
    @a_card = Cards::Card.new('A', 'S')
  end

  it "should have validate inputs" do
    proc { Cards::Card.new('-', '*')}.must_raise RuntimeError
    proc { Cards::Card.new('*', '-')}.must_raise RuntimeError
  end

  it "should have a default direction facing down" do
    @a_card.face_down?.must_equal true
    @a_card.face_up?.must_equal false
  end

  it "should allow the direction to be set up" do
    @a_card.face_up?.must_equal false
    @a_card.up
    @a_card.face_up?.must_equal true
  end

  it "should allow the direction to be set down" do
    @a_card.up
    @a_card.face_up?.must_equal true
    @a_card.down
    @a_card.face_up?.must_equal false
    @a_card.face_down?.must_equal true
  end

end

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

  it "should have soft value of 1 for 'A'" do 
    @ace_spades.face_value.must_equal 1
  end

  it "should have default face value of the soft value for 'A'" do 
    @ace_spades.face_value.must_equal @ace_spades.soft_value
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
  end

  it "should not be an ace" do
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

  it "should respond to being a face_card?" do
    @jack_clubs.face_card?.must_equal true
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

describe Cards::Cards, "A Hand of 8 8" do
  before do
    @eight_eight = Cards::Cards.make('8D', '8S')
  end

  it "should respond to pair" do
    @eight_eight.pair?.must_equal true
  end

  it "should have a value of 16" do
    @eight_eight.soft_sum.must_equal 16
  end

  it "should should not be busted" do
    @eight_eight.bust?.must_equal false
  end
end

describe Cards::Cards, "A Hand of 8 9" do
  before do
    @eight_nine = Cards::Cards.make('8D', '9S')
  end

  it "should not respond to pair" do
    @eight_nine.pair?.must_equal false
  end

  it "should have a value of 17" do
    @eight_nine.soft_sum.must_equal 17
  end

  it "should should not be busted" do
    @eight_nine.bust?.must_equal false
  end
end

describe Cards::Cards, "A Hand of J Q" do
  before do
    @jack_q = Cards::Cards.make('JD', 'QS')
  end

  it "should respond to pair" do
    @jack_q.pair?.must_equal true
  end

  it "should have a value of 20" do
    @jack_q.soft_sum.must_equal 20
    @jack_q.hard_sum.must_equal 20
  end

  it "should should not be busted" do
    @jack_q.bust?.must_equal false
  end
end

describe Cards::Cards, "A Hand of K 10" do
  before do
    @k_10 = Cards::Cards.make('KD', '10S')
  end

  it "should respond to pair" do
    @k_10.pair?.must_equal true
  end

  it "should have a value of 20" do
    @k_10.soft_sum.must_equal 20
    @k_10.hard_sum.must_equal 20
  end

  it "should should not be busted" do
    @k_10.bust?.must_equal false
  end

  it "should not be blackjack?" do
    @k_10.blackjack?.must_equal false
  end
end

describe Cards::Cards, "A Hand of A Q" do
  before do
    @blackjack = Cards::Cards.make('AD', 'QS')
  end

  it "should not respond to pair" do
    @blackjack.pair?.must_equal false
  end

  it "should have a hard value of 21" do
    @blackjack.hard_sum.must_equal 21
  end

  it "should have a soft value of 11" do
    @blackjack.soft_sum.must_equal 11
  end

  it "should should not be busted" do
    @blackjack.bust?.must_equal false
  end

  it "should be blackjack?" do
    @blackjack.blackjack?.must_equal true
  end
end

