module Blackjack

  class TableDrivenStrategy < PlayerHandStrategy

    attr_reader  :strategy_table

    def initialize(table, player, strategy_table)
      super(table, player)
      @strategy_table = strategy_table
    end

    def play?
      player.bank.balance >= player.bank.initial_deposit/4
    end

    def bet_amount
      table.config[:minimum_bet]
    end

    def insurance_bet_amount(bet_box)
      0
    end

    def double_down_bet_amount(bet_box)
      bet_box.bet_amount
    end

    def insurance?(bet_box)
      bet_box.hand.blackjack? ? Action::EVEN_MONEY : Action::NO_INSURANCE
    end

    def decision(bet_box, dealer_up_card, other_hands=[])
      strategy_table.decision(dealer_up_card, bet_box.hand)
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
      raise "#{strategy_step}: #{message}"
    end
  end

  class BasicStrategy < TableDrivenStrategy
    def initialize(table, player)
      super(table, player, BasicStrategyTable.new)
    end
  end
end
