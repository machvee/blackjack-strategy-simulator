module Blackjack

  class StrategyTable
    #
    # pass in an encoded strategy table (see BasicStrategyTable below for example)
    # and this class will build a table of StrategyRules that can be used to
    # provide Actions for PlayerHandStrategy#play responses
    #
    attr_reader  :lookup_table
    attr_reader  :formatted_table

    CODE_TO_ACTION = {
      'S'  => Action::STAND,
      'SP' => Action::SPLIT,
      'H'  => Action::HIT,
      'D'  => Action::DOUBLE_DOWN,
      '-'  => nil,
    }

    TWO_CARDS='2'
    TWO_PLUS_CARDS= '+'

    CODE_TO_ACTION_PLUS = {
      TWO_CARDS => CODE_TO_ACTION,
      TWO_PLUS_CARDS => CODE_TO_ACTION.merge('D' => Action::HIT)
    }

    def initialize(formatted_table)
      @formatted_table = formatted_table
      @lookup_table = parse_table
    end

    def play(dealer_up_card_value, player_hand)
      table_section,
      player_hand_val,
      dealer_hand_val,
      two_card_key = rule_keys(dealer_up_card_value, player_hand)

      rule_from_table = lookup_table[table_section][two_card_key][player_hand_val][dealer_hand_val]
    end

    def inspect
      formatted_table.join("\n")
    end

    private

    def table_lookup(table_section, player_hand_val, dealer_hand_val)
      rule_from_table = lookup_table[table_section][player_hand_val][dealer_hand_val]
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
      end + [dealer_up_card_value, player_hand.length == 2 ? TWO_CARDS : TWO_PLUS_CARDS]
    end

    def rule_name(section, dealer_up_card_value, player_hand_val, two_card_key)
      "%s:%s:%s:%s" % [section, dealer_up_card_value, player_hand_val, two_card_key]
    end

    def init_parsed_rules
      {TWO_CARDS => [], TWO_PLUS_CARDS => []}
    end

    def parse_table
      #
      # parsed_output[:soft][player_val][dealer_up_card] yields the player Action
      #
      parsed_output = {
        soft:  init_parsed_rules,
        hard:  init_parsed_rules,
        pairs: init_parsed_rules
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
      parse_section_lines_to_rules(parsed_output, :soft) do |sline|
        sline.first.to_i
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
      parse_section_lines_to_rules(parsed_output, :soft) do |sline|
        sline.first.split(",").last.to_i + 1
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
      parse_section_lines_to_rules(parsed_output, :pairs) do |sline|
        half = sline.first.split("-").first
        (half =~ /A/ ? 1 : half.to_i)
      end

      parsed_output
    end

    def parse_section_lines_to_rules(section_name, &block)
      start, finish = section_boundaries(section_name)
      formatted_table[start..finish].each do |line|
        sline = line.split("|")
        player_hand_key = yield(sline)
        codes = sline.last.split(" ")
        parsed_output[section_name].keys.each do |two_card_key|
          parsed_output[section_name][two_card_key][player_hand_key] =
            codes[0..-2].unshift('-', codes.last).map.with_index do |action_code, dealer_hand_key|
              name = rule_name(section, dealer_hand_key, player_hand_key, two_card_key)
              StrategyRule.new(name, CODE_TO_ACTION_PLUS[two_card_key][action_code])
            end
        end
    end

    def section_boundaries(section_name)
      sname = section_name.to_s
      start_ind = formatted_table.index {|l| l.split("|").first =~ %r{#{sname}}}
      start_ind += 2
      end_ind = formatted_table[start_ind..-1].index {|l| l =~ /----\+----/}
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

      def initialize
        super(BASIC_STRATEGY_TABLE)
      end
    end

end
