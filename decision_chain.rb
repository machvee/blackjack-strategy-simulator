module Blackjack

  class DecisionLink
    def outcome(result, amount)
      # result:
      #   Outcome::WON
      #   Outcome::LOST
      #   Outcome::PUSH
      #   Outcome::BUST
      #
      # amount player has won (winnings only) or lost (total bet amount)
      #
    end
  end

  class DecisionChain
    #
    # CONDITIONS
    #   states that are often out of the players control.  They can be used as inputs to rules to help make
    #   decisions
    #     num_decks in shoe
    #     10 percentage
    #     cards remaining in shoe
    #     dealer up card
    #     player hard hand total
    #     player soft hand total
    #     number cards in player hand
    #     player bank
    #
    # RULES
    #   when x,y,z CONDITIONS are in effect, make a decision accordingly
    #   keep stats on rules...how often they are made, their win/loss/push %, and total $ won/lost
    #
    #   eg. RULE 33
    #
    #       STATE "Waiting for player next-card decision"
    #
    #       WHEN num_decks=2,
    #            10 percentage > 30,
    #            > 20 cards remain in shoe,    # CONDITIONS
    #            dealer up card 3,
    #            player hard total < 16
    #       THEN
    #            HIT                           # DECISION
    #
    # DECISIONS
    #   points in time that the player must decide their fate by applying RULES
    #     play hand/sit out/cash-out quit
    #     num hands to play simultaneously
    #     bet multiple (or $amount)
    #     take insurance on dealer A upcard?
    #     surrender?
    #     hit/stand/split/double action to take
    #
    # DECISION CHAINS
    #   records each decision made during a single hand dealt.  From these decisions, the distinct rules applied
    #   will have their stats updated.
    #
    # OUTCOMES
    #   win/lose/push
    #   money won/lost
    #
    # STATS
    #   keep track of outcomes on decision chain rules
    #
    attr_reader  :chain
    attr_reader  :player

    def initialize(player)
      @player = player
      @chain = []
    end

    def add(link)
      @chain << link
    end

    def evaluate
      @chain.each do |link|
        link.outcome(result, amount)
      end
    end
  end
end
