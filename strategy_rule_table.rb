module Blackjack

  class StrategyRuleTable < StrategyTable
    attr_reader   :rules

    def initialize(formatted_table)
      @formatted_table = formatted_table
      @lookup_table = parse_table
      @rules = Hash.new {|h,k| h[k] = StrategyRule.new(*k)}
    end

    def rule_name(dealer_up_card_value, player_hand)
      "%s:%s:%s:%s" % rule_keys(dealer_up_card_value, player_hand, player_hand.length == 2 ? "i" : "+")
    end

    def rule_keys(dealer_up_card_value, player_hand)
      #
      # returns [lookup_section, player_hand value, dealer up card]
      #
      if player_hand.pair?
        [:pairs, player_hand[0].soft_value]
      elsif player_hand.soft? && player_hand.soft_sum <= BlackjackCard::ACE_HARD_VALUE
        [:soft, player_hand.soft_sum]
      else
        [:hard, player_hand.hard_sum]
      end + [dealer_up_card_value]
    end

    def play(dealer_up_card_value, player_hand)
      rule = rules[rule_keys(dealer_up_card_value, player_hand)]

      decision_from_table = lookup_table[table_section][player_hand_val][dealer_hand_val]

      check_can_only_double_down_on_two_cards_and_return_decision(player_hand, decision_from_table)
    end
  end
end
