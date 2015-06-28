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

    def initialize(player, player_hand, dealer_up_card=nil, other_hands=[])
      @player = player
      @player_hand = player_hand
      @dealer_up_card = dealer_up_card
      @other_hands = other_hand
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
    def decision
      show_other_hands
      show_dealer_up_card
      show_player_hand
      action = prompt_for_action
      action
    end
  end
end
