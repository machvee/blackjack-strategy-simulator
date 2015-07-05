require 'minitest/autorun'

require 'table'

#################################################
#
#  C O U N T E R S
#
describe  Counters, "A counter DSL" do
  before do
    class Foo
      include Counters
      counters :a, :b, :c
    end
    @f = Foo.new
  end

  it "should allow named counter access" do
    assert @f.counter_value(:a).must_equal 0
    assert @f.counter_value(:b).must_equal 0
    assert @f.counter_value(:c).must_equal 0
  end

  it "should validate against invalid counter names" do
    proc {@f.counter_value(:x)}.must_raise RuntimeError
  end

  it "should allow increment function" do
    @inc = 5
    [:a, :b, :c].each do |c|
      @inc.times {@f.incr_counter(c)}
      @f.counter_value(c).must_equal @inc
    end
  end

  it "should allow decrement function" do
    @inc = 10
    [:a, :b, :c].each do |c|
      @inc.times {@f.incr_counter(c)}
      @f.counter_value(c).must_equal @inc
    end
    @dec = 2
    @dec.times { @f.decr_counter(:b) }
    @f.counter_value(:b).must_equal @inc - @dec
  end

  it "should support a reset for one counter" do 
    @inc = 10
    @inc.times {@f.incr_counter(:a)}
    @f.counter_value(:a).must_equal @inc
    @f.reset_counter(:a)
    @f.counter_value(:a).must_equal 0
  end

  it "should support a reset for all counters" do 
    @inc = 5
    [:a, :b, :c].each do |c|
      @inc.times {@f.incr_counter(c)}
      @f.counter_value(c).must_equal @inc
    end
    @f.reset_counters
    [:a, :b, :c].each do |c|
      @f.counter_value(c).must_equal 0
    end
  end

  it "should allow access to all counters as a copied hash" do
    @inc = 9
    [:a, :b, :c].each do |c|
      @inc.times {@f.incr_counter(c)}
      @f.counter_value(c).must_equal @inc
    end
    c = @f.counters
    c[:a].must_equal @inc
    c[:b].must_equal @inc
    c[:c].must_equal @inc

    c[:c] += 1
    c[:c].must_equal @inc+1
    @f.counter_value(:c).must_equal @inc
  end
end



#################################################
#
#  T A B L E
#
describe Blackjack::Table, "A Blackjack Table" do
  before do
    @table_name = 'table_1'
    @table = Blackjack::Table.new('table_1')
  end

  it "should have a name" do
    @table.name.must_equal @table_name  
  end

  it "should have players" do
    @table.players.wont_equal nil
  end

  it "should have a dealer" do
    @table.dealer.wont_equal nil
  end

  it "should default to a SixDeckShoe if none is passed in" do
    @table.shoe.class.name.must_equal "Blackjack::SixDeckShoe"
  end

  it "should support default configuration" do 
    @table.config[:blackjack_payout].must_equal [3,2]
    @table.config[:dealer_hits_soft_17].must_equal false
    @table.config[:num_seats].must_equal 6
  end

  it "should support options for configuration" do

    @configuration = {
      blackjack_payout: [6,5],
      dealer_hits_soft_17: true,
      shoe: Blackjack::SingleDeckShoe.new,
      num_seats: 4
    }

    @configured_table = Blackjack::Table.new("configured_table", @configuration)
    [:blackjack_payout, :dealer_hits_soft_17, :shoe, :num_seats].each do |item|
      @configured_table.config[:item].must_equal @configuration[:item]
    end
  end

  it "should allow a player to join the table and find them an open seat" do
    @player = MiniTest::Mock.new
    seat_position = @table.join(@player)
    seat_position.must_be :>=, 0
    seat_position.must_be :<, @table.config[:num_seats]
  end

  it "should auto-fill the table right to left" do
    (0..(@table.config[:num_seats]-1)).each do |i|
      player = Blackjack::Player.new("player_#{i}")
      seat_position = @table.join(player)
      seat_position.must_equal i
    end
  end

  it "should allow a player to join the table at the empty seat of the players choice" do
    @player = MiniTest::Mock.new
    @fav_seat = @table.config[:num_seats]-1
    seat_position = @table.join(@player, @fav_seat)
    seat_position.must_equal @fav_seat
  end

  it "should allow a player to leave the table" do
    @player = Blackjack::Player.new('ted2')
    seat_position = @table.join(@player)
    seat_position.must_be :>=, 0
    seat_position.must_be :<, @table.config[:num_seats]
    @table.leave(@player)
    @player.table.must_equal nil
    @table.players.all?(&:nil?).must_equal true
  end

  it "should allow a player to inquire his/her seat position at the table" do
    @player = Blackjack::Player.new('ted2')
    seat_position = @table.join(@player, 0)
    @table.seat_position(@player).must_equal 0
  end

  it "should not assign a seat to a player when all the seats are full" do
    (0..(@table.config[:num_seats]-1)).each do |i|
      player = Blackjack::Player.new("player_#{i}")
      seat_position = @table.join(player)
      seat_position.must_equal i
    end
    @player = Blackjack::Player.new('machvee')
    proc {@table.join(@player)}.must_raise RuntimeError
  end

  it "should not allow a player to take a specified seat if that seat is filled" do
    @player = Blackjack::Player.new("bubba")
    @bubbas_fav_seat = @table.config[:num_seats]-1
    seat_position = @table.join(@player, @bubbas_fav_seat)
    seat_position.must_equal @bubbas_fav_seat
    @player = Blackjack::Player.new("machvee")
    proc {@table.join(@player, @bubbas_fav_seat)}.must_raise RuntimeError
  end
end

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

  it "should not be busted" do
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

  it "should not be busted" do
    @eight_nine.bust?.must_equal false
  end

  it "should not has_ace?" do
    @eight_nine.has_ace?.must_equal false
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

  it "should not be busted" do
    @jack_q.bust?.must_equal false
  end

  it "should not has_ace?" do
    @jack_q.has_ace?.must_equal false
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

  it "should not be busted" do
    @k_10.bust?.must_equal false
  end

  it "should not be blackjack?" do
    @k_10.blackjack?.must_equal false
  end

  it "should not has_ace?" do
    @k_10.has_ace?.must_equal false
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

  it "should not be busted" do
    @blackjack.bust?.must_equal false
  end

  it "should be blackjack?" do
    @blackjack.blackjack?.must_equal true
  end

  it "should respond true to has_ace?" do
    @blackjack.has_ace?.must_equal true
  end

  it "should be soft?" do
    @blackjack.soft?.must_equal true
  end
end


describe Cards::Cards, "A hand that has multiple aces" do
  before do
    @hand = Cards::Cards.make('AD', 'AC', '4S', '3D')
  end

  it "should not respond to pair" do
    @hand.pair?.must_equal false
  end

  it "should have a hard value of 19" do
    @hand.hard_sum.must_equal 19
  end

  it "should have a soft value of 9" do
    @hand.soft_sum.must_equal 9
  end

  it "should not be busted" do
    @hand.bust?.must_equal false
  end

  it "should not be blackjack?" do
    @hand.blackjack?.must_equal false
  end

  it "should respond true to has_ace?" do
    @hand.has_ace?.must_equal true
  end

  it "should be soft?" do
    @hand.soft?.must_equal true
  end
end


describe Cards::Cards, "A hand that has an aces and is more than 21" do
  before do
    @hand = Cards::Cards.make('AD', '4C', '9S', 'QD')
  end

  it "should not respond to pair" do
    @hand.pair?.must_equal false
  end

  it "should have a hard value of 24" do
    @hand.hard_sum.must_equal 24
  end

  it "should have a soft value of hard value when the soft_value is a bust" do
    @hand.soft_sum.must_equal 24
  end

  it "should be busted" do
    @hand.bust?.must_equal true
  end

  it "should not be blackjack?" do
    @hand.blackjack?.must_equal false
  end

  it "should respond true to has_ace?" do
    @hand.has_ace?.must_equal true
  end

  it "should be soft?" do
    @hand.soft?.must_equal true
  end
end


describe Cards::Cards, "A hand that has an no aces and is more than 21" do
  before do
    @hand = Cards::Cards.make('4D', '5C', '6S', 'QD')
  end

  it "should not respond to pair" do
    @hand.pair?.must_equal false
  end

  it "should have a hard value of 25" do
    @hand.hard_sum.must_equal 25
  end

  it "should have a soft value of hard value when the soft_value is a bust" do
    @hand.soft_sum.must_equal 25
  end

  it "should be busted" do
    @hand.bust?.must_equal true
  end

  it "should not be blackjack?" do
    @hand.blackjack?.must_equal false
  end

  it "should not respond true to has_ace?" do
    @hand.has_ace?.must_equal false
  end

  it "should not be soft?" do
    @hand.soft?.must_equal false
  end
end

describe Cards::Deck, "a deck can be created face up" do
  before do
    @deck = Cards::Deck.new(1, Cards::Card::FACE_UP)
  end

  it "should have a deck with cards face up" do
    @deck.all? {|c| c.face_up?}.must_equal true
  end

  it "should have 52 cards" do
    @deck.length.must_equal 52
  end
end

describe Cards::Deck, "a default deck of one set of cards" do
  before do
    @deck = Cards::Deck.new(1)
  end

  it "should have a deck with cards face down by default" do
    @deck.all? {|c| c.face_down?}.must_equal true
  end

  it "should be able to deal hands" do
    hands = @deck.deal_hands(4, 2)
    hands.length.must_equal 4
    hands.first.length.must_equal 2
  end
end

describe Cards::Deck, "a default deck of one set of cards" do
  before do
    @deck = Cards::Deck.new(1)
  end

  it "should have a deck with cards face down by default" do
    @deck.all? {|c| c.face_down?}.must_equal true
  end

  it "should be able to deal hands" do
    hands = @deck.deal_hands(4, 2)
    hands.length.must_equal 4
    hands.first.length.must_equal 2
  end
end

describe Blackjack::Shoe, "shoes come in a variety of sizes" do
  it "should have the correct number of cards" do
    @shoe = Blackjack::Shoe.new
    @shoe.decks.length.must_equal (1*52)

    @shoe = Blackjack::SingleDeckShoe.new
    @shoe.decks.length.must_equal (1*52)

    @shoe = Blackjack::TwoDeckShoe.new
    @shoe.decks.length.must_equal (2*52)

    @shoe = Blackjack::SixDeckShoe.new
    @shoe.decks.length.must_equal (6*52)
  end
end

describe Blackjack::Shoe, "a 6 deck shoe" do
  before do
    @shoe = Blackjack::SixDeckShoe.new
  end

  it "should have a functioning random cut card somewhere past half the deck" do
    @shoe.place_cut_card
    @shoe.cutoff.must_be :<, @shoe.decks.length/3
  end

  it "should not need shuffle upon initial cut card placement" do
    @shoe.place_cut_card
    @shoe.needs_shuffle?.must_equal false
  end

  it "should support options for cut card" do
    @num_decks = 10
    opts = {
      cut_card_segment: 0.10,
      cut_card_offset:  0.05,
      split_and_shuffles: 5,
      num_decks_in_shoe: @num_decks
    }
    @custom_shoe = Blackjack::Shoe.new(opts)
    @custom_shoe.shuffle
    100.times {
      @custom_shoe.place_cut_card
      @custom_shoe.cutoff.must_be :<=, @shoe.decks.length/4
    }
    @custom_shoe.decks.length.must_equal (@num_decks*52)
  end

  it "should let the cut card be placed at a specific offset" do
    @my_offset = 84
    @shoe.place_cut_card(@my_offset)
    @shoe.cutoff.must_equal @my_offset
  end

  it "shuffle up should set cutoff to nil" do
    @shoe.place_cut_card
    @shoe.cutoff.must_be :>, 0
    @shoe.shuffle
    @shoe.cutoff.must_equal nil
  end

  it "should deal cards to hands one at a time face up" do
    num_cards = @shoe.decks.length
    @destination = MiniTest::Mock.new
    top_card = @shoe.decks.first
    @destination.expect(:add, nil, [[top_card]])
    @shoe.deal_one_up(@destination)
    @destination.verify
    @shoe.decks.length.must_equal num_cards-1
  end

  it "should deal cards to hands one at a time face down" do
    num_cards = @shoe.decks.length
    @destination = MiniTest::Mock.new
    top_card = @shoe.decks.first
    @destination.expect(:add, nil, [[top_card]])
    @shoe.deal_one_down(@destination)
    @destination.verify
    @shoe.decks.length.must_equal num_cards-1
  end

  it "should deal cards and report needs_shuffle? true when reached cut card" do
    @shoe.place_cut_card
    deal_this_many = @shoe.decks.length - @shoe.cutoff
    deal_this_many.times do
      @destination = MiniTest::Mock.new
      top_card = @shoe.decks.first
      @destination.expect(:add, nil, [[top_card]])
      @shoe.deal_one_up(@destination)
      @destination.verify
      @shoe.needs_shuffle?.wont_equal true
    end
    @destination = MiniTest::Mock.new
    top_card = @shoe.decks.first
    @destination.expect(:add, nil, [[top_card]])
    @shoe.deal_one_up(@destination)
    @destination.verify
    @shoe.needs_shuffle?.must_equal true
  end

  it "should deal cards to hands one at a time face up and keep counter" do
    num_cards = @shoe.decks.length
    @destination = MiniTest::Mock.new
    top_card = @shoe.decks.first
    @destination.expect(:add, nil, [[top_card]])
    @shoe.counter_value(:cards_dealt).must_equal 0
    @shoe.deal_one_up(@destination)
    @shoe.counter_value(:cards_dealt).must_equal 1
    @destination.verify
    @shoe.shuffle
    @destination = MiniTest::Mock.new
    top_card = @shoe.decks.first
    @destination.expect(:add, nil, [[top_card]])
    @shoe.deal_one_up(@destination)
    @destination.verify
    @shoe.counter_value(:cards_dealt).must_equal 2
  end

  it "shuffle up shoudl incr counter" do
    @shoe.counter_value(:num_shuffles).must_equal 1
    @shuffs = 4
    @shuffs.times { @shoe.shuffle }
    @shoe.counter_value(:num_shuffles).must_equal 1 + @shuffs
  end

  it "should allow resetting of all counters" do 
    @shoe.counter_value(:num_shuffles).must_equal 1
    @shuffs = 4
    @shuffs.times { @shoe.shuffle }
    @shoe.counter_value(:num_shuffles).must_equal 1 + @shuffs
    num_cards = @shoe.decks.length
    @destination = MiniTest::Mock.new
    top_card = @shoe.decks.first
    @destination.expect(:add, nil, [[top_card]])
    @shoe.counter_value(:cards_dealt).must_equal 0
    @shoe.deal_one_up(@destination)
    @shoe.counter_value(:cards_dealt).must_equal 1
    @destination.verify

    @shoe.reset_counters
    @shoe.counter_value(:cards_dealt).must_equal 0
    @shoe.counter_value(:num_shuffles).must_equal 0
  end
end
