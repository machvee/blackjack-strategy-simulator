module Blackjack

  class RuleBasedStrategy < PlayerHandStrategy

    # TableDrivenStrategy should override RuleBasedStrategy as there
    # is a rule table that drives the decision can define OutcomeStats
    #
    # the motivation behind this class is to have
    # a PHS that keeps StrategyStats for each decision made.  The
    # methods that are overriden here provide the choices based on
    # rules.  The PHS methods call the decisions but also keep
    # stats and decision chains on the rules via an included class
    # StrategyStats.  The sub-class author of an RBS must provide a
    # rule-name for the particular decision stat ("pairs:A" or "hard:16").
    # outcome method will update the stats on the decision chain
    #
    def initialize(table, player, options)
    end

    def outcome(win_lose_push, dealer_hand, amount)
      strategy.stats.update(win_loss_push, need_wagered, amount)
      strategy.outcome(win_lose_push, dealer_hand, amount)
    end

    def num_bets
      strategy.num_bets
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
