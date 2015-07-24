module Blackjack

  module Action
    HIT=1
    STAND=2
    SPLIT=3
    DOUBLE_DOWN=4
  end

  class PlayerHandStrategy
    #
    # base class for player strategy on how to play his hand. 
    # An example sub-class would be one that just prompts the
    # player at the command line for instructions on what to do.
    # The context passed are all the other players hands on the
    # table (if any) and the dealers up card
    #

    attr_reader  :player
    attr_reader  :player_hand
    attr_reader  :e

    def initialize(player, dealer_up_card=nil, other_hands=[])
      @player = player
      @player_hand = player.bet_box.hand
      @dealer_up_card = dealer_up_card
      @other_hands = other_hands
    end

    def decision
      #
      # override in subclass to decide what to do
      #
      # Action::HIT
      # Action::STAND
      # Action::SPLIT
      # Action::DOUBLE_DOWN
      #
    end
  end

  class PromptPlayerHandStrategy < PlayerHandStrategy
    def initialize(player, dealer_up_card=nil, other_hands=[])
      @get_user_decision = Prompt.new("Hit", "Stand", "Double", "sPlit")
      @map = {
        'h' => Action::HIT,
        's' => Action::STAND,
        'd' => Action::DOUBLE_DOWN
        'p' => Action::SPLIT
      }
    end

    def decision
      show_other_hands
      show_dealer_up_card
      show_player_hand
      prompt_for_action
    end

    private

    def show_other_hands
      puts other_hands.inspect unless other_hands.empty?
    end

    def show_dealer_up_card
      puts "Dealer's showing:"
      dealer_up_card.print
    end

    def show_player_hand
      player_hand.print
    end

    def prompt_for_action
      cmd = @get_user_decision.prompt
      @map[cmd]
    end
  end
end
