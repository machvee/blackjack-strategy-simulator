module Blackjack

  class TableDrivenStrategy < PlayerHandStrategy

    attr_reader  :strategy_table

    def initialize(table, player, strategy_table, options={})
      super(table, player, options)
      @strategy_table = strategy_table
    end

    def stay?
      Action::PLAY
    end

    def num_bets
      num_bets = options[:num_bets]||1
      #
      # leave room in bank to double down on all hands bet
      #
      @minimum_bet = table.config[:minimum_bet]
      current_balance = player.bank.balance

      if num_bets > 1
        @minimum_bet *= 2 # house requires you make double min bet 
      end

      if current_balance < (@minimum_bet * num_bets)
        player.marker_for(player.config[:start_bank])
        table.game_announcer.says("%s gets a marker for $%d" % [player.name, player.config[:start_bank]])
      end

      num_bets
    end

    def bet_amount(bet_box)
      @minimum_bet
    end

    def insurance_bet_amount(bet_box)
      bet_box.bet_amount/2
    end

    def double_down_bet_amount(bet_box)
      [bet_box.bet_amount, bet_box.player.bank.balance].min
    end

    def insurance?(bet_box)
      bet_box.hand.blackjack? ? Action::EVEN_MONEY : Action::NO_INSURANCE
    end

    def decision_stat_name(bet_box, dealer_up_card, other_hands=[])
      strategy_table.decision_stat_name(dealer_up_card.face_value, bet_box.hand)
    end

    def play(bet_box, dealer_up_card, other_hands=[])
      dec = strategy_table.play(dealer_up_card.face_value, bet_box.hand)
      return case dec
        when Action::SPLIT
          # can't split if player doesn't have funds
          player.bank.balance < bet_box.bet_amount ? Action::HIT : dec
        when Action::DOUBLE_DOWN
          # can't double down if player doesn't have funds
          player.bank.balance == 0 ? Action::HIT : dec
        else
          dec
      end
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
    def initialize(table, player, options={})
      super(table, player, BasicStrategyTable.new, options)
    end
  end
end
