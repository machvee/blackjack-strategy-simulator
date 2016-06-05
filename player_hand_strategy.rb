module Blackjack

  module Decision
    #
    # The player is asked to make these decisions
    # throughout game play.  The player returns an Action below
    # or an integer for for num bets and bet amounts
    #
    STAY=1                   # stay at the table or cash-out and quit
    NUM_BETS=2               # how many bet boxes to place bets (0-max available)
    BET_AMOUNT=3             # amount of bet in each bet box
    INSURANCE=4              # take INSURANCE Action if dealer up card is Ace?
    INSURANCE_BET_AMOUNT=5   # how much to bet on INSURANCE from 1 to bet_amount/2?
    DOUBLE_DOWN_BET_AMOUNT=6 # how much to bet on a DOUBLE_DOWN from 1 to bet_amount?
    PLAY=7                   # What Action to take when dealer ask player to make a hand decision?
  end

  module Action
    #
    # For Decision STAY
    #
    LEAVE=-1
    PLAY=0

    #
    # for Decision PLAY
    #
    HIT=1
    STAND=2
    SPLIT=3
    DOUBLE_DOWN=4
    SURRENDER=5

    #
    # for Decision INSURANCE
    #
    INSURANCE=6
    NO_INSURANCE=7
    EVEN_MONEY=8

    def action_name(a)
      #
      # Action.action_name(Action::DOUBLE_DOWN) => "DOUBLE DOWNS"
      #
      @action_names ||= Hash.new {|h,k| h[k] = constants.find{ |name| const_get(name) == k}.to_s.gsub(/_/, ' ') + "S"}
      @action_names[a]
    end
    module_function :action_name
  end

  module Outcome
    NONE=0
    WON=1
    LOST=2
    PUSH=3
    BUST=4
    INSURANCE_WON=5
    INSURANCE_LOST=6
  end


  class PlayerHandStrategy
    #
    # base class for player strategy on how to play his hand.
    # The game_play invokes this through the Dealer to get the
    # players decision on what move to make, how much to bet, etc.
    #
    # An example sub-class would be one that just prompts the
    # player at the command line for instructions on what to do.
    # The context passed are all the other players hands on the
    # table (if any) and the dealers up card
    #
    # Made visible to the class when they are available are public attributes of
    # the table -- items that would be visible to a player at a real blackjack
    # table.
    #
    #    - table info (# players, player seat positions, # decks in shoe, config)
    #    - dealer up_card
    #    - current players hand.
    #    - other visible player's cards
    #    - the percentage % of cards in shoe/decks remaining before the cut card
    #
    # all other aspects of play and inputs to strategy must be maintained by the
    # strategy.  e.g.  card counts
    #

    attr_reader  :table
    attr_reader  :player
    attr_reader  :options

    def initialize(table, player, options={})
      @player = player
      @table = table
      @options = options
    end

    def stay?
      #
      # Decision::STAY
      #
      # override in sub-class to indicate:
      #
      #   Action::LEAVE - the player cashes out and/or repays markers and leaves table
      #    Action::PLAY - means they can choose to occupy the seat and will make num_bets 
      #                   bets in 0 or more bet_boxes.
      #
    end

    def num_bets
      #
      # Decision::NUM_BETS
      #
      # override in sub-class to return:
      #
      #      0 - to make NO bets in any bet_box and sit out the hand
      #     1+ - to claim 1 or more (up to table.config[:max_player_bets]>) default and adjacent bet boxes
      #          at the table, if they are available.
      #
    end

    def bet_amount(bet_box)
      #
      # Decision::BET_AMOUNT
      #
      # override in sub-class to provide:
      #
      #   for each player bet_box, a whole dollar amount to bet for the main opening bet.
      #
    end

    def insurance?(bet_box)
      #
      # Decision::INSURANCE
      #
      # override in sub-class to indicate:
      #
      #      Action::INSURANCE - the player wants insurance against dealer Ace up-card
      #   Action::NO_INSURANCE - willing to lose automatically if dealer has blackjack
      #     Action::EVEN_MONEY - player_hand is blackjack, will take 1-1 immediate payout 
      #
    end

    def insurance_bet_amount(bet_box)
      #
      # Decision::INSURANCE_BET_AMOUNT
      #
      # The player may choose up to 1/2 the MAIN bet amount for INSURANCE
    end

    def play(bet_box, dealer_up_card, other_hands=[])
      #
      # Decision::PLAY
      #
      # override in subclass to decide what to do based on
      #   bet_box for hand and bet_amount
      #   dealer_up_card value
      #   other_hands current visible cards dealt to other players
      #
      # valid responses:
      #
      #   Action::HIT
      #   Action::STAND
      #   Action::SPLIT
      #   Action::DOUBLE_DOWN
      #
    end

    def double_down_bet_amount(bet_box)
      #
      # Decision::DOUBLE_DOWN_BET_AMOUNT
      #
      # override in sub-class to determine double_down_bet_amount
      #
      #   1-current_bet_amount the player may choose up to the full MAIN bet amount for DOUBLE_DOWN
    end


    def outcome(outcome, amount)
      #
      # (optional) override-in sub-class to take strategy-specific actions
      # on one of the possible outcomes of hand 
      #
      # outcome
      #   Outcome::WON
      #   Outcome::LOST
      #   Outcome::PUSH
      #   Outcome::BUST
      #
      # amount
      #   integer
      #     > 0 - amount won
      #       0 - push
      #     < 0 - amount lost
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
