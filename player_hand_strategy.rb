module Blackjack

  module Action
    LEAVE=0
    SIT_OUT=1
    PLAY=2
    HIT=3
    STAND=4
    SPLIT=5
    DOUBLE_DOWN=6
    SURRENDER=7
    INSURANCE=8
    NO_INSURANCE=9
    EVEN_MONEY=10
  end

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

    def initialize(table, player)
      @table = player
      @player = player
    end

    def play?
      #
      # return Action::BET to put chips in the bet_box
      # return Action::SIT_OUT to stay at table but sit out hand
      # return Action::LEAVE to leave table before next hand dealt
      #
    end

    def bet_amount
      #
      # override in sub-class to provide a whole dollar amount
      # to bet.
      #
    end

    def insurance?(player_hand)
      #
      # override in sub-class to indicate:
      #
      # Action::INSURANCE - the player wants insurance against dealer Ace up-card
      # Action::NO_INSURANCE - willing to lose automatically if dealer has blackjack
      # Action::EVEN_MONEY - player_hand is blackjack, will take 1-1 immediate payout 
      #
    end

    def decision(player_hand, dealer_up_card, other_hands=[])
      #
      # override in subclass to decide what to do based on
      #   player_hand
      #   dealer_up_card
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

  class PromptPlayerHandStrategy < PlayerHandStrategy
    #
    # this strategy will make a few automatic decisions, but
    # primarily prompts the Player for on how much to bet,
    # whether to Hit, Stand or Split, etc.
    #
    def initialize(table, player)
      @get_user_decision = CommandPrompter.new("Hit", "Stand", "Double", "sPlit")
      @map = {
        'h' => Action::HIT,
        's' => Action::STAND,
        'd' => Action::DOUBLE_DOWN,
        'p' => Action::SPLIT
      }
      min_bet = table.config[:minimum_bet]
      max_bet = table.config[:maximum_bet]
      @user_bet_maker = CommandPrompter.new("Bet Amount:int:#{min_bet}:#{max_bet}")
    end

    def decision(player_hand, dealer_up_card, other_hands=[])
      show_other_hands(other_hands)
      show_dealer_up_card(dealer_up_card)
      show_player_hand(player_hand)
      prompt_for_action
    end

    def bet_amount
      @user_bet_maker.get_command.to_i
    end

    def play?
      player.bank.current_balance > blayer.bank.initial_deposit/8 ? Action::BET : Action::LEAVE
    end

    def insurance?(player_hand)
      Action::NO_INSURANCE
    end

    def error(strategy_step, message)
      sep = "="*[80, (message.length)].min
      puts ''
      puts sep
      puts message
      puts sep
      puts ''
    end

    private

    def show_other_hands(other_hands)
      puts other_hands.inspect unless other_hands.empty?
    end

    def show_dealer_up_card(dealer_up_card)
      puts "Dealer's showing:"
      dealer_up_card.print
    end

    def show_player_hand(player_hand)
      player_hand.print
    end

    def prompt_for_action
      @map[@get_user_decision.get_command]
    end
  end
end
