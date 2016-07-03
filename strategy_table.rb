module Blackjack

  class StrategyTable
    # TODO: Need to refactor Strategy table to be a table of Rules
    # Based on Game Conditions, a Rule is looked up in the table
    # and returned with the decision the rule makes.
    #
    # pass in a custom strategy table (in the exact format below), or
    # default to the basic strategy table retrieved from the web
    #
    attr_reader  :lookup_table
    attr_reader  :double_split_option_table
    attr_reader  :formatted_table

    CODE_TO_ACTION = {
      'S'  => Action::STAND,
      'SP' => Action::SPLIT,
      'H'  => Action::HIT,
      'D'  => Action::DOUBLE_DOWN,
      '-'  => nil,
    }

    def initialize(formatted_table, formatted_double_split_option_table)
      @formatted_table = formatted_table
      @lookup_table = parse_table(formatted_table)
      @double_split_option_table = parse_table(formatted_double_split_option_table)
    end

    def decision_stat_name(dealer_up_card_value, hand)
      "%s:%s:%s" % rule_keys(dealer_up_card_value, hand)
    end

    def rule_keys(dealer_up_card_value, hand)
      keys = if hand.pair?
        [:pairs, hand[0].soft_value, dealer_up_card_value]
      elsif hand.soft? && hand.soft_sum <= BlackjackCard::ACE_HARD_VALUE
        [:soft, hand.soft_sum, dealer_up_card_value]
      else
        [:hard, hand.hard_sum, dealer_up_card_value]
      end
      Struct.new(:section, :player_hand_val, :dealer_up_card)[*keys]
    end

    def play(bet_box, dealer_up_card_value)
      lkup = rule_keys(dealer_up_card_value, bet_box.hand)

      decision_from_table = lookup_table[lkup.section][lkup.player_hand_val][lkup.dealer_up_card]

      final_decision = check_double_or_split_optional_handling(bet_box, decision_from_table, lkup)

      final_decision
    end

    def inspect
      formatted_table.join("\n")
    end

    private

    def check_double_or_split_optional_handling(bet_box, decision, lkup)
      #
      # Make sure the split/double decision is valid given the state of the player
      # hand and bank.   If not, a tweak in the decision will occur
      #
      return case decision
        when Action::DOUBLE_DOWN
          double_option(bet_box, lkup)
        when Action::SPLIT
          split_option(bet_box, lkup)
        else
          decision
      end
    end

    def double_option(bet_box, lkup)
      if bet_box.hand.length > 2 || !bet_box.player.balance_check(1)
        double_split_option_table[lkup.section][lkup.player_hand_val][lkup.dealer_up_card]
      else
        Action::DOUBLE_DOWN
      end
    end

    def split_option(bet_box, lkup)
      if !bet_box.can_split? || !bet_box.player.balance_check(bet_box.bet_amount)
        double_split_option_table[lkup.section][lkup.player_hand_val][lkup.dealer_up_card]
      else
        Action::SPLIT
      end
    end

    def parse_table(table)
      #
      # parsed_output[:soft][player_val][dealer_up_card] yields the player Action
      #
      parsed_output = {
        soft:  [], 
        hard:  [],
        pairs: []
      }

      #
      # hard values
      #  e.g
      #
      #   hard   |   2    3    4    5    6    7    8    9    10    A  
      # ---------+----------------------------------------------------
      #    16    |   S    S    S    S    S    H    H    H     H    H  
      #
      #   parsed_output[:hard][16] = [nil, 3, 4, 4, 4, 4, 4, 3, 3, 3, 3]
      #     (dealer up card)            0  A  2  3  4  5  6  7  8  9 10
      #
      start, finish = section_boundaries(table, :hard)
      table[start..finish].each do |line|
        sline = line.split("|")
        hard_sum = sline.first.to_i
        parsed_output[:hard][hard_sum] = encoded_actions_with_ace_rotated_to_front(sline.last.split(" "))
      end

      #
      # soft hands
      #
      #   soft   |   2    3    4    5    6    7    8    9    10    A  
      #  --------+----------------------------------------------------
      #    A,6   |   H    D    D    D    D    H    H    H     H    H  
      #
      #   parsed_output[:soft][7] = [nil, 3, 3, 6, 6, 6, 6, 3, 3, 3, 3]
      #     (dealer up card)           0  A  2  3  4  5  6  7  8  9 10
      #
      start, finish = section_boundaries(table, :soft)
      table[start..finish].each do |line|
        sline = line.split("|")
        soft_sum = sline.first.split(",").last.to_i + 1
        parsed_output[:soft][soft_sum] = encoded_actions_with_ace_rotated_to_front(sline.last.split(" "))
      end
 
      #
      # pairs
      #
      #   pairs  |   2    3    4    5    6    7    8    9    10    A 
      #  --------+----------------------------------------------------
      #    8-8   |   SP   SP   SP   SP   SP   SP   SP   SP    SP   SP
      #
      #   parsed_output[:pairs][8] = [nil, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5]
      #     (dealer up card)            0  A  2  3  4  5  6  7  8  9 10
      #
      start, finish = section_boundaries(table, :pairs)
      table[start..finish].each do |line|
        sline = line.split("|")
        half = sline.first.split("-").first
        pair_half_val = (half =~ /A/ ? 1 : half.to_i)
        parsed_output[:pairs][pair_half_val] = encoded_actions_with_ace_rotated_to_front(sline.last.split(" "))
      end

      parsed_output
    end

    def encoded_actions_with_ace_rotated_to_front(codes)
      codes[0..-2].unshift('-', codes.last).map {|code| CODE_TO_ACTION[code]}
    end

    def section_boundaries(table, section_name)
      sname = section_name.to_s
      start_ind = table.index {|l| l.split("|").first =~ %r{#{sname}}}
      start_ind += 2
      end_ind = table[start_ind..-1].index {|l| l =~ /----\+----/}
      [start_ind, end_ind + start_ind - 1]
    end
  end

  class BasicStrategyTable < StrategyTable
    BASIC_STRATEGY_TABLE = 
      [
        '                           Dealer Up Card                    ',
        '--------+----------------------------------------------------',
        ' hard   |   2    3    4    5    6    7    8    9    10    A  ',
        '--------+----------------------------------------------------',
        '  21    |   S    S    S    S    S    S    S    S     S    S  ',
        '  20    |   S    S    S    S    S    S    S    S     S    S  ',
        '  19    |   S    S    S    S    S    S    S    S     S    S  ',
        '  18    |   S    S    S    S    S    S    S    S     S    S  ',
        '  17    |   S    S    S    S    S    S    S    S     S    S  ',
        '  16    |   S    S    S    S    S    H    H    H     H    H  ',
        '  15    |   S    S    S    S    S    H    H    H     H    H  ',
        '  14    |   S    S    S    S    S    H    H    H     H    H  ',
        '  13    |   S    S    S    S    S    H    H    H     H    H  ',
        '  12    |   H    H    S    S    S    H    H    H     H    H  ',
        '  11    |   D    D    D    D    D    D    D    D     D    H  ',
        '  10    |   D    D    D    D    D    D    D    D     H    H  ',
        '   9    |   H    D    D    D    D    H    H    H     H    H  ',
        '   8    |   H    H    H    H    H    H    H    H     H    H  ',
        '   7    |   H    H    H    H    H    H    H    H     H    H  ',
        '   6    |   H    H    H    H    H    H    H    H     H    H  ',
        '   5    |   H    H    H    H    H    H    H    H     H    H  ',
        '--------+----------------------------------------------------',
        ' soft   |   2    3    4    5    6    7    8    9    10    A  ',
        '--------+----------------------------------------------------',
        '  A,10  |   S    S    S    S    S    S    S    S     S    S  ',
        '  A,9   |   S    S    S    S    S    S    S    S     S    S  ',
        '  A,8   |   S    S    S    S    S    S    S    S     S    S  ',
        '  A,7   |   S    D    D    D    D    S    S    H     H    H  ',
        '  A,6   |   H    D    D    D    D    H    H    H     H    H  ',
        '  A,5   |   H    H    D    D    D    H    H    H     H    H  ',
        '  A,4   |   H    H    D    D    D    H    H    H     H    H  ',
        '  A,3   |   H    H    H    D    D    H    H    H     H    H  ',
        '  A,2   |   H    H    H    D    D    H    H    H     H    H  ',
        '--------+----------------------------------------------------',
        ' pairs  |   2    3    4    5    6    7    8    9    10    A  ',
        '--------+----------------------------------------------------',
        '  A-A   |   SP   SP   SP   SP   SP   SP   SP   SP    SP   SP ',
        ' 10-10  |   S    S    S    S    S    S    S    S     S    S  ',
        '  9-9   |   SP   SP   SP   SP   SP   S    SP   SP    S    S  ',
        '  8-8   |   SP   SP   SP   SP   SP   SP   SP   SP    SP   SP ',
        '  7-7   |   SP   SP   SP   SP   SP   SP   H    H     H    H  ',
        '  6-6   |   SP   SP   SP   SP   SP   H    H    H     H    H  ',
        '  5-5   |   D    D    D    D    D    D    D    D     H    H  ',
        '  4-4   |   H    H    H    SP   SP   H    H    H     H    H  ',
        '  3-3   |   SP   SP   SP   SP   SP   SP   H    H     H    H  ',
        '  2-2   |   SP   SP   SP   SP   SP   SP   H    H     H    H  ',
        '--------+----------------------------------------------------'
      ]

    DOUBLE_SPLIT_OPTION_TABLE =
      [
        '                           Dealer Up Card                    ',
        '--------+----------------------------------------------------',
        ' hard   |   2    3    4    5    6    7    8    9    10    A  ',
        '--------+----------------------------------------------------',
        '  11    |   H    H    H    H    H    H    H    H     H    H  ',
        '  10    |   H    H    H    H    H    H    H    H     H    H  ',
        '   9    |   H    H    H    H    H    H    H    H     H    H  ',
        '--------+----------------------------------------------------',
        ' soft   |   2    3    4    5    6    7    8    9    10    A  ',
        '--------+----------------------------------------------------',
        '  A,7   |   S    H    H    H    H    S    S    H     H    H  ',
        '  A,6   |   H    H    H    H    H    H    H    H     H    H  ',
        '  A,5   |   H    H    H    H    H    H    H    H     H    H  ',
        '  A,4   |   H    H    H    H    H    H    H    H     H    H  ',
        '  A,3   |   H    H    H    H    H    H    H    H     H    H  ',
        '  A,2   |   H    H    H    H    H    H    H    H     H    H  ',
        '--------+----------------------------------------------------',
        ' pairs  |   2    3    4    5    6    7    8    9    10    A  ',
        '--------+----------------------------------------------------',
        '  9-9   |   S    S    S    S    S    S    S    S     S    S  ',
        '  8-8   |   S    S    S    S    S    H    H    H     H    H  ',
        '  7-7   |   S    S    S    S    S    H    H    H     H    H  ',
        '  6-6   |   H    H    S    S    S    H    H    H     H    H  ',
        '  5-5   |   H    H    H    H    H    H    H    H     H    H  ',
        '  4-4   |   H    H    H    H    H    H    H    H     H    H  ',
        '  3-3   |   H    H    H    H    H    H    H    H     H    H  ',
        '  2-2   |   H    H    H    H    H    H    H    H     H    H  ',
        '  A,A   |   H    H    H    H    H    H    H    H     H    H  ',
        '--------+----------------------------------------------------'
      ]

      def initialize
        super(BASIC_STRATEGY_TABLE, DOUBLE_SPLIT_OPTION_TABLE)
      end
    end

end
