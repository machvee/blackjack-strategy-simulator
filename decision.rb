module Blackjack
  class Decision
    #
    # The player is asked to make these decisions throughout game play
    #
    # STAY                    stay at the table or cash-out and quit
    # NUM_HANDS               how many bet boxes to place bets (0-max available/table limit)
    #
    # From within a bet_box, the player must make these decisions
    #
    # BET_AMOUNT              amount of bet in each bet box
    # INSURANCE               take INSURANCE Action if dealer up card is Ace?
    # INSURANCE_BET_AMOUNT    how much to bet on INSURANCE from 1 to bet box bet_amount/2?
    # DOUBLE_DOWN_BET_AMOUNT  how much to bet on a DOUBLE_DOWN from 1 to bet_amount?
    # PLAY                    What Action to take when playing a hand? (hit/stand/split/dbl)
    #
    # Each Decision sub_class handles one of the above game decisions.
    #

    attr_reader :table
    attr_reader :player
    attr_reader :stats
    attr_reader :bet_box

    def initialize(player, bet_box=nil)
      @player = player
      @table = player.table
      @bet_box = bet_box
      @stats = StrategyStats.new
    end

    def prompt
      while(true) do
        response, rule = get_response
        success, message = valid?(response)
        break if success
        #
        # player.strategy.error will either raise in the case of bot strategies
        # or should print/communicate the message to a live user
        #
        player.strategy.error(name, message)
      end
      table.game_announcer.play_by_play(self, player, response)

      stats.add(rule) unless rule.nil?

      response
    end

    def name
      self.class.name.gsub(/Decision/,'').downcase
    end

    def print_stats
      @stats.print
    end

    private 

    def get_response
      #
      # override in sub-class.  Returns an Blackjack::Action or integer amount
      # has access to bet_box (nil when optional), and the parent class @player and
      # @table.  get_response also returns a (optional) Rule class instance, which
      # represents the Strategy Rule used make the decision.  The Decision system
      # will keep track of rule(s) used for each Decision sub-class in a chain of
      # decision making until an outcome is determined (e.g. player busts, player wins,
      # deal busts).  Once the outcome is determined, stats are kept for player wins/losses
      # busts/pushes and $ amounts won and lost.
      #
    end

    def valid?(response)
      #
      # override in sub-class.  Returns an [true|false, nil|error_message] array
      # has access to bet_box, player and table
      #
    end
  end
end
