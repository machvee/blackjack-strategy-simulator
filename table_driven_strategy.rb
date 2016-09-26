module Blackjack

  class TableDrivenStrategy < SimpleStrategy

    attr_reader  :strategy_table

    def initialize(table, player, strategy_table, options={})
      super(table, player, options)
      @strategy_table = strategy_table
    end

    def play(bet_box, dealer_up_card, other_hands=[])
      dec = strategy_table.play(bet_box, dealer_up_card.face_value)
    end

  end

  class BasicStrategy < TableDrivenStrategy
    def initialize(table, player, options={})
      super(table, player, BasicStrategyTable.new(player), options)
    end
  end
end
