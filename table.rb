require 'byebug'
require 'delegate'
require 'counter_measures'
require 'blackjack_card'
require 'shoe'
require 'decision'
require 'player_decisions'
require 'player_hand_strategy'
require 'bet_amount_decision'
require 'double_down_bet_amount_decision'
require 'insurance_bet_amount_decision'
require 'insurance_decision'
require 'num_hands_decision'
require 'play_decision'
require 'stay_decision'
require 'prompt_player_hand_strategy'
require 'command_prompter'
require 'simple_strategy'
require 'strategy_table'
require 'table_driven_strategy'
require 'split_boxes'
require 'bet_boxes'
require 'bet_box'
require 'bank'
require 'insurance'
require 'hand_stats'
require 'bet_stats'
require 'histo_bucket'
require 'histo_stats'
require 'dealer'
require 'player_stats'
require 'player'
require 'markers'
require 'game_play'
require 'game_announcer'
require 'table_stats'

module Blackjack
  class Table

    class GameRandomizer

      attr_reader :prng
      attr_reader :seed

      def initialize(opt_seed=nil)
        # pass in an optional seed argument to guarantee
        # that the Dice will always yield the
        # same roll sequence (useful in testing and for comparing
        # strategy to strategy).  Pass no seed argument to ensure
        # that the Dice will have a 'psuedo-random' roll sequence 
        #
        iseed = opt_seed.nil? ? nil : opt_seed.to_i
        @seed = iseed || gen_random_seed
        @prng = Random.new(seed)
      end

      private
      
      def gen_random_seed
        Random.new_seed
      end
    end

    DEFAULT_HOUSE_BANK_AMOUNT  = 1_500_000
    DEFAULT_MAX_SEATS          = 6
    DEFAULT_SHOE_CLASS         = SixDeckShoe
    DEFAULT_GAME_ANNOUNCER     = GameAnnouncer
    DEFAULT_BET_RANGE          = 25..5000
    DEFAULT_MAX_PLAYER_BETS    = 3
    DEFAULT_MAX_SPLITS_PER_BOX = 3
    EVEN_MONEY_PAYOUT          = [1,1]
    DEFAULT_BLACKJACK_PAYOUT   = [3,2]
    INSURANCE_PAYOUT           = [2,1]

    DEFAULT_DOUBLE_DOWN_ON    = []  # [] means ANY. or [9,10,11] or [10,11]

    DEFAULT_CONFIG = {
      num_seats:            DEFAULT_MAX_SEATS,
      blackjack_payout:     DEFAULT_BLACKJACK_PAYOUT,
      dealer_hits_soft_17:  false,
      player_surrender:     false,
      double_down_on:       DEFAULT_DOUBLE_DOWN_ON,
      minimum_bet:          DEFAULT_BET_RANGE.min,
      maximum_bet:          DEFAULT_BET_RANGE.max,
      max_player_bets:      DEFAULT_MAX_PLAYER_BETS,
      max_player_splits:    DEFAULT_MAX_SPLITS_PER_BOX, # nil unlimited or n: one hand split up to n times
      game_announcer_class: DEFAULT_GAME_ANNOUNCER,
      random_seed:          nil,
      shoe:                 nil, # pass in a custom from which to deal
      shoe_class:           DEFAULT_SHOE_CLASS
    }

    attr_reader   :name
    attr_reader   :shoe
    attr_reader   :dealer
    attr_reader   :seated_players
    attr_reader   :bet_boxes
    attr_reader   :insurance
    attr_reader   :config
    attr_reader   :stats
    attr_reader   :house
    attr_reader   :game_announcer
    attr_reader   :seed
    attr_reader   :markers
    attr_reader   :cash

    def initialize(name, options={})
      @name = name
      @config = DEFAULT_CONFIG.merge(options)

      init_table
    end

    def run(options={})
      gp = GamePlay.new(self)
      gp.run(options)
      report_stats
    end

    def init_table
      @stats = TableStats.new(self)
      @house = Bank.new(DEFAULT_HOUSE_BANK_AMOUNT)
      @cash = Bank.new(0)
      @markers = Markers.new(self)
      @prng = GameRandomizer.new(config[:random_seed]).prng
      @seed = @prng.seed
      @shoe = new_shoe

      @seated_players = Array.new(num_seats) {nil}

      #
      # bet_boxes array 0 to (num_seats-1) are positions right to left
      # on the table.  Dealer deals to position 0 first and (num_seats-1)
      # last
      #
      @bet_boxes = BetBoxes.new(self, num_seats)
      @dealer = Dealer.new(self)
      @game_announcer = config[:game_announcer_class].new(self)
      @insurance = Insurance.new(self)
    end

    def join(player, desired_seat_position=nil)
      seat_position = find_empty_seat_position(desired_seat_position)
      if seat_position.nil?
        if desired_seat_position.nil?
          raise "Sorry this table is full"
        else
          raise "Sorry that seat is taken by #{seated_players[desired_seat_position].name}"
        end
      end
      seat(seat_position, player)
      game_announcer.says("Hey %s! Welcome to %s. You're in seat %d" % [player.name, name, seat_position])
      seat_position
    end

    def get_marker(player, amount)
      @markers.borrow(player, amount)
    end

    def repay_markers(player, max_amount)
      @markers.repay_markers(player, max_amount)
    end

    def buy_chips(player, cash_amount)
      dealer.money.buy_chips(player, cash_amount)
    end

    def seat(seat_position, player)
      seated_players[seat_position] = player
      bet_boxes[seat_position].dedicate_to(player)
      stats.players_seated.incr
      seat_position
    end

    def leave(player)
      game_announcer.says("Goodbye #{player.name}, thanks for playing")

      ind = seated_players.index(player)
      raise "player #{player.name} isn't at table #{name}" if ind.nil?
      seated_players[ind] = nil
      bet_boxes[ind].player_leaves
      self
    end

    def other_hands(omit_bet_box)
      []
    end

    def seat_available?(desired_seat_position=nil)
      !find_empty_seat_position(desired_seat_position).nil?
    end

    def seat_position(player)
      seated_players.index(player)
    end

    def new_hand
      shoe.new_player_hand
    end

    def new_dealer_hand
      shoe.new_dealer_hand
    end

    def has_split_limit?
      !config[:max_player_splits].nil?
    end

    def split_limit
      config[:max_player_splits]
    end

    def rand(*args)
      @prng.rand(*args)
    end

    def reset
      init_table
    end

    def num_players
      seated_players.count {|sp| !sp.nil?}
    end

    def any_seated_players?
      !seated_players.compact.empty?
    end

    def each_player
      seated_players.each do |player|
        next if player.nil?
        yield player
      end
      self
    end

    def find_player(name)
      each_player do |player|
        return player if player.name == name
      end
      nil
    end

    def inspect
      name
    end

    private

    def new_shoe
      shoe = config[:shoe] || config[:shoe_class].new(prng: @prng)
      shoe.force_shuffle
      shoe
    end

    def num_seats
      config[:num_seats]
    end

    def find_empty_seat_position(desired_seat_position=nil)
      if desired_seat_position.nil?
        # find first available empty seat index, or nil of none
        seated_players.index(nil) 
      else
        seated_players[desired_seat_position].nil? ? desired_seat_position : nil
      end
    end

    def report_stats
      stats.print
      puts ""
      dealer.print_stats
      each_player do |player|
        player.stats.print
      end
    end

  end

  class TableWithAnnouncer < Table
    def initialize(name, options={})
      super(name, options.merge(game_announcer_class: StdoutGameAnnouncer))
    end
  end
end
