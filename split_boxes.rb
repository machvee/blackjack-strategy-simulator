module Blackjack
  class SplitBoxes
    #
    # the hand pair is taken from the parent_bet_box
    # and two new bet_boxes are created right and left.
    # the parent bet_box bet is moved in to the right, and
    # the left bet box gets an equal bet taken from the player
    # bank
    attr_reader  :player
    attr_reader  :parent_bet_box
    attr_reader  :bet_amount
    attr_reader  :bet_box_left
    attr_reader  :bet_box_right

    include Enumerable

    def initialize(parent_bet_box)
      @player = parent_bet_box.player
      @parent_bet_box = parent_bet_box
      @bet_amount = parent_bet_box.bet_amount

      create_right_box_from_parent_bet_box
      create_left_box_from_parent_bet_box
    end

    def each
      [bet_box_right, bet_box_left].each do |bet_box|
        yield bet_box
      end
    end

    def discard
      each {|bet_box| bet_box.discard}
    end

    def iter(&block)
      each {|bet_box| bet_box.iter(&block)}
    end

    def inspect
      "Split:\n\t" + map {|bet_box| bet_box.inspect}.join("\n\t")
    end

    private

    def create_left_box_from_parent_bet_box
      @bet_box_left = new_hand_from_parent
      player.make_split_bet(bet_box_left, bet_amount)
    end

    def create_right_box_from_parent_bet_box
      @bet_box_right = new_hand_from_parent
      #
      # transfer the bet from the parent bet box to the new
      # split right bet box
      #
      bet_box_right.bet(player, bet_amount, parent_bet_box.box)
    end

    def new_hand_from_parent
      bet_box = BetBox.new(parent_bet_box.table, parent_bet_box.position, self)
      bet_box.dedicate_to(player)
      move_one_card_to(bet_box)
      bet_box
    end

    def move_one_card_to(bet_box)
      bet_box.hand.add(parent_bet_box.hand.remove(1, BlackjackCard::FACE_UP))
    end

  end
end
