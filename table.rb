require 'counters'
require 'blackjack_card'
require 'shoe'
require 'dealer'
require 'player'
require 'bet_box'

module Blackjack
  class Table

    include Counters

    counters :players_seated

    DEFAULT_MAX_SEATS = 6
    DEFAULT_BLACKJACK_PAYS = [3,2]

    DEFAULT_CONFIG = {
      blackjack_payout:    DEFAULT_BLACKJACK_PAYS,
      dealer_hits_soft_17: false,
      num_seats:           DEFAULT_MAX_SEATS
    }

    attr_reader   :name
    attr_reader   :shoe
    attr_reader   :dealer
    attr_reader   :players
    attr_reader   :bet_boxes
    attr_reader   :config

    def initialize(name, options={})
      @name = name
      @config = DEFAULT_CONFIG.merge(options)

      @dealer = Dealer.new(self)
      @shoe = new_shoe

      @players = Array.new(num_seats) {nil}

      #
      # bet_boxes array 0 to (num_seats-1) are positions right to left
      # on the table.  Dealer deals to position 0 first and (num_seats-1)
      # last
      #
      @bet_boxes = Array.new(num_seats) {BetBox.new(self)}
    end

    def join(player, desired_seat_position=nil)
      seat_position = find_empty_seat_position(desired_seat_position)
      if seat_position.nil?
        if desired_seat_position.nil?
          raise "Sorry this table is full"
        else
          raise "Sorry that seat is taken by #{players[desired_seat_position].name}"
        end
      end
      players[seat_position] = player
      players_seated.incr
      seat_position
    end

    def leave(player)
      ind = players.index(player)
      raise "player #{player.name} isn't at table #{name}" if ind.nil?
      players[ind] = nil
      player.leave_table
    end

    def seat_available?(desired_seat_position=nil)
      !find_empty_seat_position(desired_seat_position).nil?
    end

    def seat_position(player)
      players.index(player)
    end

    private

    def new_shoe
      config[:shoe] || SixDeckShoe.new
    end

    def num_seats
      config[:num_seats] || DEFAULT_MAX_SEATS
    end

    def find_empty_seat_position(desired_seat_position=nil)
      if desired_seat_position.nil?
        # find first available empty seat index, or nil of none
        players.index(nil) 
      else
        players[desired_seat_position].nil? ? desired_seat_position : nil
      end
    end
  end
end
