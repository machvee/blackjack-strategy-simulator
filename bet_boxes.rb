module Blackjack
  class BetBoxes
    attr_reader :bet_boxes
    attr_reader :table

    include Enumerable

    def initialize(table, num_bet_boxes)
      @table = table
      @bet_boxes = Array.new(num_bet_boxes) {BetBox.new(table)}
    end

    def each
      bet_boxes.each do |bb|
        yield bb
      end
    end

    def [](index)
      bet_boxes[index]
    end

    def any_bets?
      bet_boxes.any? {|bet_box| bet_box.current_bet > 0}
    end

    def dedicated_to(player)
      #
      # this is the default box for the player
      # to make bets.  No one else can make bets in
      # it while the player is seated
      #
      bet_boxes[table.seat_position(player)]
    end

    def available_for(player)
      #
      # search for consective bet boxes until options[:max_player_bets] is reached
      # or a bet_box is in front of a another seated player
      #
      player_seat_position = table.seat_position(player)
      raise "that player is not seated" if player_seat_position.nil?

      min_pos = 0
      max_pos = table.config[:num_seats]-1

      yield dedicated_to(player)

      #
      # TODO: need to iterate over adjacent, available bet_boxes
      # if they're available
      #
    end

    def each_active
      bet_boxes.each do |bet_box|
        yield bet_box if bet_box.active?
      end
    end
  end
end
