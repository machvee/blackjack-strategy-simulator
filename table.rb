module Blackjack
  class Table

    MAX_SEATS = 6

    attr_reader   :name
    attr_reader   :shoe
    attr_reader   :dealer
    attr_reader   :players

    def initialize(name, shoe)
      @name = name
      @dealer = Dealer.new(self)
      @shoe = shoe
      @players = Array.new(MAX_SEATS) {nil}
    end

    def join(player_name, desired_seat_position=nil)
      seat_position = find_empty_seat_position(desired_seat_position)
      @player[seat_position] = Player.new(player_name)
    end

    private

    def find_empty_seat_position(desired_seat_position=nil)
      if desired_seat_position.nil?
        seat_position = @players.index(nil)
        raise "Sorry #{player_name}, but this table is full" \
          if seat_position.nil?
      else
        raise "Sorry #{player_name}, that seat is taken by #{@players[desired_seat_position].name}" \
          unless @players[desired_seat_position].blank?
        seat_position = desired_seat_position
      end
      seat_position
    end
  end
end
