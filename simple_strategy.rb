module Blackjack
  class SimpleStrategy < PlayerHandStrategy
    #
    # takes easy/recommended/default actions, leaving more important
    # decisions to sub-classes
    #
    def initialize(table, player, options={})
      @num_rounds = options[:num_rounds]
      @round_count = 0
      super
    end

    def stay?
      return Action::PLAY if @num_rounds.nil?
      @round_count += 1
      @round_count > @num_rounds ?  Action::LEAVE : Action::PLAY
    end

    def num_hands
      @num_hands = options[:num_hands]||1
    end

    def bet_amount
      amt = table.config[:minimum_bet]
      @num_hands > 1 ? amt * table.config[:multi_hand_multiple] : amt 
    end

    def insurance?(bet_box)
      bet_box.hand.blackjack? ? Action::EVEN_MONEY : Action::NO_INSURANCE
    end

    def insurance_bet_amount(bet_box)
      bet_box.bet_amount/2
    end

    def double_down_bet_amount(bet_box)
      bet_box.bet_amount
    end

    def error(decision, message)
      raise "#{decision}: #{message}"
    end
  end
end
