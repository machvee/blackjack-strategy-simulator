require 'minitest/autorun'
require 'table'

#################################################
#
#  C O U N T E R S
#
module Blackjack

  describe CounterMeasures, "A counter/measurement DSL" do
    describe CounterMeasures::Counter, "A counter DSL" do
      before do
        class Foo
          include CounterMeasures
          counters :a, :b, :c
        end
        @f = Foo.new
      end

      it "should allow named counter access" do
        assert @f.a.count.must_equal 0
        assert @f.b.count.must_equal 0
        assert @f.c.count.must_equal 0
      end

      it "should allow increment function" do
        @inc = 5
        @inc.times {@f.a.incr}
        @f.a.count.must_equal @inc
      end

      it "should allow decrement function" do
        @inc = 10
        @inc.times {@f.c.incr}
        @f.c.count.must_equal @inc
        @dec = 2
        @dec.times { @f.c.decr}
        @f.c.count.must_equal @inc - @dec
      end

      it "should support a reset for one counter" do 
        @inc = 10
        @inc.times {@f.b.incr}
        @f.a.incr
        @f.a.count.must_equal 1
        @f.b.count.must_equal @inc
        @f.b.reset
        @f.b.count.must_equal 0
        @f.a.count.must_equal 1
      end

      it "should support a reset for all counters" do 
        @inc = 5
        @inc.times {@f.a.incr; @f.b.incr; @f.c.incr}
        @f.a.count.must_equal @inc
        @f.b.count.must_equal @inc
        @f.c.count.must_equal @inc
        @f.reset_counters
        @f.a.count.must_equal 0
        @f.b.count.must_equal 0
        @f.c.count.must_equal 0
      end

      it "should allow access to all counters as a copied hash but frozen" do
        @inc = 9
        @inc.times {@f.a.incr; @f.b.incr; @f.c.incr}
        @f.a.count.must_equal @inc
        @f.b.count.must_equal @inc
        @f.c.count.must_equal @inc
        c = @f.counters
        c[:a].must_equal @inc
        c[:b].must_equal @inc
        c[:c].must_equal @inc

        proc {c[:c] += 1}.must_raise RuntimeError
      end

      it "should act like a rising and falling quantity, with high and low watermarks" do
        @f.a.set(10000)
        @f.a.add(50)
        @f.a.add(50)
        @f.a.add(100)
        @f.a.add(1000)
        @f.a.sub(5000)
        @f.a.count.must_equal(10000+50+50+100+1000-5000)
        @f.a.high.must_equal(10000+50+50+100+1000)
        @f.a.low.must_equal(10000+50+50+100+1000-5000)
      end
    end

    describe CounterMeasures::Measure, "A Measurement DSL" do
      before do
        class Weather
          include CounterMeasures
          counters :rainy_days, :sunny_days
          measures :rainfall, :temperature
        end
        @w = Weather.new
      end

      it "should allow both counters and measure to be accessed" do
        @w.rainy_days.incr
        @w.rainy_days.incr
        @w.rainy_days.incr
        @w.rainy_days.incr
        @w.sunny_days.incr
        @w.rainy_days.count.must_equal 4
        @w.sunny_days.count.must_equal 1

        readings = [2,1,3,1]
        readings.each do |inches_of_rain|
          @w.rainfall.incr(inches_of_rain)
        end
        @w.rainfall.commit
        first_reading = @w.rainfall.total
        readings2 = [4,2,0]
        @w.rainfall.add(*readings2)
        @w.rainfall.total.must_be :==, readings.reduce(:+) + readings2.reduce(:+)
        @w.rainfall.count.must_equal 4
        @w.rainfall.last.must_equal(0)
        @w.rainfall.last(3).must_equal(readings2)
        @w.rainfall.last(4).must_equal([first_reading] + readings2)
        @w.reset_measures
        @w.rainfall.count.must_equal 0
      end
    end
  end



  #################################################
  #
  #  D E A L E R
  #
  describe Dealer, "A Blackjack Dealer" do
    before do
      @table = Table.new('table_1')
      @players = []
      3.times {
        player = MiniTest::Mock.new
        @players << player
      }
      @dealer = Dealer.new(@table)
    end

    it "should deal hands to players with bets made" do
      @dealer.deal_one_card_face_up_to_bet_active_bet_box
    end
  end


  #################################################
  #
  #  T A B L E
  #
  describe Table, "A Blackjack Table" do
    before do
      @table_name = 'table_1'
      @table = Table.new('table_1')
    end

    it "should have a name" do
      @table.name.must_equal @table_name  
    end

    it "should have seats where players join" do
      @table.seated_players.wont_equal nil
    end

    it "should have bet boxes" do
      @table.bet_boxes.wont_equal nil
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
      @table.config[:player_surrender].must_equal false
      @table.config[:num_seats].must_equal 6
      @table.config[:minimum_bet].must_equal 25
      @table.config[:maximum_bet].must_equal 5000
      @table.config[:double_down_on].must_equal []
    end

    it "should support options for configuration" do

      @configuration = {
        blackjack_payout: [6,5],
        dealer_hits_soft_17: true,
        shoe: SingleDeckShoe.new,
        num_seats: 4
      }

      @configured_table = Table.new("configured_table", @configuration)
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

    it "should allow respond true to any_seated_players? when a player is seated" do 
      @player = MiniTest::Mock.new
      seat_position = @table.join(@player)
      seat_position.must_be :>=, 0
      seat_position.must_be :<, @table.config[:num_seats]
      @table.any_seated_players?.must_equal(true)
    end

    it "should allow respond false to any_seated_players? when table is empty" do 
      @table.any_seated_players?.must_equal(false)
    end

    it "should increment the players_seated counter when a player joins" do
      @table.players_seated.count.must_equal 0
      @player = MiniTest::Mock.new
      seat_position = @table.join(@player)
      @table.players_seated.count.must_equal 1
    end

    it "should auto-fill the table right to left" do
      (0..(@table.config[:num_seats]-1)).each do |i|
        player = Player.new("player_#{i}")
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
      @player = Player.new('ted2')
      seat_position = @table.join(@player)
      seat_position.must_be :>=, 0
      seat_position.must_be :<, @table.config[:num_seats]
      @table.leave(@player)
      @player.table.must_equal nil
      @table.seated_players.all?(&:nil?).must_equal true
    end

    it "should allow a player to inquire his/her seat position at the table" do
      @fav_seat = 4
      @player = Player.new('ted2')
      seat_position = @table.join(@player, @fav_seat)
      @table.seat_position(@player).must_equal @fav_seat
    end

    it "should provide the player way to reach their designated bet_box" do
      @fav_seat = 4
      @player = Player.new('ted4')
      seat_position = @table.join(@player, @fav_seat)
      @table.bet_boxes.dedicated_to(@player).must_equal(@table.bet_boxes[@fav_seat])
    end

    it "should provide a mid-table player way to reach adjacent, available bet_boxes for multi-bet play" do
      @fav_seat = 2
      @player = Player.new('ted2')
      seat_position = @table.join(@player, @fav_seat)
      expected_results = [
        @table.bet_boxes[@fav_seat],
        @table.bet_boxes[@fav_seat-1],
        @table.bet_boxes[@fav_seat+1]
      ].each
      @table.bet_boxes.available_for(@player) do |bet_box|
        bet_box.must_equal(expected_results.next)
      end
    end

    it "should provide a mid-table player way to reach adjacent, available bet_boxes for multi-bet play when the one to the right is taken" do
      @fav_seat = 2
      @player = Player.new('ted2')
      @player2 = Player.new('tedsbuddy')
      seat_position = @table.join(@player, @fav_seat)
      seat_position = @table.join(@player2, @fav_seat-1)
      expected_results = [
        @table.bet_boxes[@fav_seat],
        @table.bet_boxes[@fav_seat+1],
        @table.bet_boxes[@fav_seat+2]
      ].each
      @table.bet_boxes.available_for(@player) do |bet_box|
        bet_box.must_equal(expected_results.next)
      end
    end

    it "should provide a mid-table player way to reach adjacent, available bet_boxes for multi-bet play when the one to the left is taken" do
      @fav_seat = 2
      @player = Player.new('ted2')
      @player2 = Player.new('tedsbuddy')
      seat_position = @table.join(@player, @fav_seat)
      seat_position = @table.join(@player2, @fav_seat+1)
      expected_results = [
        @table.bet_boxes[@fav_seat],
        @table.bet_boxes[@fav_seat-1],
        @table.bet_boxes[@fav_seat-2]
      ].each
      @table.bet_boxes.available_for(@player) do |bet_box|
        bet_box.must_equal(expected_results.next)
      end
    end

    it "should provide a mid-table player one bet_box when no other adjacents are available" do
      @fav_seat = 2
      @player = Player.new('ted2')
      @player2 = Player.new('tedsbuddy')
      @player3 = Player.new('tedsotherbuddy')
      seat_position = @table.join(@player, @fav_seat)
      seat_position = @table.join(@player2, @fav_seat+1)
      seat_position = @table.join(@player3, @fav_seat-1)
      expected_results = [
        @table.bet_boxes[@fav_seat]
      ].each
      @table.bet_boxes.available_for(@player) do |bet_box|
        bet_box.must_equal(expected_results.next)
      end
    end

    it "should provide a mid-table player two bet_boxes when only one adjacent is available" do
      @fav_seat = 2
      @player = Player.new('ted2')
      @player2 = Player.new('tedsbuddy')
      @player3 = Player.new('tedsotherbuddy')
      seat_position = @table.join(@player, @fav_seat)
      seat_position = @table.join(@player2, @fav_seat+1)
      seat_position = @table.join(@player3, @fav_seat-2)
      expected_results = [
        @table.bet_boxes[@fav_seat],
        @table.bet_boxes[@fav_seat-1]
      ].each
      @table.bet_boxes.available_for(@player) do |bet_box|
        bet_box.must_equal(expected_results.next)
      end
    end

    it "should provide a zero position player way to reach adjacent, available bet_boxes for multi-bet play" do
      @fav_seat = 0
      @player = Player.new('tedzero')
      seat_position = @table.join(@player, @fav_seat)
      expected_results = [
        @table.bet_boxes[@fav_seat],
        @table.bet_boxes[@fav_seat+1],
        @table.bet_boxes[@fav_seat+2]
      ].each
      @table.bet_boxes.available_for(@player) do |bet_box|
        bet_box.must_equal(expected_results.next)
      end
    end

    it "should provide the last position player way to reach adjacent, available bet_boxes for multi-bet play" do
      @fav_seat = @table.config[:num_seats]
      @player = Player.new('tedlast')
      seat_position = @table.join(@player, @fav_seat)
      expected_results = [
        @table.bet_boxes[@fav_seat],
        @table.bet_boxes[@fav_seat-1],
        @table.bet_boxes[@fav_seat-2]
      ].each
      @table.bet_boxes.available_for(@player) do |bet_box|
        bet_box.must_equal(expected_results.next)
      end
    end

    it "should not assign a seat to a player when all the seats are full" do
      (0..(@table.config[:num_seats]-1)).each do |i|
        player = Player.new("player_#{i}")
        seat_position = @table.join(player)
        seat_position.must_equal i
      end
      @player = Player.new('machvee')
      proc {@table.join(@player)}.must_raise RuntimeError
    end

    it "should not allow a player to take a specified seat if that seat is filled" do
      @player = Player.new("bubba")
      @bubbas_fav_seat = @table.config[:num_seats]-1
      seat_position = @table.join(@player, @bubbas_fav_seat)
      seat_position.must_equal @bubbas_fav_seat
      @player = Player.new("machvee")
      proc {@table.join(@player, @bubbas_fav_seat)}.must_raise RuntimeError
    end

    it "should allow people to ask if a specific seat is available, and return true if it is" do
      @table.seat_available?(2).must_equal true
    end

    it "should allow people to ask if ANY seat is available, and return true if it is" do
      @table.seat_available?.must_equal true
    end

    it "should allow people to ask if ANY seat is available, and return false when all taken" do
      (0..(@table.config[:num_seats]-1)).each do |i|
        player = Player.new("player_#{i}")
        seat_position = @table.join(player)
        seat_position.must_equal i
      end
      @table.seat_available?.must_equal false
    end

    it "should allow people to ask if a specific seat is available, and return false if not" do
      @player = Player.new("bubba")
      @bubbas_fav_seat = @table.config[:num_seats]-1
      seat_position = @table.join(@player, @bubbas_fav_seat)
      seat_position.must_equal @bubbas_fav_seat
      @table.seat_available?(@bubbas_fav_seat).must_equal false
    end

    it "should allow use of the game play class with many players" do
      class TestStrategy < PlayerHandStrategy
        def play?
          Action::BET
        end

        def insurance?(bet_box)
          bet_box.hand.blackjack? ? Action::EVEN_MONEY : Action::NO_INSURANCE
        end

        def bet_amount
          25
        end

        def decision(bet_box, dealer_up_card, other_hands)
        end
      end
      names = %w{dave davey katie vader cass erica}
      players = names.map {|n| Player.new(n)}
      players.each {|p| p.strategy = TestStrategy.new(@table, p); p.join(@table)}
      @table.num_players.must_equal(names.length)
      gp = GamePlay.new(@table)
      gp.wait_for_player_bets
      gp.shuffle_check
      gp.opening_deal
      @table.bet_boxes.each_active do |bb|
        bb.box.current_balance.must_equal(25)
        bb.hand.length.must_equal(2)
        bb.hand[0].face_up?.must_equal(true)
        bb.hand[1].face_up?.must_equal(true)
      end
      @table.dealer.up_card.face_up?.must_equal(true)
      @table.dealer.hole_card.face_down?.must_equal(true)
    end
  end

  describe StrategyValidator, "A validator for strategy responses" do
    before do
      @table = Table.new('t1')
      @player = Player.new('dave')
      @player.join(@table)
      @sv = StrategyValidator.new(@table)
    end

    it "for the play response, it should return false with non-play response" do
      @sv.validate_play?(@player, Action::HIT).must_equal([false, "Sorry, that's not a valid response"])
    end

    it "for the play response, it should return true with valid LEAVE response" do
      @sv.validate_play?(@player, Action::LEAVE).must_equal([true, nil])
    end

    it "for the play response, it should return true with valid BET response" do
      @sv.validate_play?(@player, Action::BET).must_equal([true, nil])
    end

    it "for the play response, it should return true with valid SIT_OUT response" do
      @sv.validate_play?(@player, Action::SIT_OUT).must_equal([true, nil])
    end

    it "for the play response, it should return false when player is broke and they want to BET" do
      @player.bank.debit(@player.bank.current_balance)
      @player.bank.current_balance.must_equal(0)
      @sv.validate_play?(@player, Action::BET).must_equal([false,
        "Player has insufficient funds to make a #{@table.config[:minimum_bet]} minimum bet"])
    end

  
    it "it should return false for insurance with non-insurance response" do
      @sv.validate_insurance?(@player.bet_box, Action::HIT).must_equal([false, "Sorry, that's not a valid response"])
    end

    it "should return false for insurance? when player is broke and they want INSURANCE" do
      @player.make_bet(@player.bet_box, 10)
      @player.bank.debit(@player.bank.current_balance)
      @player.bank.current_balance.must_equal(0)
      @player.bet_box.hand.set('JD', '9H')
      @sv.validate_insurance?(@player.bet_box, Action::INSURANCE).must_equal([false,
        "Player has insufficient funds to make an insurance bet"])
    end

    it "should return true for insurance? when player wants INSURANCE" do
      @player.make_bet(@player.bet_box, 10)
      @player.bet_box.hand.set('JD', '9H')
      @sv.validate_insurance?(@player.bet_box, Action::INSURANCE).must_equal([true, nil])
    end

    it "should return false for insurance player doesn't have blackjack and they want EVEN MONEY" do
      @player.make_bet(@player.bet_box, 10)
      @player.bet_box.hand.set('JD', '9H')
      @sv.validate_insurance?(@player.bet_box, Action::EVEN_MONEY).must_equal([false,
        "Player must have Blackjack to request even money"])
    end

    it "should return true for insurance player has blackjack and they want EVEN MONEY" do
      @player.make_bet(@player.bet_box, 10)
      @player.bet_box.hand.set('JD', 'AH')
      @sv.validate_insurance?(@player.bet_box, Action::EVEN_MONEY).must_equal([true, nil])
    end

    it "should return false for bet_amount when player has insufficient funds" do
      @player.bank.debit(@player.bank.current_balance)
      @player.bank.current_balance.must_equal(0)
      @sv.validate_bet_amount(@player, 25).must_equal([false,
        "Player has insufficient funds to make a #{@table.config[:minimum_bet]} minimum bet"])
    end

    it "should return false for bet_amount when player bets below table minimum" do
      min = @table.config[:minimum_bet]
      @sv.validate_bet_amount(@player, min-1).must_equal([false,
        "Player bet must be between #{min} and #{@table.config[:maximum_bet]}"])
    end

    it "should return false for bet_amount when player bets above table maximum" do
      max = @table.config[:maximum_bet]
      @sv.validate_bet_amount(@player, max+1).must_equal([false,
        "Player bet must be between #{@table.config[:minimum_bet]} and #{max}"])
    end

    it "should return true for a valid bet_amount" do
      min = @table.config[:minimum_bet]
      max = @table.config[:maximum_bet]
      @sv.validate_bet_amount(@player, min).must_equal([true, nil])
      @sv.validate_bet_amount(@player, max).must_equal([true, nil])
      @sv.validate_bet_amount(@player, min+1).must_equal([true, nil])
      @sv.validate_bet_amount(@player, max-1).must_equal([true, nil])
    end

    it "should return false for decision when input is a non-decsion" do
      @sv.validate_decision(@player.bet_box, Action::LEAVE).must_equal([false, "Sorry, that's not a valid response"])
    end

    it "should return false for decision when input is a SURRENDER but table doesn't allow it" do
      @table.config[:player_surrender] = false
      @player.make_bet(@player.bet_box, 10)
      @player.bet_box.hand.set('JD', '9H')
      @sv.validate_decision(@player.bet_box, Action::SURRENDER).must_equal([false,
        "This table does not allow player to surrender"])
    end

    it "should return false for decision when input is a SURRENDER but player already took a hit" do
      @table.config[:player_surrender] = true
      @player.make_bet(@player.bet_box, 10)
      @player.bet_box.hand.set('4D', '9H', '3H')
      @sv.validate_decision(@player.bet_box, Action::SURRENDER).must_equal([false,
        "Player may surrender only after initial hand is dealt"])
    end

    it "should return false for decision when input is a SURRENDER but player already split" do
      @table.config[:player_surrender] = true
      @player.make_bet(@player.bet_box, 10)
      @player.bet_box.hand.set('4D', '9H')
      @player.bet_box.split
      @sv.validate_decision(@player.bet_box, Action::SURRENDER).must_equal([false,
        "Player may surrender only after initial hand is dealt"])
    end

    it "should return true for decision when input is a SURRENDER and its legit" do
      @table.config[:player_surrender] = true
      @player.make_bet(@player.bet_box, 10)
      @player.bet_box.hand.set('4D', '9H')
      @sv.validate_decision(@player.bet_box, Action::SURRENDER).must_equal([true, nil])
    end

    it "should return false for decision when input is a SPLIT and player is broke" do
      @player.make_bet(@player.bet_box, 10)
      @player.bank.debit(@player.bank.current_balance)
      @player.bet_box.hand.set('8D', '8H')
      @sv.validate_decision(@player.bet_box, Action::SPLIT).must_equal([false,
        "Player has insufficient funds to split the hand"])
    end

    it "should return false for decision when input is a SPLIT and player doesn't have pair" do
      @player.make_bet(@player.bet_box, 10)
      @player.bet_box.hand.set('9D', '8H')
      @sv.validate_decision(@player.bet_box, Action::SPLIT).must_equal([false,
        "Player can only split cards that are identical in value"])
    end

    it "should return true for decision when input is a SPLIT and its legit" do
      @player.make_bet(@player.bet_box, 10)
      @player.bet_box.hand.set('8D', '8H')
      @sv.validate_decision(@player.bet_box, Action::SPLIT).must_equal([true, nil])
    end

    it "should return false for decision when input is DOUBLE_DOWN and player is broke" do
      @player.make_bet(@player.bet_box, 10)
      @player.bank.debit(@player.bank.current_balance)
      @player.bet_box.hand.set('8D', '3H')
      @sv.validate_decision(@player.bet_box, Action::DOUBLE_DOWN).must_equal([false,
        "Player has insufficient funds to double down"])
    end

    it "should return false for decision when input is DOUBLE_DOWN and player has bad double hand" do
      @table.config[:double_down_on] = [10,11]
      @player.make_bet(@player.bet_box, 10)
      @player.bet_box.hand.set('AD', '4H')
      @sv.validate_decision(@player.bet_box, Action::DOUBLE_DOWN).must_equal([false,
        "Player can only double down on hands of 10, 11"])
    end

    it "should return true for decision when input is DOUBLE_DOWN and player has legit config hand" do
      @table.config[:double_down_on] = [10,11]
      @player.make_bet(@player.bet_box, 10)
      @player.bet_box.hand.set('6D', '4H')
      @sv.validate_decision(@player.bet_box, Action::DOUBLE_DOWN).must_equal([true, nil])
      @player.bet_box.hand.set('6D', '5H')
      @sv.validate_decision(@player.bet_box, Action::DOUBLE_DOWN).must_equal([true, nil])
    end

    it "should return true for decision when input is DOUBLE_DOWN and player has legit hand" do
      @table.config[:double_down_on] = []
      @player.make_bet(@player.bet_box, 10)
      @player.bet_box.hand.set('AD', '5H')
      @sv.validate_decision(@player.bet_box, Action::DOUBLE_DOWN).must_equal([true, nil])
    end

    it "should return true for decision when input is HIT and player hand is hittable" do
      @player.make_bet(@player.bet_box, 10)
      @player.bet_box.hand.set('4D', '5H')
      @sv.validate_decision(@player.bet_box, Action::HIT).must_equal([true, nil])
      @player.bet_box.hand.set('10D', 'KH')
      @sv.validate_decision(@player.bet_box, Action::HIT).must_equal([true, nil])
      @player.bet_box.hand.set('3D', '2H', 'AD', '5C')
      @sv.validate_decision(@player.bet_box, Action::HIT).must_equal([true, nil])
    end

    it "should return false for decision when input is HIT and player hand is not hittable" do
      @player.make_bet(@player.bet_box, 10)
      @player.bet_box.hand.set('3D', '2H', '9D', '6C', 'AS')
      @sv.validate_decision(@player.bet_box, Action::HIT).must_equal([false,
        "Player hand can no longer be hit after hard 21"])
    end

    it "should return true decision when player wants to STAND" do
      @player.make_bet(@player.bet_box, 10)
      @player.bet_box.hand.set('KD', 'QH')
      @sv.validate_decision(@player.bet_box, Action::STAND).must_equal([true, nil])
    end


  end

  describe Player, "A Player" do
    before do
      @player = Player.new(@name='dave')
    end

    it "should have a name" do
      @player.name.must_equal(@name)
    end

    it "should have a bank" do
      @player.bank.current_balance.must_be :>, 0
    end

    it "should have stats" do
      @player.stats.hands.count.must_equal(0)
      @player.stats.hands_won.count.must_equal(0)
      @player.stats.hands_lost.count.must_equal(0)
      @player.stats.busts.count.must_equal(0)
      @player.stats.blackjacks.count.must_equal(0)
    end

    it "should be able to join a table" do
      @table = MiniTest::Mock.new
      @table.expect(:join, @player, [@player, nil])
      @player.join(@table)
      @table.verify
    end

    it "should be able to join a table at a specific seat position" do
      @table = MiniTest::Mock.new
      @seat = 0
      @table.expect(:join, @player, [@player, @seat])
      @player.join(@table, @seat)
      @table.verify
    end

    it "should be able to join, then leave a table" do
      @table = MiniTest::Mock.new
      @table.expect(:leave, @player, [@player])
      @table.expect(:join, @player, [@player, nil])
      @player.join(@table)
      @player.leave_table
      @table.verify
    end

  end

  describe Bank, "A money account" do
    before do
      @initial_balance = 3833
      @bank1 = Bank.new(@initial_balance)
      @bank2 = Bank.new(@initial_balance)
    end

    it "should have initial balances" do
      @bank1.current_balance.must_equal(@initial_balance)
      @bank2.current_balance.must_equal(@initial_balance)
    end

    it "should allow direct credit and debiting" do
      amount_to_credit = 91
      amount_to_debit = 83
      @bank1.credit(amount_to_credit)
      @bank1.current_balance.must_equal(@initial_balance + amount_to_credit)
      @bank1.credits.count.must_equal(1)
      @bank2.debit(amount_to_debit)
      @bank2.current_balance.must_equal(@initial_balance - amount_to_debit)
      @bank2.debits.count.must_equal(1)
    end

    it "should allow a reset back to initial balance" do
      amount_to_credit = 91
      amount_to_debit = 83
      @bank1.credit(amount_to_credit)
      @bank1.current_balance.must_equal(@initial_balance + amount_to_credit)
      @bank1.credits.count.must_equal(1)
      @bank2.debit(amount_to_debit)
      @bank2.current_balance.must_equal(@initial_balance - amount_to_debit)
      @bank2.debits.count.must_equal(1)
      @bank1.reset
      @bank2.reset
      @bank1.current_balance.must_equal(@initial_balance)
      @bank2.current_balance.must_equal(@initial_balance)
      @bank1.credits.count.must_equal(0)
      @bank2.credits.count.must_equal(0)
      @bank1.debits.count.must_equal(0)
      @bank2.debits.count.must_equal(0)
    end

    it "should allow transfer_to another account" do
      amount_to_transfer = 382
      @bank1.transfer_to(@bank2, amount_to_transfer)
      @bank1.current_balance.must_equal(@initial_balance - amount_to_transfer)
      @bank2.current_balance.must_equal(@initial_balance + amount_to_transfer)
      @bank1.credits.count.must_equal(0)
      @bank1.debits.count.must_equal(1)
      @bank2.credits.count.must_equal(1)
      @bank2.debits.count.must_equal(0)
    end

    it "should allow transfer_from another account" do
      amount_to_transfer = 98
      @bank1.transfer_from(@bank2, amount_to_transfer)
      @bank1.current_balance.must_equal(@initial_balance + amount_to_transfer)
      @bank2.current_balance.must_equal(@initial_balance - amount_to_transfer)
      @bank1.credits.count.must_equal(1)
      @bank1.debits.count.must_equal(0)
      @bank2.credits.count.must_equal(0)
      @bank2.debits.count.must_equal(1)
    end

    it "should raise an exception if trying to debit below 0 balance" do
      @bank1.debit(@initial_balance) # ok
      @bank1.current_balance.must_equal(0)
      proc {
        @bank2.debit(@initial_balance+1)
      }.must_raise RuntimeError
      @bank2.current_balance.must_equal(@initial_balance)
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

  describe Shoe, "shoes come in a variety of sizes" do
    it "should have the correct number of cards" do
      @shoe = Shoe.new
      @shoe.remaining.must_equal (1*52)

      @shoe = SingleDeckShoe.new
      @shoe.remaining.must_equal (1*52)

      @shoe = TwoDeckShoe.new
      @shoe.remaining.must_equal (2*52)

      @shoe = SixDeckShoe.new
      @shoe.remaining.must_equal (6*52)
    end
  end

  describe Shoe, "a 6 deck shoe" do
    before do
      @shoe = SixDeckShoe.new
    end

    it "should have a functioning random cut card somewhere past half the deck" do
      @shoe.place_cut_card
      @shoe.cutoff.must_be :<, @shoe.remaining/3
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
      @custom_shoe = Shoe.new(opts)
      @custom_shoe.shuffle
      100.times {
        @custom_shoe.place_cut_card
        @custom_shoe.cutoff.must_be :<=, @shoe.remaining/4
      }
      @custom_shoe.remaining.must_equal (@num_decks*52)
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

    it "should allow a force_shuffle to be invoked, causing needs_shuffle? to be true" do
      @shoe.place_cut_card
      @shoe.needs_shuffle?.must_equal(false)
      @shoe.force_shuffle
      @shoe.needs_shuffle?.must_equal(true)
      @shoe.shuffle
      @shoe.place_cut_card
      @shoe.needs_shuffle?.must_equal(false)
    end

    it "should deal cards to hands one at a time face up" do
      num_cards = @shoe.remaining
      @destination = MiniTest::Mock.new
      top_card = @shoe.decks.first
      @destination.expect(:add, nil, [[top_card]])
      @shoe.place_cut_card
      @shoe.deal_one_up(@destination)
      @destination.verify
      @shoe.remaining.must_equal num_cards-1
    end

    it "should deal cards to hands one at a time face down" do
      @shoe.place_cut_card
      num_cards = @shoe.remaining
      @destination = MiniTest::Mock.new
      top_card = @shoe.decks.first
      @destination.expect(:add, nil, [[top_card]])
      @shoe.deal_one_down(@destination)
      @destination.verify
      @shoe.remaining.must_equal num_cards-1
    end

    it "should support a new hand getter to deal cards to" do
      @shoe.place_cut_card
      hand = @shoe.new_hand
      num_cards = 3
      num_cards.times { @shoe.deal_one_up(hand)}
      hand.length.must_equal num_cards
    end

    it "should support a discard pile that is wired to the hand when it folds and back to deck when shuffling" do
      @shoe.place_cut_card
      start_count = @shoe.remaining
      hand_counts = [11,4,7,3,2,9]
      hands = Array.new(hand_counts.length) {@shoe.new_hand}
      cards_dealt = hand_counts.reduce(:+)

      2.times do
        total_cards_dealt = 0
        3.times do |i|
          hand_counts.each_with_index do |c, i|
            c.times { @shoe.deal_one_up(hands[i])}
            hands[i].length.must_equal(c)
          end
          total_cards_dealt += cards_dealt
          @shoe.remaining.must_equal(start_count - total_cards_dealt)

          hands.map(&:fold)
          @shoe.discarded.must_equal(total_cards_dealt)

          hands.all? {|h| h.length == 0}.must_equal(true)
        end

        @shoe.remaining.must_equal(start_count - total_cards_dealt)
        @shoe.discarded.must_equal(total_cards_dealt)

        @shoe.shuffle
        @shoe.place_cut_card
        @shoe.discarded.must_equal(0)
        @shoe.remaining.must_equal(start_count)
      end
    end

    it "should deal cards and report needs_shuffle? true when reached cut card" do
      @shoe.place_cut_card
      deal_this_many = @shoe.remaining - @shoe.cutoff
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
      @shoe.place_cut_card
      num_cards = @shoe.remaining
      @destination = MiniTest::Mock.new
      top_card = @shoe.decks.first
      @destination.expect(:add, nil, [[top_card]])
      @shoe.cards_dealt.count.must_equal 0
      @shoe.deal_one_up(@destination)
      @shoe.cards_dealt.count.must_equal 1
      @destination.verify
      @shoe.shuffle
      @shoe.place_cut_card
      @destination = MiniTest::Mock.new
      top_card = @shoe.decks.first
      @destination.expect(:add, nil, [[top_card]])
      @shoe.deal_one_up(@destination)
      @destination.verify
      @shoe.cards_dealt.count.must_equal 2
    end

    it "shuffle up shoudl incr counter" do
      @shoe.num_shuffles.count.must_equal 1
      @shuffs = 4
      @shuffs.times { @shoe.shuffle }
      @shoe.place_cut_card
      @shoe.num_shuffles.count.must_equal 1 + @shuffs
    end

    it "should allow resetting of all counters" do 
      @shoe.num_shuffles.count.must_equal 1
      @shuffs = 4
      @shuffs.times { @shoe.shuffle }
      @shoe.place_cut_card
      @shoe.num_shuffles.count.must_equal 1 + @shuffs
      num_cards = @shoe.remaining
      @destination = MiniTest::Mock.new
      top_card = @shoe.decks.first
      @destination.expect(:add, nil, [[top_card]])
      @shoe.cards_dealt.count.must_equal 0
      @shoe.deal_one_up(@destination)
      @shoe.cards_dealt.count.must_equal 1
      @destination.verify

      @shoe.reset_counters
      @shoe.cards_dealt.count.must_equal 0
      @shoe.num_shuffles.count.must_equal 0
    end
  end
end
