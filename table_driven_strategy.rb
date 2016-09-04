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

    def error(strategy_step, message)
      #
      # Dealer will call this with a message string when/if the PlayerHandStrategy
      # would respond with something invalid during the above strategy_steps
      # and then invokes the offending method again
      #
      #  (e.g. :decision, :insurance, :bet_amount, or :play)
      #
      # e.g. raise "invalid entry for #{strategy_step}: #{message}"
      # 
      raise "#{strategy_step.class.name}: #{message}"
    end

  end

  class BasicStrategy < TableDrivenStrategy
    def initialize(table, player, options={})
      super(table, player, BasicStrategyTable.new, options)
    end
  end
end
