module Blackjack
  class BetBox
    attr_reader :table
    attr_reader :player
    attr_reader :box
    attr_reader :insurance
    attr_reader :double
    attr_reader :hand
    attr_reader :position

    #
    # if this bet_box came from a previously split hand
    # then parent_split_box will point back at the splitter
    #
    # if this hand is split, then split boxes will be non-nil
    # and will contain the two new bet_box hands
    #
    attr_reader :parent_split_box
    attr_reader :split_boxes

    def initialize(table, player_seat_position, parent_split_box=nil)
      @table = table

      @box       = Bank.new(0)
      @insurance = Bank.new(0)
      @double    = Bank.new(0)

      @hand = table.new_hand
      @position = player_seat_position
      reset
      @parent_split_box = parent_split_box # do after reset
    end

    def dedicate_to(player)
      @reserved_for_player = player
    end

    def player_leaves
      @reserved_for_player = nil
    end

    def dedicated?
      #
      # bet box has a seated player in front of it
      #
      !@reserved_for_player.nil?
    end

    def available?
      #
      # adjacent seated players may place a bet here its available?
      #
      !(dedicated? || active?)
    end

    def total_player_bet
      bet_amount + double_bet_amount
    end

    def active?
      #
      # A player has a bet in this bet box
      # adjacent seated players may not place a bet here
      # when its active?
      #
      bet_amount > 0 || split?
    end

    def insurance_bet(bet_amount)
      player.bank.transfer_to(insurance, bet_amount)
      self
    end

    def bet(player, bet_amount, from_account=nil)
      #
      # player makes a bet
      #
      @player = player
      (from_account||player.bank).transfer_to(box, bet_amount)
      self
    end

    def double_down(double_down_bet_amt)
      player.make_double_down_bet(self, double_down_bet_amt)
    end

    def take_down_bet
      box.transfer_to(player.bank, box.balance)
      double.transfer_to(player.bank, double.balance) if double_down?
      self
    end

    alias :take_winnings :take_down_bet

    def take_insurance
      insurance.transfer_to(player.bank, insurance_bet_amount)
      self
    end

    def bet_amount
      box.balance
    end

    def insurance_bet_amount
      insurance.balance
    end

    def double_bet_amount
      double.balance
    end

    def split
      #
      raise "not able to split this hand" unless can_split?
      @split_boxes = SplitBoxes.new(self)
      self
    end

    def split?
      #
      # was this hand split into two hands?
      #
      !split_boxes.nil?
    end

    def from_split?
      #
      # was this bet_box created from a split?
      #
      !parent_split_box.nil?
    end

    def from_split_aces?
      from_split? && hand[0].ace?
    end

    def num_splits
      root_bet_box.split_counter
    end

    def split_counter
      split? ? split_boxes.inject(1) {|count, bet_box| count += bet_box.split_counter} : 0
    end

    def can_split?
      !split? && hand.pair? && (!table.has_split_limit? || num_splits < table.split_limit)
    end

    def double_down?
      double.balance > 0
    end

    def player_name
      if dedicated? 
        @reserved_for_player.name
      elsif active?
        @player.name
      else
        "unoccupied"
      end + "[#{position}]"
    end

    def discard
      raise "you can't discard until dealer or player removes bet" if bet_amount > 0
      hand.fold
      @player = nil
      self
    end

    def iter(&block)
      split? ? split_boxes.iter(&block) : block.call(self) if active?
    end

    def reset
      discard
      @split_boxes = nil
      @parent_split_box = nil
      self
    end

    def inspect
      split? ?  split_boxes.inspect : to_s
    end

    def to_s
      available? ? "Available BetBox #{position}" :
        "BetBox %d with $%d for %s%s" % [
           position,
           bet_amount,
           (player||@reserved_for_player).name,
           hand.length == 0 ? "" : " " + hand.to_s
         ]
    end

    private

    def reset_bank
      @box.reset
      @insurance.reset
      @double.reset
    end

    def root_bet_box
      #
      # follow parent_split_boxes back until the root
      # bet_box for the player is reached,
      #
      bet_box = self
      sb = parent_split_box
      while(!sb.nil?) do
        bet_box = sb.parent_bet_box
        sb = bet_box.parent_split_box
      end
      bet_box
    end
  end
end
