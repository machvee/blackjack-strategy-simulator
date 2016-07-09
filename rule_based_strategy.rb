module Blackjack

  class RuleBasedStrategy < PlayerHandStrategy

    #
    # given the params to the strategy step function, lookup and return the
    # StrategyRule.  The StrategyRule lookup is a method is sub-classed.
    # The StrategyRule is added to the RuleChain for the current hand play
    # When the outcome is determined, the chain is traversed, and the outcome
    # and amounts are tallied for in the stats for each StrategyRule.
    #

    def initialize(table, player, options)
    end

    def outcome(win_lose_push, dealer_hand, amount)
      strategy.stats.update(win_loss_push, need_wagered, amount)
      strategy.outcome(win_lose_push, dealer_hand, amount)
    end

    def num_hands
      strategy.num_hands
    end

    def bet_amount(bet_box)
      strategy.bet_amount(bet_box).tap do |amount|
        bet_box.decision_chain.add(:bet_amount, amount)
      end
    end

    def insurance?(bet_box)
      strategy.insurance?(bet_box).tap do |yes_no|
        bet_box.decision_chain.add(:insurance, yes_no)
      end
    end

    def insurance_bet_amount(bet_box)
      #
      # no stats for now
      #
      strategy.insurance_bet_amount(bet_box)
    end

    def decision(bet_box, dealer_up_card, other_hands=[])
      # either decision has to return the decision name ("pairs:AA", "hard:16"), or
      # it should be responsible for adding to the decision chain
      #
      strategy.decision(bet_box, dealer_up_card, other_hands).tap do |decision|
        bet_box.decision_chain.add(
          :decision,
          strategy.decision_stat_name(bet_box, dealer_up_card, other_hands)
        )
      end
    end

    def double_down_bet_amount(bet_box)
      #
      # no stats for now
      #
      strategy.double_down_bet_amount(bet_box)
    end

    def error(bet_box, strategy_step, message)
      bet_box.decision_chain.pop
      strategy.error(bet_box, strategy_step, message)
    end
  end
end
