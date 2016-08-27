require 'card'

module Cards
  class AsciiCardPrinter
    CARD_TOP    = ".-------." # 0

    SUIT_PATTERNS = {
      HEARTS => [
        "|%2s_  _ |",  # 1
        '| ( \/ )|',   # 2
        '|  \  / |',   # 3
        "|   \\/%2s|"  # 4
      ],
      DIAMONDS => [
        "|%2s /\\  |",
        '|  /  \ |',
        '|  \  / |',
        "|   \\/%2s|"
      ],
      CLUBS => [
        "|%2s _   |",
        "|  ( )  |",
        "| (_x_) |",
        "|   Y %2s|"
      ],
      SPADES => [
        "|%2s .   |",
        '|  / \  |',
        "| (_,_) |",
        "|   I %2s|"
      ]
    }

    CARD_BOTTOM = "`-------'" # 5

    DOUBLE_X = "| x   x |"
    SINGLE_X = "|   x   |"

    NUM_PRINT_ROWS=6
    DFLT_CARDS_PRINTED_PER_LINE=7

    def print(cards, options={})
      per_line = options.fetch(:per_line) {DFLT_CARDS_PRINTED_PER_LINE}
      value = options.fetch(:value) {nil}
      output = [*cards].each_slice(per_line).map do |set|
        print_slice(set)
      end.join("\n") + (value.nil? ? "" : " #{value}")
      puts output
    end

    private 

    def print_slice(slice)
      [].tap do |s|
        NUM_PRINT_ROWS.times {|i| s << print_cards(slice, i)}
      end.join("\n")
    end

    def print_cards(cards, i)
      cards.map {|card| print_row(card, i)}.join("  ")
    end

    def print_row(card, n)
      case n
        when 0
          CARD_TOP
        when 1,4
          card.face_up? ? SUIT_PATTERNS[card.suit][n-1] % card.face : DOUBLE_X
        when 2,3
          card.face_up? ? SUIT_PATTERNS[card.suit][n-1] : SINGLE_X
        when 5
          CARD_BOTTOM
      end
    end
  end
end
