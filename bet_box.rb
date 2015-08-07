module Blackjack
  class BetBox
    attr_reader :table
    attr_reader :player
    attr_reader :box
    attr_reader :insurance
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
      @box = Bank.new(0)
      @insurance = Bank.new(0)
      @hand = table.new_hand
      @position = player_seat_position
      reset
      @parent_split_box = parent_split_box # do after reset
    end

    def dedicated?
      #
      # bet box has a seated player in front of it
      #
      !table.seated_players[position].nil?
    end

    def available?
      #
      # adjacent seated players may place a bet here
      # when its available?
      #
      !dedicated? && player.nil?
    end

    def active?
      #
      # A player has a bet in this bet box
      # adjacent seated players may not place a bet here
      # when its active?
      #
      !player.nil?
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

    def take_winnings
      box.transfer_to(player.bank, bet_amount)
      self
    end

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

    def split
      #
      # validate that the hand is splittable
      # validate number of splits for the parent bet box and table config
      # 
      # raise "player hand is already split" if split?
      # raise "split limit of #{table.split_limit} reached for this bet" if \
      #   table.has_split_limit? && player.num_splits(self) == table.split_limit
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

    def num_splits
      root_bet_box.split_counter
    end

    def split_counter
      split? ? split_boxes.inject(1) {|count, bet_box| count += bet_box.split_counter} : 0
    end

    def discard
      split_boxes.discard if split?
      reset
      self
    end

    def iter(&block)
      split? ? split_boxes.iter(&block) : block.call(self)
    end

    def reset
      hand.fold
      @player = nil
      @split_boxes = nil
      @parent_split_box = nil
      self
    end

    def inspect
      split? ?  split_boxes.inspect : to_s
    end

    def to_s
      available? ? "Available BetBox #{position}" : "Dedicated BetBox #{position} for #{player.name}"
    end

    private

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
