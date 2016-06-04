module Blackjack

  class TableDrivenStrategy < SimpleStrategy

    attr_reader  :strategy_table

    def initialize(table, player, strategy_table, options={})
      super(table, player, options)
      @strategy_table = strategy_table
    end

    def rule_name(bet_box, dealer_up_card)
      strategy_table.rule_name(dealer_up_card, bet_box.hand)
    end

    def num_bets
      num_bets = options[:num_bets]||super
      #
      # leave room in bank to double down on all hands bet
      #
      @minimum_bet = table.config[:minimum_bet]

      if num_bets > 1
        @minimum_bet *= 2 # house requires you make double min bet 
      end

      num_bets
    end

    def bet_amount(bet_box)
      @minimum_bet
    end

    def play(bet_box, dealer_up_card, other_hands=[])
      decision = strategy_table.play(dealer_up_card.face_value, bet_box.hand)
      modify_to_hit_if_unable_to_double_or_split(bet_box, decision)
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

    private

    def modify_to_hit_if_unable_to_double_or_split(bet_box, decision)
      case decision
        when Action::SPLIT
          # can't split if player doesn't have funds or reached table split limit
          (player.bank.balance < bet_box.bet_amount || !bet_box.can_split?) ? Action::HIT : decision
        when Action::DOUBLE_DOWN
          # can't double down if player doesn't have funds
          player.bank.balance == 0 ? Action::HIT : decision
        else
          decision
      end
    end

  end

  class BasicStrategy < TableDrivenStrategy
    def initialize(table, player, options={})
      super(table, player, BasicStrategyTable.new, options)
    end
  end
end
