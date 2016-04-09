module Blackjack
  module Cards
    class AsciiCard
      CARD_TOP    = ".-------." # 0

      SUIT_PATTERNS = {
        Card::HEARTS => [
          "|%2s_  _ |", # 1
          '| ( \/ )|',  # 2
          '|  \  / |',  # 3
          "|   \\/%2s|"  # 4
        ],
        Card::DIAMONDS => [
          "|%2s /\\  |",
          '|  /  \ |',
          '|  \  / |',
          "|   \\/%2s|"
        ],
        Card::CLUBS => [
          "|%2s _   |",
          "|  ( )  |",
          "| (_x_) |",
          "|   Y %2s|"
        ],
        Card::SPADES => [
          "|%2s .   |",
          '|  / \  |',
          "| (_,_) |",
          "|   I %2s|"
        ]
      }

      CARD_BOTTOM = "`-------'" # 5

      NUM_PRINT_ROWS=6

      def self.print_row(card, n)
        case n
          when 0
            CARD_TOP
          when 1,4
            card.face_up? ? SUIT_PATTERNS[card.suit][n-1] % card.face : "| x   x |"
          when 2,3
            card.face_up? ? SUIT_PATTERNS[card.suit][n-1] : "|   x   |"
          when 5
            CARD_BOTTOM
        end
      end

      def self.print(card_arg, opt_val=nil)
        card_arg.is_a?(Array) ? print_cards(card_arg, opt_val) : print_card(card_arg, opt_val)
        nil
      end

      def self.print_card(card, opt_val=nil)
        NUM_PRINT_ROWS.times do |i|
          puts print_row(card, i)
        end
      end

      DFLT_MAX_CARDS_PRINTED_PER_LINE=7

      def self.print_cards(cards, opt_val=nil, max_per_line=DFLT_MAX_CARDS_PRINTED_PER_LINE)
        cards.each_slice(max_per_line) do |set|
          print_set(set, opt_val)
        end
      end

      def self.print_set(set, opt_val=nil)
        sep = "  "
        iter = NUM_PRINT_ROWS-1
        iter.times do |i|
          puts set.map {|card| print_row(card, i)}.join(sep)
        end
        puts (set.map {|card| print_row(card, iter)}+[opt_val]).compact.join(sep)
      end
    end
  end
end
