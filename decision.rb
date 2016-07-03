module Blackjack
  class Decision
    #
    # The player is asked to make these decisions throughout game play
    #
    # STAY                    stay at the table or cash-out and quit
    # NUM_BETS                how many bet boxes to place bets (0-max available)
    # BET_AMOUNT              amount of bet in each bet box
    # INSURANCE               take INSURANCE Action if dealer up card is Ace?
    # INSURANCE_BET_AMOUNT    how much to bet on INSURANCE from 1 to bet_amount/2?
    # DOUBLE_DOWN_BET_AMOUNT  how much to bet on a DOUBLE_DOWN from 1 to bet_amount?
    # PLAY                    What Action to take when dealer ask player to make a hand decision?
    #

    attr_reader :table
    attr_reader :player

    def initialize(player)
      @player = player
      @table = player.table
    end

    def prompt(bet_box)
      while(true) do
        response = get_response(bet_box)
        success, message = valid?(response, bet_box)
        break if success
        #
        # player.strategy.error will either raise in the case of bot strategies
        # or should print/communicate the message to a live user
        #
        player.strategy.error(self, message)
      end
      table.game_announcer.play_by_play(self.class.name.downcase, player, response)
      response
    end

    private 

    def get_response(bet_box=nil)
      #
      # override in sub-class.  Returns an Blackjack::Action or integer amount
      # has access to bet_box, player and table
      #
    end

    def valid?(response, bet_box=nil)
      #
      # override in sub-class.  Returns an [true|false, nil|error_message] array
      # has access to bet_box, player and table
      #
    end
  end
end
