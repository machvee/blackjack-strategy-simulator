module Blackjack
  class BetBoxes
    attr_reader :bet_boxes
    attr_reader :table

    include Enumerable

    def initialize(table, num_bet_boxes)
      @table = table
      @bet_boxes = Array.new(num_bet_boxes) {|i| BetBox.new(table, i)}
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
      bet_boxes.any? {|bet_box| bet_box.bet_amount > 0}
    end

    def dedicated_to(player)
      #
      # this is the default box for the player
      # to make bets.  No one else can make bets in
      # it while the player is seated
      #
      bet_boxes[table.seat_position(player)]
    end

    def num_available_for(player)
      count = 0
      available_for(player) do |b|
        count += 1
      end
      count
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
      max_player_bets = table.config[:max_player_bets]
      bet_box_count = 1
      offset = 1
      available_bet_boxes = [dedicated_to(player)]
      right_remain = left_remain = true
      while(true) do
        #
        # look to the players right then left for an available? bet_box
        # keep working outwards until as many bet_boxes can be selected
        # up to max_player_bets
        #
        break unless right_remain || left_remain

        if right_remain
          ind = player_seat_position - offset
          if ind >= min_pos && bet_boxes[ind].available?
            available_bet_boxes << bet_boxes[ind]
            break if available_bet_boxes.length == max_player_bets
          else
            right_remain = false
          end
        end

        if left_remain
          ind = player_seat_position + offset
          if ind <= max_pos && bet_boxes[ind].available?
            available_bet_boxes << bet_boxes[ind]
            break if available_bet_boxes.length == max_player_bets
          else
            left_remain = false
          end
        end
        offset += 1
      end

      available_bet_boxes.each do |bet_box|
        yield bet_box
      end
    end

    def reset
      each {|bet_box| bet_box.reset}
      self
    end

    def each_active(&block)
      bet_boxes.each { |bet_box| bet_box.iter(&block) if bet_box.active? }
    end

    def inspect
      bet_boxes.inspect     
    end
  end
end
