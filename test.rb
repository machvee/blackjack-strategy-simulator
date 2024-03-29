require 'minitest/autorun'
require 'table'
require 'byebug'

module Blackjack

  class TestShoe < Shoe
    def initialize(dealer_fs, players_fs, remaining=[])
      #
      # this is a shoe that you can stack, that won't shuffle the
      # order so for testing purposes, we can pre-arrange what
      # cards will be dealt
      #
      super(split_and_shuffles: 0, num_decks: 1)
      face_suits = []
      players_fs.each do |pc|
        face_suits << pc[0]
      end
      face_suits << dealer_fs[0]
      players_fs.each do |pc|
        face_suits << pc[1]
      end
      face_suits << dealer_fs[1]
      face_suits += remaining

      decks.set(BlackjackCard.make(*face_suits))
    end

    def beyond_cut?
      false
    end
  end

  describe Player, "A Blackjack Player" do
    it "should be able to play the game of blackjack interactively" do
    end

    it "should be able to define a Strategy for betting" do
    end

    it "should be able to define a Strategy for hitting/doubling/standing/splitting" do
    end

    it "should be able to automate his play using a defined Strategy" do 
    end
 
    it "should be able to describe events that may occur during the game, and alter strategy when those events occur" do
    end

    it "should be able to view stats maintained during automated play so as to assign a score or value to a Strategy" do
    end

    it "should be able to store Strategys" do
    end
  end


  #################################################
  #
  #  C O U N T E R _ M E A S U R E S
  #
  describe CounterMeasures, "A counter/measurement DSL" do
    describe CounterMeasures::Event, "An event stats DSL" do
      before do
        class Temperature
          include CounterMeasures

          HEAT_WAVE_DAYS=10
          HOT_HIGH_TEMP=90
          COLD_LOW_TEMP=50

          events :hot_day, :cold_day, :heat_wave
          measures :daily_readings, :highs

          def reading(temp)
            daily_readings.add(temp)
          end

          def end_of_day
            highs.add(daily_readings.max)
            update_events
            daily_readings.reset
          end

          def hot_day?
            daily_readings.max >= HOT_HIGH_TEMP
          end

          def cold_day?
            daily_readings.min <= COLD_LOW_TEMP
          end

          def heat_wave?
            last_days_hot = hot_day.last(HEAT_WAVE_DAYS)
            last_days_hot.length == HEAT_WAVE_DAYS && last_days_hot.all?
          end
        end
      end

      it "should keep stats on hot and cold days" do
        f = Temperature.new
        really_hot_days = 17
        hot_days = 0
        cold_days = 0
        just_right = 0
        tues_temps = [47,54,75,74,75,74,78,74,75,74,53]
        tues_temps.each do |temp|
          f.reading(temp)
        end
        expect(f.daily_readings.count).must_equal(tues_temps.length)
        f.end_of_day; cold_days += 1

        really_hot_days.times do |i|
          f.daily_readings.add(87+i,84+i,95+i,84+i,60+i)
          f.end_of_day; hot_days += 1
        end
        f.daily_readings.add(57,64,85,89,87)
        f.end_of_day; just_right += 1
        f.daily_readings.add(27,34,45,39,30)
        f.end_of_day; cold_days += 1
        total_days = hot_days + cold_days + just_right

        expect(f.cold_day.passed).must_equal(cold_days)
        expect(f.cold_day.count).must_equal(total_days)
        expect(f.hot_day.passed).must_equal(hot_days)
        expect(f.hot_day.failed).must_equal(cold_days + just_right)
        expect(f.hot_day.count).must_equal(total_days)
        expect(f.heat_wave.passed).must_equal(really_hot_days - Temperature::HEAT_WAVE_DAYS + 1)
        f.reset_events
        expect(f.cold_day.passed).must_equal(0)
        expect(f.hot_day.passed).must_equal(0)
      end
    end

    describe CounterMeasures::Counter, "A counter DSL" do
      before do
        class Foo
          include CounterMeasures
          counters :a, :b, :c
        end
        @f = Foo.new
      end

      it "should allow named counter access" do
        expect(@f.a.count).must_equal 0
        expect(@f.b.count).must_equal 0
        expect(@f.c.count).must_equal 0
      end

      it "should allow increment function" do
        @inc = 5
        @inc.times {@f.a.incr}
        expect(@f.a.count).must_equal @inc
      end

      it "should allow decrement function" do
        @inc = 10
        @inc.times {@f.c.incr}
        expect(@f.c.count).must_equal @inc
        @dec = 2
        @dec.times { @f.c.decr}
        expect(@f.c.count).must_equal @inc - @dec
      end

      it "should support a reset for one counter" do 
        @inc = 10
        @inc.times {@f.b.incr}
        @f.a.incr
        expect(@f.a.count).must_equal 1
        expect(@f.b.count).must_equal @inc
        @f.b.reset
        expect(@f.b.count).must_equal 0
        expect(@f.a.count).must_equal 1
      end

      it "should support a reset for all counters" do 
        @inc = 5
        @inc.times {@f.a.incr; @f.b.incr; @f.c.incr}
        expect(@f.a.count).must_equal @inc
        expect(@f.b.count).must_equal @inc
        expect(@f.c.count).must_equal @inc
        @f.reset_counters
        expect(@f.a.count).must_equal 0
        expect(@f.b.count).must_equal 0
        expect(@f.c.count).must_equal 0
      end

      it "should allow access to all counters as a copied hash but frozen" do
        @inc = 9
        @inc.times {@f.a.incr; @f.b.incr; @f.c.incr}
        expect(@f.a.count).must_equal @inc
        expect(@f.b.count).must_equal @inc
        expect(@f.c.count).must_equal @inc
        c = @f.counters
        expect(c[:a]).must_equal @inc
        expect(c[:b]).must_equal @inc
        expect(c[:c]).must_equal @inc

        expect(proc {c[:c] += 1}).must_raise RuntimeError
      end

      it "should act like a rising and falling quantity, with high and low watermarks" do
        @f.a.set(10000)
        @f.a.add(50)
        @f.a.add(50)
        @f.a.add(100)
        @f.a.add(1000)
        @f.a.sub(5000)
        expect(@f.a.count).must_equal(10000+50+50+100+1000-5000)
        expect(@f.a.high).must_equal(10000+50+50+100+1000)
        expect(@f.a.low).must_equal(10000+50+50+100+1000-5000)
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
        expect(@w.rainy_days.count).must_equal 4
        expect(@w.sunny_days.count).must_equal 1

        readings = [2,1,3,1]
        readings.each do |inches_of_rain|
          @w.rainfall.incr(inches_of_rain)
        end
        @w.rainfall.commit
        first_reading = @w.rainfall.total
        readings2 = [4,2,0]
        @w.rainfall.add(*readings2)
        expect(@w.rainfall.total).must_be :==, readings.reduce(:+) + readings2.reduce(:+)
        expect(@w.rainfall.count).must_equal 4
        expect(@w.rainfall.last).must_equal(0)
        expect(@w.rainfall.last(3)).must_equal(readings2)
        expect(@w.rainfall.last(4)).must_equal([first_reading] + readings2)
        @w.reset_measures
        expect(@w.rainfall.count).must_equal 0
      end
    end
  end



  #################################################
  #
  #  D E A L E R
  #
  describe Dealer, "A Blackjack Dealer" do
    before do
      @bet_amount = 50
      @table = Table.new('table_1',
        dealer_hits_soft_17: true,
        shoe: TestShoe.new(
          ["AC", "6D"],
          [
            ['AH', '4D']
          ]
        ))
      @player = Player.new('dave')
      @player.join(@table)
      @player.make_bet(@bet_amount)
      @dealer = @table.dealer
      @table.shoe.shuffle
      @table.shoe.place_marker_card
    end
 
    it "should hit when table config says hit soft 17" do
      @dealer.deal_one_card_face_up_to_each_active_bet_box
      @dealer.deal_up_card
      @dealer.deal_one_card_face_up_to_each_active_bet_box
      @dealer.deal_hole_card
      expect(@dealer.hit?).must_equal(true)
    end
  end

  describe Dealer, "A Blackjack Dealer" do
    before do
      @bet_amount = 50
      @table = Table.new('table_1',
        dealer_hits_soft_17: false,
        shoe: TestShoe.new(
          ["AC", "6D"],
          [
            ['AH', '4D']
          ]
        ))
      @player = Player.new('dave')
      @player.join(@table)
      @player.make_bet(@bet_amount)
      @dealer = @table.dealer
      @table.shoe.shuffle
      @table.shoe.place_marker_card
    end
 
    it "should not hit when table config says do not hit soft 17" do
      @dealer.deal_one_card_face_up_to_each_active_bet_box
      @dealer.deal_up_card
      @dealer.deal_one_card_face_up_to_each_active_bet_box
      @dealer.deal_hole_card
      expect(@dealer.hit?).must_equal(false)
    end
  end

  describe Dealer, "A Blackjack Dealer" do
    before do
      @bet_amount = 50
      @table = Table.new('table_1',
        dealer_hits_soft_17: true,
        shoe: TestShoe.new(
          ["KC", "7D"],
          [
            ['AH', '4D']
          ]
        ))
      @player = Player.new('dave')
      @player.join(@table)
      @player.make_bet(@bet_amount)
      @dealer = @table.dealer
      @table.shoe.shuffle
      @table.shoe.place_marker_card
    end
 
    it "should stand hard 17 when table config says hit soft 17" do
      @dealer.deal_one_card_face_up_to_each_active_bet_box
      @dealer.deal_up_card
      @dealer.deal_one_card_face_up_to_each_active_bet_box
      @dealer.deal_hole_card
      expect(@dealer.hit?).must_equal(false)
    end
  end

  describe Dealer, "A Blackjack Dealer" do
    before do
      @bet_amount = 50
      @table = Table.new('table_1',
        dealer_hits_soft_17: false,
        shoe: TestShoe.new(
          ["AD", "7D"],
          [
            ['AH', '4D']
          ]
        ))
      @player = Player.new('dave')
      @player.join(@table)
      @player.make_bet(@bet_amount)
      @dealer = @table.dealer
      @table.shoe.shuffle
      @table.shoe.place_marker_card
    end
 
    it "should stand hard 18" do
      @dealer.deal_one_card_face_up_to_each_active_bet_box
      @dealer.deal_up_card
      @dealer.deal_one_card_face_up_to_each_active_bet_box
      @dealer.deal_hole_card
      expect(@dealer.hit?).must_equal(false)
    end
  end

  describe Dealer, "A Blackjack Dealer" do
    before do
      @bet_amount = 50
      @table = Table.new('table_1',
        shoe: TestShoe.new(
          ["AC", "5D"],
          [
            ['9H', '7C'],
            ['7H', 'KC'],
            ['AH', '4D']
          ],
          ['9D','6C','KD', '4H']
        ))
      @players = %w{dave cortney erica}.inject([]) do |p, n|
        player = Player.new(n)
        player.join(@table)
        player.make_bet(@bet_amount)
        p << player
      end
      @dealer = @table.dealer
      @table.shoe.shuffle
      @table.shoe.place_marker_card
    end

    it "should automate playing of hand" do
      @dealer.deal_one_card_face_up_to_each_active_bet_box
      @dealer.deal_up_card
      @dealer.deal_one_card_face_up_to_each_active_bet_box
      @dealer.deal_hole_card
      @dealer.deal_card_face_up_to(@players[0].default_bet_box)
      @dealer.deal_card_face_up_to(@players[2].default_bet_box)
      @dealer.flip_hole_card
      @dealer.play_hand
      expect(@dealer.hand.inspect).must_equal("[AC, 5D, KD, 4H]")
      expect(@dealer.hand.hard_sum).must_equal(20)
      expect(@dealer.hand.length).must_equal(4)
      @dealer.discard_hand
      expect(@dealer.hand.length).must_equal(0)
    end

    it "should collect bets" do
      sb = @table.house.balance
      p = @players[0]
      expect(p.default_bet_box.bet_amount).must_equal(@bet_amount)
      @dealer.money.collect_bet(p.default_bet_box)
      expect(p.default_bet_box.bet_amount).must_equal(0)
      expect(@table.house.balance).must_equal(sb + @bet_amount)
    end

    it "should pay winnings" do
      p = @players[0]
      sb = @table.house.balance
      sp = p.default_bet_box.bet_amount
      expect(p.default_bet_box.bet_amount).must_equal(@bet_amount)
      @dealer.money.pay_bet(p.default_bet_box, [7,2])
      payout = (@bet_amount / 2) * 7
      expect(p.default_bet_box.bet_amount).must_equal(sp + payout)
      expect(@table.house.balance).must_equal(sb - payout)
    end

    it "should deal hands to players with bets made" do
      num_cards_before_deal = @table.shoe.decks.length
      @dealer.deal_one_card_face_up_to_each_active_bet_box
      @dealer.deal_up_card
      @dealer.deal_one_card_face_up_to_each_active_bet_box
      @dealer.deal_hole_card
      expect(@table.shoe.decks.length).must_equal(num_cards_before_deal - ((@players.length*2) + 2))
      expect(@players[0].default_bet_box.hand.inspect).must_equal("[9H, 7C]")
      expect(@players[1].default_bet_box.hand.inspect).must_equal("[7H, KC]")
      expect(@players[2].default_bet_box.hand.inspect).must_equal("[AH, 4D]")
      expect(@dealer.hand.inspect).must_equal("[AC, XX]")
      @players.each do |p|
        expect(@dealer.check_player_hand_busted?(p.default_bet_box)).must_equal(false)
      end
      expect(@dealer.hole_card.face_down?).must_equal true
      @dealer.flip_hole_card
      expect(@dealer.up_card.face_up?).must_equal true
      expect(@dealer.hand.inspect).must_equal("[AC, 5D]")
      expect(@dealer.hole_card.face_down?).must_equal false
      @dealer.deal_card_face_up_to(@players[0].default_bet_box)
      expect(@players[0].default_bet_box.hand.inspect).must_equal("[9H, 7C, 9D]")
      expect(@dealer.check_player_hand_busted?(@players[0].default_bet_box)).must_equal(true)
      @dealer.deal_card_face_up_to(@players[2].default_bet_box)
      expect(@players[2].default_bet_box.hand.inspect).must_equal("[AH, 4D, 6C]")
      expect(@dealer.hit?).must_equal(true)
      @dealer.deal_card_to_hand
      expect(@dealer.hand.inspect).must_equal("[AC, 5D, KD]")
      expect(@dealer.hit?).must_equal(true)
      @dealer.deal_card_to_hand
      expect(@dealer.hand.inspect).must_equal("[AC, 5D, KD, 4H]")
      expect(@dealer.hand.hard_sum).must_equal(20)
      expect(@dealer.hit?).must_equal(false)
      expect(@dealer.busted?).must_equal(false)
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
      expect(@table.name).must_equal @table_name  
    end

    it "should have seats where players join" do
      expect(@table.seated_players).wont_equal nil
    end

    it "should have bet boxes" do
      expect(@table.bet_boxes).wont_equal nil
    end

    it "should have a dealer" do
      expect(@table.dealer).wont_equal nil
    end

    it "should default to a SixDeckShoe if none is passed in" do
      expect(@table.shoe.class.name).must_equal "Blackjack::SixDeckShoe"
    end

    it "should support default configuration" do 
      expect(@table.config[:blackjack_payout]).must_equal [3,2]
      expect(@table.config[:dealer_hits_soft_17]).must_equal false
      expect(@table.config[:player_surrender]).must_equal false
      expect(@table.config[:num_seats]).must_equal 6
      expect(@table.config[:minimum_bet]).must_equal 25
      expect(@table.config[:maximum_bet]).must_equal 5000
      expect(@table.config[:double_down_on]).must_equal []
      expect(@table.config[:max_player_splits]).must_equal 3
      expect(@table.config[:max_player_bets]).must_equal 3
    end

    it "should support options for configuration" do

      @configuration = {
        blackjack_payout: [6,5],
        dealer_hits_soft_17: true,
        shoe_class: OneDeckShoe,
        num_seats: 4
      }

      @configured_table = Table.new("configured_table", @configuration)
      @configuration.keys.each do |item|
        expect(@configured_table.config[item]).must_equal @configuration[item]
      end
    end

    it "should allow a player to join the table and find them an open seat" do
      @player = MiniTest::Mock.new
      @player.expect(:name, "fugdup", [])
      seat_position = @table.join(@player)
      expect(seat_position).must_be :>=, 0
      expect(seat_position).must_be :<, @table.config[:num_seats]
      @player.verify
    end

    it "should allow respond true to any_seated_players? when a player is seated" do 
      @player = MiniTest::Mock.new
      @player.expect(:name, "fugdup", [])
      seat_position = @table.join(@player)
      expect(seat_position).must_be :>=, 0
      expect(seat_position).must_be :<, @table.config[:num_seats]
      expect(@table.any_seated_players?).must_equal(true)
      @player.verify
    end

    it "should allow respond false to any_seated_players? when table is empty" do 
      expect(@table.any_seated_players?).must_equal(false)
    end

    it "should increment the players_seated counter when a player joins" do
      expect(@table.stats.players_seated.count).must_equal 0
      @player = MiniTest::Mock.new
      @player.expect(:name, "fugdup", [])
      seat_position = @table.join(@player)
      expect(@table.stats.players_seated.count).must_equal 1
      @player.verify
    end

    it "should auto-fill the table right to left" do
      (0..(@table.config[:num_seats]-1)).each do |i|
        player = Player.new("player_#{i}")
        seat_position = @table.join(player)
        expect(seat_position).must_equal i
      end
    end

    it "should allow a player to join the table at the empty seat of the players choice" do
      @player = MiniTest::Mock.new
      @player.expect(:name, "fugdup", [])
      @fav_seat = @table.config[:num_seats]-1
      seat_position = @table.join(@player, @fav_seat)
      expect(seat_position).must_equal @fav_seat
    end

    it "should allow a player to leave the table" do
      @player = Player.new('ted2')
      seat_position = @table.join(@player)
      expect(seat_position).must_be :>=, 0
      expect(seat_position).must_be :<, @table.config[:num_seats]
      @table.leave(@player)
      assert_nil @player.table
      expect(@table.seated_players.all?(&:nil?)).must_equal true
    end

    it "should allow a player to inquire his/her seat position at the table" do
      @fav_seat = 4
      @player = Player.new('ted2')
      seat_position = @table.join(@player, @fav_seat)
      expect(@table.seat_position(@player)).must_equal @fav_seat
    end

    it "should provide the player way to reach their designated bet_box" do
      @fav_seat = 4
      @player = Player.new('ted4')
      seat_position = @table.join(@player, @fav_seat)
      expect(@table.bet_boxes.dedicated_to(@player)).must_equal(@table.bet_boxes[@fav_seat])
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
        expect(bet_box).must_equal(expected_results.next)
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
        expect(bet_box).must_equal(expected_results.next)
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
        expect(bet_box).must_equal(expected_results.next)
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
        expect(bet_box).must_equal(expected_results.next)
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
        expect(bet_box).must_equal(expected_results.next)
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
        expect(bet_box).must_equal(expected_results.next)
      end
    end

    it "should provide the last position player way to reach adjacent, available bet_boxes for multi-bet play" do
      @fav_seat = @table.config[:num_seats]-1
      @player = Player.new('tedlast')
      seat_position = @table.join(@player, @fav_seat)
      expected_results = [
        @table.bet_boxes[@fav_seat],
        @table.bet_boxes[@fav_seat-1],
        @table.bet_boxes[@fav_seat-2]
      ].each
      @table.bet_boxes.available_for(@player) do |bet_box|
        expect(bet_box).must_equal(expected_results.next)
      end
    end

    it "should not assign a seat to a player when all the seats are full" do
      (0..(@table.config[:num_seats]-1)).each do |i|
        player = Player.new("player_#{i}")
        seat_position = @table.join(player)
        expect(seat_position).must_equal i
      end
      @player = Player.new('machvee')
      expect(proc {@table.join(@player)}).must_raise RuntimeError
    end

    it "should not allow a player to take a specified seat if that seat is filled" do
      @player = Player.new("bubba")
      @bubbas_fav_seat = @table.config[:num_seats]-1
      seat_position = @table.join(@player, @bubbas_fav_seat)
      expect(seat_position).must_equal @bubbas_fav_seat
      @player = Player.new("machvee")
      expect(proc {@table.join(@player, @bubbas_fav_seat)}).must_raise RuntimeError
    end

    it "should allow people to ask if a specific seat is available, and return true if it is" do
      expect(@table.seat_available?(2)).must_equal true
    end

    it "should allow people to ask if ANY seat is available, and return true if it is" do
      expect(@table.seat_available?).must_equal true
    end

    it "should allow people to ask if ANY seat is available, and return false when all taken" do
      (0..(@table.config[:num_seats]-1)).each do |i|
        player = Player.new("player_#{i}")
        seat_position = @table.join(player)
        expect(seat_position).must_equal i
      end
      expect(@table.seat_available?).must_equal false
    end

    it "should allow people to ask if a specific seat is available, and return false if not" do
      @player = Player.new("bubba")
      @bubbas_fav_seat = @table.config[:num_seats]-1
      seat_position = @table.join(@player, @bubbas_fav_seat)
      expect(seat_position).must_equal @bubbas_fav_seat
      expect(@table.seat_available?(@bubbas_fav_seat)).must_equal false
    end

    it "should allow use of the game play class with many players" do
      class TestStrategy < PlayerHandStrategy
        def num_hands
          1
        end

        def stay?
          Action::PLAY
        end

        def insurance?(bet_box)
          bet_box.hand.blackjack? ? Action::EVEN_MONEY : Action::NO_INSURANCE
        end

        def bet_amount
          25
        end
      end
      names = %w{dave davey katie vader cass erica}
      players = names.map {|n| Player.new(n, strategy_class: TestStrategy)}
      players.each {|p| p.join(@table)}
      expect(@table.num_players).must_equal(names.length)
      gp = GamePlay.new(@table)
      gp.players_make_bets
      gp.shuffle_check
      gp.opening_deal
      @table.bet_boxes.each_active do |bb|
        expect(bb.box.balance).must_equal(25)
        expect(bb.hand.length).must_equal(2)
        expect(bb.hand[0].face_up?).must_equal(true)
        expect(bb.hand[1].face_up?).must_equal(true)
      end
      expect(@table.dealer.up_card.face_up?).must_equal(true)
      expect(@table.dealer.hole_card.face_down?).must_equal(true)
    end
  end

  describe GamePlay, "A full hand dealt with a split" do
    before do
      shoe = TestShoe.new(
          ["2H", "5C"], # dealer hand
          [
            ['3C', '3H'] #player hand
          ],
          # player splits 3's
          # player is dealt 3,K stands.
          # player is dealt 3,9and hits, gets 5, and STANDS with 17
          # Dealer HITS and gets Q for 17 STANDS
          ['KH', '9D', '5D', 'QH']
      )
      @table_options = {
        shoe: shoe,
        minimum_bet: 10,
        maximum_bet: 2000,
      }

      @player_options = {
        strategy_class: BasicStrategy,
        strategy_options: {num_rounds: 1}
      }
    end

    it "should play a single hand, dealing one split to player" do
      @table = Table.new("test3", @table_options)
      @dave = Player.new("Dave", @player_options)
      @dave.join(@table)
      @game_play = GamePlay.new(@table)
      @game_play.run
    end
  end

  describe GamePlay, "A full hand dealt with multiple splits" do
    before do
      shoe = TestShoe.new(
          ["2H", "5C"], # dealer hand
          [
            ['3C', '3H'] #player hand SPLIT against deals 2 upcard (rule pairs:2:3 push=1 won=1 lost=1)
          ],
          # split hand 1: player is dealt 3,5,9, stand on 17 (rule hard:2:17)
          # split hand 2: player is dealt 3,3 SPLITs again (rule pairs:2:3 (2) won=1 lost=1)
          # player is dealt 3,9,8 STANDS 20 (rule hard:2:20 won=1)
          # player is dealt 3,Q STANDS 13 (rule hard:2:13 lost=1)
          # Dealer HITS Q for 17 STANDS
          ['5D', '9D', '3D', '9H', '8H', 'QD', 'QH']
      )
      @expected_rules_count = 6
      @table_options = {
        shoe: shoe,
        minimum_bet: 10,
        maximum_bet: 2000,
        game_announcer_class: StdoutGameAnnouncer # test only DELETE ME
      }

      @player_options = {
        strategy_class: BasicStrategy,
        strategy_options: {num_rounds: 1}
      }
    end

    it "should play a single hand, dealing one split to player" do
      @table = Table.new("test3", @table_options)
      @dave = Player.new("Dave", @player_options)
      @dave.join(@table)
      @game_play = GamePlay.new(@table)
      @game_play.run
      @dave.print_rules
      expect(@dave.stats.split_stats.played.count).must_equal(3)
      expect(@dave.stats.split_stats.won.count).must_equal(1)
      expect(@dave.stats.split_stats.lost.count).must_equal(1)
      expect(@dave.stats.split_stats.pushed.count).must_equal(1)
      expect(@dave.rules_used.count).must_equal(@expected_rules_count)
    end
  end

  describe GamePlay, "A game execution service class" do
    before do
      shoe = TestShoe.new(
          ["2H", "5C"],
          [
            ['3C', '3H']
          ],
          ['KH', '9D', 'QH']
      )
      @table = Table.new('test', shoe: shoe)
      @table.shoe.shuffle
      @table.shoe.place_marker_card
      @player = Player.new('p', start_bank: 5000)
      @player.join(@table)
      @player.make_bet(50)
      @game_play = GamePlay.new(@table)
      @game_play.opening_deal
    end

    it "should play correctly for players who have split their hand" do
      expect(@player.default_bet_box.hand.hard_sum).must_equal(6)
      @player.default_bet_box.split
      vals = [13,12].each
      @table.bet_boxes.each_active do |bb|
        @table.dealer.deal_card_face_up_to(bb)
        expect(bb.hand.hard_sum).must_equal(vals.next)
      end

      @table.bet_boxes.each_active do |bb|
        next if bb.hand.hard_sum == 13
        @table.dealer.deal_card_face_up_to(bb)
        expect(bb.hand.hard_sum).must_equal(22)
        @table.dealer.money.collect_bet(bb)
        bb.discard
      end

      @table.dealer.flip_hole_card

      @game_play.pay_any_winners
    end
  end

  describe GamePlay, "When player has blackjack and dealer has 10 upcard, A in hole" do
    before do
      shoe = TestShoe.new(
          ["JH", "AC"],
          [
            ['AD', '10H']
          ],
          []
      )
      @table = Table.new('test', shoe: shoe)
      @table.shoe.shuffle
      @table.shoe.place_marker_card
      @player_options = {
        strategy_class: BasicStrategy,
        strategy_options: {num_rounds: 1}
      }
      @player = Player.new('p', @player_options)
      @player.join(@table)
      @player.make_bet(50)
      @game_play = GamePlay.new(@table)
      expect(@player.stats.hand_stats.pushed.count).must_equal(0)
      @game_play.run
    end

    it "should be a player push" do
      expect(@player.stats.hand_stats.pushed.count).must_equal(1)
    end
  end

  describe BetBox, "A BetBox" do
    before do
      @position = 0
      @table = Table.new('bet_box_test_table')
      @table.shoe.shuffle
      @table.shoe.place_marker_card
      @player = Player.new('dave')
      @player.join(@table, @position)
      @bet_box = @table.bet_boxes[@position]
      @bet_box_empty = @table.bet_boxes[@position+1]
    end

    it "should be dedicated? because a player sits in front of it" do
      expect(@bet_box.dedicated?).must_equal(true)
    end

    it "should not be dedicated? because no player sits in front of it" do
      expect(@bet_box_empty.dedicated?).must_equal(false)
    end

    it "must not be available? because its dedicated" do
      expect(@bet_box.available?).must_equal(false)
    end

    it "must be available? because its not dedicated" do
      expect(@bet_box_empty.available?).must_equal(true)
    end

    it "is not active yet because no bet" do
      expect(@bet_box.active?).must_equal(false)
    end

    it "is active when a player has made a bet" do
      @player.make_bet(50, @bet_box)
      expect(@bet_box.active?).must_equal(true)
    end

    it "lets a player take insurance bet winnings" do
      bet_amt = 50
      ins_bet = bet_amt/2
      @bet_box.bet(@player, bet_amt)
      @bet_box.insurance_bet(ins_bet)
      @bet_box.insurance.credit(ins_bet*2) # winnings 2-1
      ins_winnings = @bet_box.insurance_bet_amount
      player_balance = @player.bank.balance
      @bet_box.take_insurance
      expect(@player.bank.balance).must_equal(player_balance + ins_winnings)
      expect(@bet_box.insurance.balance).must_equal(0)
    end

    it "lets a player make an insurance bet" do
      bet_amt = 50
      @bet_box.bet(@player, bet_amt)
      @bet_box.insurance_bet(bet_amt/2)
      expect(@bet_box.insurance.balance).must_equal(bet_amt/2)
    end

    it "supports bet making" do
      start_bank = @player.bank.balance
      bet_amt = 50
      @bet_box.bet(@player, bet_amt)
      expect(@bet_box.active?).must_equal(true)
      expect(@player.bank.balance).must_equal(start_bank-bet_amt)
    end

    it "lets the player win a bet" do
      start_bank = @player.bank.balance
      bet_amt = 50
      @player.make_bet(bet_amt)
      @bet_box.box.credit(bet_amt)
      @player.won_bet(@bet_box, bet_amt)
      expect(@bet_box.box.balance).must_equal(0)
      expect(@player.bank.balance).must_equal(start_bank + bet_amt)
    end

    it "allows a player to split the hand" do
      bet_amt = 50
      @player.make_bet(bet_amt)
      @player.default_bet_box.hand.set(BlackjackCard.make('8D', '8H'))
      @bet_box.split
      expect(@bet_box.split?).must_equal(true) # this hand was split
      expect(@bet_box.num_splits).must_equal(1)
      @bet_box.split_boxes.each do |bet_box|
        expect(bet_box.active?).must_equal(true)
        expect(bet_box.hand.hard_sum).must_equal(8)
        bet_box.hand.set(BlackjackCard.make('8D', '8S'))
        expect(bet_box.from_split?).must_equal(true) # this hand came from a split
        bet_box.split # split the split hand again
      end
      expect(@bet_box.num_splits).must_equal(3)
      counter = 0
      @table.bet_boxes.each_active do |bet_box|
        counter +=1
      end
      expect(counter).must_equal(4)
      @table.bet_boxes.each_active do |bet_box|
        #
        # attempt to split the again should exceed table limit
        #
        bet_box.hand.set(BlackjackCard.make('8D', '8S'))
        assert !bet_box.can_split?, "shouldn't be able to split"
        expect(proc {
          bet_box.split
        }).must_raise RuntimeError
        break
      end
    end
  end

  describe BetBox, "A BetBox with a doublable Hand in play" do
    before do
      @position = 0
      @dbl_on = [] # any hand doubleable
      shoe = TestShoe.new(
          ["3H", "3C"],
          [
            ['9C', '2H']
          ],
          ['KH', '9D', 'QH']
      )
      @table = Table.new('test', shoe: shoe, double_down_on: @dbl_on)
      @table.shoe.shuffle
      @table.shoe.place_marker_card
      @player = Player.new('p', start_bank: 5000)
      @player.join(@table, @position)
      @bet_box = @table.bet_boxes[@position]
      @player.make_bet(50)
      @game_play = GamePlay.new(@table)
      @game_play.opening_deal
    end

    it "responds correctly to can_double? when the hand is doublable" do
      expect(@bet_box.can_double?).must_equal(true)
    end

    it "responds correctly to can_double? when the hand has more than 2 cards" do
      @table.dealer.deal_card_face_up_to(@bet_box)
      expect(@bet_box.can_double?).must_equal(false)
    end
  end

  describe BetBox, "A BetBox with a no doublable Hand in play" do
    before do
      @position = 0
      @dbl_on = [10,11] # only 10 and 11 are doublable
      shoe = TestShoe.new(
          ["9H", "3C"],
          [
            ['3C', '6H']
          ],
          ['KH', '9D', 'QH']
      )
      @table = Table.new('test', shoe: shoe, double_down_on: @dbl_on)
      @table.shoe.shuffle
      @table.shoe.place_marker_card
      @player = Player.new('p', start_bank: 5000)
      @player.join(@table, @position)
      @bet_box = @table.bet_boxes[@position]
      @player.make_bet(50)
      @game_play = GamePlay.new(@table)
      @game_play.opening_deal
    end

    it "responds correctly to can_double? when the hand is not doublable" do
      expect(@bet_box.can_double?).must_equal(false)
    end
  end

  describe Markers, "A Player" do
    before do
      @table = Table.new('test')
      @player = Player.new(@name='dave')
    end

    it "should allow a player to borrow" do
      @player.join(@table)
      expect(@player.bank.balance).must_equal(500)
      @player.marker_for(500)
      expect(@player.bank.balance).must_equal(500+500)
    end

    it "should allow a player to repay what they've borrowed" do
      @player.join(@table)
      expect(@player.bank.balance).must_equal(500)
      @player.marker_for(500)
      expect(@player.bank.balance).must_equal(500+500)
      @player.repay_any_markers(500)
      expect(@player.bank.balance).must_equal(500)
      @table.markers.for_player(@player).length == 0
    end

    it "should allow a player to repay an amount less than they've borrowed" do
      @player.join(@table)
      expect(@player.bank.balance).must_equal(500)
      @player.marker_for(500)
      expect(@player.bank.balance).must_equal(500+500)
      @player.repay_any_markers(250)
      expect(@table.markers.for_player(@player).first[:amount]).must_equal(500-250)
      expect(@player.bank.balance).must_equal(500+500-250)
    end

    it "should raise if player attempts to pay back more than their bank balance" do
      @player.join(@table)
      expect(@player.bank.balance).must_equal(500)
      @player.marker_for(500)
      expect(@player.bank.balance).must_equal(500+500)
      expect(proc {
        @player.repay_any_markers(1250)
      }).must_raise RuntimeError
    end
  end

  describe Player, "A Player" do
    before do
      @player = Player.new(@name='dave')
    end

    it "should have a name" do
      expect(@player.name).must_equal(@name)
    end

    it "should have an initial zero balance bank" do
      expect(@player.bank.balance).must_equal 0
    end

    it "should be able to join a table" do
      @table = Table.new('t')
      @player.join(@table)
      expect(@table.find_player(@player.name)).must_equal(@player)
    end

    it "should be able to join a table at a specific seat position" do
      @table = Table.new('t')
      @seat = 3
      @player.join(@table, @seat)
      expect(@table.seat_position(@player)).must_equal(@seat)
    end

    it "should be able to join, then leave a table" do
      @table = Table.new('t')
      @player.join(@table)
      expect(@table.find_player(@player.name)).must_equal(@player)
      @player.leave_table
      assert_nil @table.find_player(@player.name)
    end

    it "should be able to make a bet" do
      bet_amt = 50
      table = Table.new('player_table')
      @player.join(table)
      @player.make_bet(bet_amt)
      expect(@player.default_bet_box.bet_amount).must_equal(bet_amt)
    end

    it "should be able to win a bet" do
    end

    it "should be able to lose a bet" do
    end

  end

  describe Bank, "A money account" do
    before do
      @initial_balance = 3833
      @bank1 = Bank.new(@initial_balance)
      @bank2 = Bank.new(@initial_balance)
    end

    it "should have initial balances" do
      expect(@bank1.balance).must_equal(@initial_balance)
      expect(@bank2.balance).must_equal(@initial_balance)
    end

    it "should allow direct credit and debiting" do
      amount_to_credit = 91
      amount_to_debit = 83
      @bank1.credit(amount_to_credit)
      expect(@bank1.balance).must_equal(@initial_balance + amount_to_credit)
      expect(@bank1.credits.count).must_equal(1)
      @bank2.debit(amount_to_debit)
      expect(@bank2.balance).must_equal(@initial_balance - amount_to_debit)
      expect(@bank2.debits.count).must_equal(1)
    end

    it "should allow a reset back to initial balance" do
      amount_to_credit = 91
      amount_to_debit = 83
      @bank1.credit(amount_to_credit)
      expect(@bank1.balance).must_equal(@initial_balance + amount_to_credit)
      expect(@bank1.credits.count).must_equal(1)
      @bank2.debit(amount_to_debit)
      expect(@bank2.balance).must_equal(@initial_balance - amount_to_debit)
      expect(@bank2.debits.count).must_equal(1)
      @bank1.reset
      @bank2.reset
      expect(@bank1.balance).must_equal(@initial_balance)
      expect(@bank2.balance).must_equal(@initial_balance)
      expect(@bank1.credits.count).must_equal(0)
      expect(@bank2.credits.count).must_equal(0)
      expect(@bank1.debits.count).must_equal(0)
      expect(@bank2.debits.count).must_equal(0)
    end

    it "should allow transfer_to another account" do
      amount_to_transfer = 382
      @bank1.transfer_to(@bank2, amount_to_transfer)
      expect(@bank1.balance).must_equal(@initial_balance - amount_to_transfer)
      expect(@bank2.balance).must_equal(@initial_balance + amount_to_transfer)
      expect(@bank1.credits.count).must_equal(0)
      expect(@bank1.debits.count).must_equal(1)
      expect(@bank2.credits.count).must_equal(1)
      expect(@bank2.debits.count).must_equal(0)
    end

    it "should allow transfer_from another account" do
      amount_to_transfer = 98
      @bank1.transfer_from(@bank2, amount_to_transfer)
      expect(@bank1.balance).must_equal(@initial_balance + amount_to_transfer)
      expect(@bank2.balance).must_equal(@initial_balance - amount_to_transfer)
      expect(@bank1.credits.count).must_equal(1)
      expect(@bank1.debits.count).must_equal(0)
      expect(@bank2.credits.count).must_equal(0)
      expect(@bank2.debits.count).must_equal(1)
    end

    it "should raise an exception if trying to debit below 0 balance" do
      @bank1.debit(@initial_balance) # ok
      expect(@bank1.balance).must_equal(0)
      expect(proc {
        @bank2.debit(@initial_balance+1)
      }).must_raise RuntimeError
      expect(@bank2.balance).must_equal(@initial_balance)
    end

    it "should keep min and max" do
      # debit 4 x 50 200, for a low_balance of @initial_deposit - 200
      @bank1.debit(50)
      @bank1.debit(50)
      @bank1.debit(50)
      @bank1.debit(50)
      # credit 5 x 100 for 500, for a high_balance of @initial_deposit - 200 + 500
      @bank1.credit(100)
      @bank1.credit(100)
      @bank1.credit(100)
      @bank1.credit(100)
      @bank1.credit(100)
      expect(@bank1.high_balance).must_equal(@initial_balance - 200 + 500)
      expect(@bank1.low_balance).must_equal(@initial_balance - 200)
    end
  end

  describe BlackjackCard, "A Card" do 
    before do
      @a_card = BlackjackCard.new('A', 'S')
    end

    it "should have validate inputs" do
      expect(proc { BlackjackCard.new('-', '*')}).must_raise RuntimeError
      expect(proc { BlackjackCard.new('*', '-')}).must_raise RuntimeError
    end

    it "should have a default orientation facing down" do
      expect(@a_card.face_down?).must_equal true
      expect(@a_card.face_up?).must_equal false
    end

    it "should allow the orientation to be set up" do
      expect(@a_card.face_up?).must_equal false
      @a_card.up
      expect(@a_card.face_up?).must_equal true
    end

    it "should allow the orientation to be set down" do
      @a_card.up
      expect(@a_card.face_up?).must_equal true
      @a_card.down
      expect(@a_card.face_up?).must_equal false
      expect(@a_card.face_down?).must_equal true
    end
  end

  describe BlackjackCard, "A single Blackjack Ace Card" do 
    before do
      @ace_spades = BlackjackCard.new('A', 'S')
    end

    it "should have 'A' as its value" do
      expect(@ace_spades.face).must_equal 'A'
      expect(@ace_spades.ace?).must_equal true
    end

    it "should have 'S' as its suit" do
      expect(@ace_spades.suit).must_equal 'S'
    end

    it "should have soft value of 1 for 'A'" do 
      expect(@ace_spades.face_value).must_equal 1
    end

    it "should have default face value of the soft value for 'A'" do 
      expect(@ace_spades.face_value).must_equal @ace_spades.soft_value
    end

    it "should have hard value of 11 for 'A'" do 
      expect(@ace_spades.hard_value).must_equal 11
    end
  end

  describe BlackjackCard, "A single Blackjack Face Card" do 
    before do
      @jack_clubs = BlackjackCard.new('J', 'C')
    end

    it "should have 'J' as its value" do
      expect(@jack_clubs.face).must_equal 'J'
    end

    it "should not be an ace" do
      expect(@jack_clubs.ace?).must_equal false
    end

    it "should have 'C' as its suit" do
      expect(@jack_clubs.suit).must_equal 'C'
    end

    it "should have 10 for its hard and soft values" do
      expect(@jack_clubs.face_value).must_equal 10
      expect(@jack_clubs.soft_value).must_equal 10
      expect(@jack_clubs.hard_value).must_equal 10
    end

    it "should respond to being a face_card?" do
      expect(@jack_clubs.face_card?).must_equal true
    end
  end

  describe BlackjackCard, "A deck of Blackjack Cards" do 

    before do
      @deck = BlackjackCard.deck
    end

    it "must have 52 cards" do
      expect(@deck.length).must_equal 52
    end

    it "must have all four suits" do
      expect(@deck.map(&:suit).uniq.length).must_equal 4
      expect(@deck.map(&:suit).uniq.sort).must_equal ['C', 'D', 'H', 'S']
    end

    it "must have all 13 cards in each suit" do
      @deck.group_by(&:suit).each_pair do |s, faces|
        expect(faces.map(&:face)).must_equal [*'2'..'9', '10', 'J', 'Q', 'K', 'A']
      end
    end
  end

  describe BlackjackHand, "A Hand of 8 8" do
    before do
      @eight_eight = BlackjackHand.make('8D', '8S')
    end

    it "should respond to pair" do
      expect(@eight_eight.pair?).must_equal true
    end

    it "should have a value of 16" do
      expect(@eight_eight.soft_sum).must_equal 16
    end

    it "should not be busted" do
      expect(@eight_eight.bust?).must_equal false
    end
  end

  describe BlackjackHand, "A Hand of 8 9" do
    before do
      @eight_nine = BlackjackHand.make('8D', '9S')
    end

    it "should not respond to pair" do
      expect(@eight_nine.pair?).must_equal false
    end

    it "should have a value of 17" do
      expect(@eight_nine.soft_sum).must_equal 17
    end

    it "should not be busted" do
      expect(@eight_nine.bust?).must_equal false
    end

    it "should not has_ace?" do
      expect(@eight_nine.has_ace?).must_equal false
    end
  end

  describe BlackjackHand, "A Hand of J Q" do
    before do
      @jack_q = BlackjackHand.make('JD', 'QS')
    end

    it "should respond to pair" do
      expect(@jack_q.pair?).must_equal false
    end

    it "should have a value of 20" do
      expect(@jack_q.soft_sum).must_equal 20
      expect(@jack_q.hard_sum).must_equal 20
    end

    it "should not be busted" do
      expect(@jack_q.bust?).must_equal false
    end

    it "should not has_ace?" do
      expect(@jack_q.has_ace?).must_equal false
    end
  end

  describe BlackjackHand, "A Hand of K 10" do
    before do
      @k_10 = BlackjackHand.make('KD', '10S')
    end

    it "should respond to pair" do
      expect(@k_10.pair?).must_equal false
    end

    it "should have a value of 20" do
      expect(@k_10.soft_sum).must_equal 20
      expect(@k_10.hard_sum).must_equal 20
    end

    it "should not be busted" do
      expect(@k_10.bust?).must_equal false
    end

    it "should not be blackjack?" do
      expect(@k_10.blackjack?).must_equal false
    end

    it "should not has_ace?" do
      expect(@k_10.has_ace?).must_equal false
    end
  end

  describe BlackjackHand, "A Hand of K K" do
    before do
      @k_k = BlackjackHand.make('KD', 'KS')
    end

    it "should respond to pair" do
      expect(@k_k.pair?).must_equal true
    end

    it "should have a value of 20" do
      expect(@k_k.soft_sum).must_equal 20
      expect(@k_k.hard_sum).must_equal 20
    end

    it "should not be busted" do
      expect(@k_k.bust?).must_equal false
    end

    it "should not be blackjack?" do
      expect(@k_k.blackjack?).must_equal false
    end

    it "should not has_ace?" do
      expect(@k_k.has_ace?).must_equal false
    end
  end

  describe BlackjackHand, "A Hand of A Q" do
    before do
      @blackjack = BlackjackHand.make('AD', 'QS')
    end

    it "should not respond to pair" do
      expect(@blackjack.pair?).must_equal false
    end

    it "should have a hard value of 21" do
      expect(@blackjack.hard_sum).must_equal 21
    end

    it "should have a soft value of 11" do
      expect(@blackjack.soft_sum).must_equal 11
    end

    it "should not be busted" do
      expect(@blackjack.bust?).must_equal false
    end

    it "should be blackjack?" do
      expect(@blackjack.blackjack?).must_equal true
    end

    it "should respond true to has_ace?" do
      expect(@blackjack.has_ace?).must_equal true
    end

    it "should be soft?" do
      expect(@blackjack.soft?).must_equal true
    end
  end


  describe BlackjackHand, "A hand that has multiple aces" do
    before do
      @hand = BlackjackHand.make('AD', 'AC', 'AH', 'AS', '2S', '2D', '3H')
    end

    it "should not respond to pair" do
      expect(@hand.pair?).must_equal false
    end

    it "should have a hard value of 21" do
      expect(@hand.hard_sum).must_equal 21
    end

    it "should have a soft value of 11" do
      expect(@hand.soft_sum).must_equal 11
    end

    it "should not be busted" do
      expect(@hand.bust?).must_equal false
    end

    it "should not be blackjack?" do
      expect(@hand.blackjack?).must_equal false
    end

    it "should respond true to has_ace?" do
      expect(@hand.has_ace?).must_equal true
    end

    it "should be soft?" do
      expect(@hand.soft?).must_equal true
    end
  end

  describe BlackjackHand, "A hand that has an aces and is more than 21" do
    before do
      @hand = BlackjackHand.make('AD', '4C', '9S', 'QD')
    end

    it "should not respond to pair" do
      expect(@hand.pair?).must_equal false
    end

    it "should have a hard value of 24" do
      expect(@hand.hard_sum).must_equal 24
    end

    it "should have a soft value of hard value when the soft_value is a bust" do
      expect(@hand.soft_sum).must_equal 24
    end

    it "should be busted" do
      expect(@hand.bust?).must_equal true
    end

    it "should not be blackjack?" do
      expect(@hand.blackjack?).must_equal false
    end

    it "should respond true to has_ace?" do
      expect(@hand.has_ace?).must_equal true
    end

    it "should be soft?" do
      expect(@hand.soft?).must_equal true
    end
  end


  describe BlackjackHand, "A hand that has an no aces and is more than 21" do
    before do
      @hand = BlackjackHand.make('4D', '5C', '6S', 'QD')
    end

    it "should not respond to pair" do
      expect(@hand.pair?).must_equal false
    end

    it "should have a hard value of 25" do
      expect(@hand.hard_sum).must_equal 25
    end

    it "should have a soft value of hard value" do
      expect(@hand.soft_sum).must_equal 25
    end

    it "should be busted" do
      expect(@hand.bust?).must_equal true
    end

    it "should not be blackjack?" do
      expect(@hand.blackjack?).must_equal false
    end

    it "should not respond true to has_ace?" do
      expect(@hand.has_ace?).must_equal false
    end

    it "should not be soft?" do
      expect(@hand.soft?).must_equal false
    end
  end


  describe BlackjackHand, "A hand that has an no aces and is 21" do
    before do
      @hand = BlackjackHand.make('7D', '7C', '7S')
    end

    it "should not respond to pair" do
      expect(@hand.pair?).must_equal false
    end

    it "should have a hard value of 21" do
      expect(@hand.hard_sum).must_equal 21
    end

    it "should have a soft value of hard value" do
      expect(@hand.soft_sum).must_equal 21
    end

    it "should not be busted" do
      expect(@hand.bust?).must_equal false
    end

    it "should not be blackjack?" do
      expect(@hand.blackjack?).must_equal false
    end

    it "should not respond true to has_ace?" do
      expect(@hand.has_ace?).must_equal false
    end

    it "should not be soft?" do
      expect(@hand.soft?).must_equal false
    end
  end

  describe BlackjackDeck, "a deck can be created" do
    before do
      @deck = BlackjackDeck.new
    end

    it "should have a deck with cards face down" do
      expect(@deck.all? {|c| c.face_down?}).must_equal true
    end

    it "should have 52 cards" do
      expect(@deck.length).must_equal 52
    end
  end

  describe BlackjackDeck, "a default deck of one set of cards" do
    before do
      @deck = BlackjackDeck.new
    end

    it "should have a deck with cards face down by default" do
      expect(@deck.all? {|c| c.face_down?}).must_equal true
    end

  end

  describe BlackjackDeck, "a default deck of one set of cards" do
    before do
      @deck = BlackjackDeck.new
    end

    it "should have a deck with cards face down by default" do
      expect(@deck.all? {|c| c.face_down?}).must_equal true
    end

  end

  describe Shoe, "shoes come in a variety of sizes" do
    it "should have the correct number of cards" do
      @shoe = Shoe.new
      expect(@shoe.remaining).must_equal (1*52)

      @shoe = OneDeckShoe.new
      expect(@shoe.remaining).must_equal (1*52)

      @shoe = TwoDeckShoe.new
      expect(@shoe.remaining).must_equal (2*52)

      @shoe = SixDeckShoe.new
      expect(@shoe.remaining).must_equal (6*52)
    end
  end

  describe Shoe, "a 6 deck shoe" do
    before do
      @shoe = SixDeckShoe.new
    end

    it "should have a functioning random cut card somewhere past half the deck" do
      @shoe.place_marker_card
      expect(@shoe.decks.marker.offset).must_be :<, @shoe.remaining/3
    end

    it "should not need shuffle upon initial cut card placement" do
      @shoe.place_marker_card
      expect(@shoe.needs_shuffle?).must_equal false
    end

    it "should support options for cut card" do
      @num_decks = 10
      opts = {
        marker_card_segment: 0.10,
        marker_card_offset:  0.05,
        split_and_shuffles: 5,
        num_decks: @num_decks
      }
      @custom_shoe = Shoe.new(opts)
      @custom_shoe.shuffle
      100.times {
        @custom_shoe.place_marker_card
        expect(@custom_shoe.decks.marker.offset).must_be :<=, @shoe.remaining/4
      }
      expect(@custom_shoe.remaining).must_equal (@num_decks*52)
    end

    it "should let the cut card be placed at a specific offset" do
      @my_offset = 84
      @shoe.place_marker_card(@my_offset)
      expect(@shoe.decks.marker.offset).must_equal @my_offset
    end

    it "shuffle up should set marker.offset to nil" do
      @shoe.place_marker_card
      expect(@shoe.decks.marker.offset).must_be :>, 0
      @shoe.shuffle
      assert_nil @shoe.decks.marker.offset
    end

    it "should allow a force_shuffle to be invoked, causing needs_shuffle? to be true" do
      @shoe.place_marker_card
      expect(@shoe.needs_shuffle?).must_equal(false)
      @shoe.force_shuffle
      expect(@shoe.needs_shuffle?).must_equal(true)
      @shoe.shuffle
      @shoe.place_marker_card
      expect(@shoe.needs_shuffle?).must_equal(false)
    end

    it "should deal cards to hands one at a time face up" do
      num_cards = @shoe.remaining
      @destination = MiniTest::Mock.new
      top_card = @shoe.decks.first
      @destination.expect(:add, nil, [[top_card]])
      @shoe.place_marker_card
      @shoe.deal_one_up(@destination)
      @destination.verify
      expect(@shoe.remaining).must_equal num_cards-1
    end

    it "should deal cards to hands one at a time face down" do
      @shoe.place_marker_card
      num_cards = @shoe.remaining
      @destination = MiniTest::Mock.new
      top_card = @shoe.decks.first
      @destination.expect(:add, nil, [[top_card]])
      @shoe.deal_one_down(@destination)
      @destination.verify
      expect(@shoe.remaining).must_equal num_cards-1
    end

    it "should support a new hand getter to deal cards to" do
      @shoe.place_marker_card
      hand = @shoe.new_player_hand
      num_cards = 3
      num_cards.times { @shoe.deal_one_up(hand)}
      expect(hand.length).must_equal num_cards
    end

    it "should support a discard pile that is wired to the hand when it folds and back to deck when shuffling" do
      @shoe.place_marker_card
      start_count = @shoe.remaining
      hand_counts = [11,4,7,3,2,9]
      hands = Array.new(hand_counts.length) {@shoe.new_player_hand}
      cards_dealt = hand_counts.reduce(:+)

      2.times do
        total_cards_dealt = 0
        3.times do |i|
          hand_counts.each_with_index do |c, i|
            c.times { @shoe.deal_one_up(hands[i])}
            expect(hands[i].length).must_equal(c)
          end
          total_cards_dealt += cards_dealt
          expect(@shoe.remaining).must_equal(start_count - total_cards_dealt)

          hands.map(&:fold)
          expect(@shoe.discarded).must_equal(total_cards_dealt)

          expect(hands.all? {|h| h.length == 0}).must_equal(true)
        end

        expect(@shoe.remaining).must_equal(start_count - total_cards_dealt)
        expect(@shoe.discarded).must_equal(total_cards_dealt)

        @shoe.shuffle
        @shoe.place_marker_card
        expect(@shoe.discarded).must_equal(0)
        expect(@shoe.remaining).must_equal(start_count)
      end
    end

    it "should deal cards and report needs_shuffle? true when reached cut card" do
      @shoe.place_marker_card
      deal_this_many = @shoe.remaining - @shoe.decks.marker.offset
      deal_this_many.times do
        @destination = MiniTest::Mock.new
        top_card = @shoe.decks.first
        @destination.expect(:add, nil, [[top_card]])
        @shoe.deal_one_up(@destination)
        @destination.verify
        expect(@shoe.needs_shuffle?).wont_equal true
      end
      @destination = MiniTest::Mock.new
      top_card = @shoe.decks.first
      @destination.expect(:add, nil, [[top_card]])
      @shoe.deal_one_up(@destination)
      @destination.verify
      expect(@shoe.needs_shuffle?).must_equal true
    end

    it "should deal cards to hands one at a time face up and keep counter" do
      @shoe.place_marker_card
      num_cards = @shoe.remaining
      @destination = MiniTest::Mock.new
      top_card = @shoe.decks.first
      @destination.expect(:add, nil, [[top_card]])
      expect(@shoe.cards_dealt.count).must_equal 0
      @shoe.deal_one_up(@destination)
      expect(@shoe.cards_dealt.count).must_equal 1
      @destination.verify
      @shoe.shuffle
      @shoe.place_marker_card
      @destination = MiniTest::Mock.new
      top_card = @shoe.decks.first
      @destination.expect(:add, nil, [[top_card]])
      @shoe.deal_one_up(@destination)
      @destination.verify
      expect(@shoe.cards_dealt.count).must_equal 2
    end

    it "shuffle up should incr counter" do
      expect(@shoe.num_shuffles.count).must_equal 1
      @shuffs = 4
      @shuffs.times { @shoe.shuffle }
      @shoe.place_marker_card
      expect(@shoe.num_shuffles.count).must_equal 1 + @shuffs
    end

    it "should allow resetting of all counters" do 
      expect(@shoe.num_shuffles.count).must_equal 1
      @shuffs = 4
      @shuffs.times { @shoe.shuffle }
      @shoe.place_marker_card
      expect(@shoe.num_shuffles.count).must_equal 1 + @shuffs
      num_cards = @shoe.remaining
      @destination = MiniTest::Mock.new
      top_card = @shoe.decks.first
      @destination.expect(:add, nil, [[top_card]])
      expect(@shoe.cards_dealt.count).must_equal 0
      @shoe.deal_one_up(@destination)
      expect(@shoe.cards_dealt.count).must_equal 1
      @destination.verify

      @shoe.reset_counters
      expect(@shoe.cards_dealt.count).must_equal 0
      expect(@shoe.num_shuffles.count).must_equal 0
    end
  end

  describe BasicStrategy, "An automated player strategy from the basic hitting guidelines" do
    before do
      @table = Table.new('test')
      @player = Player.new('dave')
      @player.join(@table)
      @bet_box = @player.default_bet_box
      @basic_strategy = BasicStrategy.new(@table, @player)
    end

    it "should follow the basic strategy for hard bet standing" do
      %w{7D 8C 9H 10H QS}.each do |c2|
        @bet_box.hand.set(BlackjackCard.make("10D", c2))
        ['A', *2..10].each do |dealer_up_card_val|
          up_card = BlackjackCard.from_s("#{dealer_up_card_val}H")
          expect(@basic_strategy.play(@bet_box, up_card).first).must_equal(Action::STAND)
        end
      end
    end

    it "should follow the basic strategy for hard bet hitting" do
      %w{2D 3C 4H 5H 6S}.each do |c2|
        @bet_box.hand.set(BlackjackCard.make("10D", c2))
        [*7..10].each do |dealer_up_card_val|
          up_card = BlackjackCard.from_s("#{dealer_up_card_val}H")
          expect(@basic_strategy.play(@bet_box, up_card).first).must_equal(Action::HIT)
        end
      end
    end

    it "should follow the basic strategy for hard bet standing" do
      %w{4H 5H 6S}.each do |c2|
        @bet_box.hand.set(BlackjackCard.make("10D", c2))
        [*4..6].each do |dealer_up_card_val|
          up_card = BlackjackCard.from_s("#{dealer_up_card_val}H")
          expect(@basic_strategy.play(@bet_box, up_card).first).must_equal(Action::STAND)
        end
      end
    end
  end
end
