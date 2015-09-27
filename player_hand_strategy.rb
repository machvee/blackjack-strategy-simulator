module Blackjack

  module Action
    LEAVE=-1
    SIT_OUT=0
    BET=1
    HIT=2
    STAND=3
    SPLIT=4
    DOUBLE_DOWN=5
    SURRENDER=6
    INSURANCE=7
    NO_INSURANCE=8
    EVEN_MONEY=9
  end

  DECISIONS = {
    Action::SPLIT => "SPLITS",
    Action::HIT => "HITS",
    Action::DOUBLE_DOWN => "DOUBLE_DOWNS",
    Action::SURRENDER => "SURRENDERS",
    Action::STAND => "STANDS"
  }

  module Outcome
    NONE=0
    WON=1
    LOST=2
    PUSH=3
    BUST=4
    INSURANCE_WON=5
    INSURANCE_LOST=6
  end

  OUTCOMES = {
    Outcome::WON => "WON",
    Outcome::LOST => "LOST",
    Outcome::PUSH => "PUSH",
    Outcome::BUST => "BUST",
    Outcome::INSURANCE_WON => "WON INSURANCE",
    Outcome::INSURANCE_LOST => "LOST INSURANCE",
    Outcome::NONE => nil
  }

  class PlayerHandStrategy
    #
    # base class for player strategy on how to play his hand. 
    # An example sub-class would be one that just prompts the
    # player at the command line for instructions on what to do.
    # The context passed are all the other players hands on the
    # table (if any) and the dealers up card
    #

    attr_reader  :table
    attr_reader  :player
    attr_reader  :config

    DEFAULT_OPTIONS = {
      num_bets: 1
    }

    def initialize(table, player, options={})
      @table = table
      @player = player
      @config = DEFAULT_OPTIONS.merge(options)
    end

    def new_hand
      #
      # hook for player to initialize stats, etc.
      #
      self
    end

    def outcome(win_lose_push, dealer_hand, amount)
      #
      # win_lose_push:
      #   Action::WON
      #   Action::LOST
      #   Action::PUSH
      #
      # dealer_hand:
      #  allow player to examine dealers hand and to record stats, etc
      #
      # amount
      #   +/- amount this hand won/lost the player
      #
      self
    end

    def num_bets
      #
      # Invoked for available_for(player) bet_boxes which lets players make one or more bets
      # return Action::SIT_OUT to make NO bets in any bet_box
      # return Action::LEAVE to take bets and leave table before next hand dealt
      # return 1 - table.config[:max_player_bets] to make one or more bets at the table
      #
      config[:num_bets]
    end

    def bet_amount
      #
      # override in sub-class to provide a whole dollar amount
      # to bet for the main opening bet.
      #
    end

    def insurance_bet_amount(bet_box)
      # The player may choose up to 1/2
      # the MAIN bet amount for INSURANCE
    end

    def double_down_bet_amount(bet_box)
      # The player may choose up to the full
      # MAIN bet amount for DOUBLE_DOWN
    end

    def insurance?(bet_box)
      #
      # override in sub-class to indicate:
      #
      # Action::INSURANCE - the player wants insurance against dealer Ace up-card
      # Action::NO_INSURANCE - willing to lose automatically if dealer has blackjack
      # Action::EVEN_MONEY - player_hand is blackjack, will take 1-1 immediate payout 
      #
    end

    def decision(bet_box, dealer_up_card, other_hands=[])
      #
      # override in subclass to decide what to do based on
      #   bet_box (hand and bet_amount)
      #   dealer_up_card value
      #   other_hands
      #
      # valid responses:
      #
      #   Action::HIT
      #   Action::STAND
      #   Action::SPLIT
      #   Action::DOUBLE_DOWN
      #
    end

    def error(strategy_step, message)
      #
      # Dealer will call this with a message string when/if the PlayerHandStrategy
      # would respond with something invalid during the above strategy_steps
      # and then invokes the offending method again
      #
      #  (e.g. :decision, :insurance, :bet_amount, or :play)
      #
      # e.g. raise "invalid entry for #{strategy_step}: #{message}"
      # 
      raise "#{strategy_step}: #{message}"
    end
  end
end
