module Blackjack

  class PromptPlayerHandStrategy < PlayerHandStrategy
    #
    # this strategy will make a few automatic decisions, but
    # primarily prompts the Player for on how much to bet,
    # whether to Hit, Stand or Split, etc.
    #
    def initialize(table, player, options={})
      super
      setup_prompters
    end

    def decision(bet_box, dealer_up_card, other_hands=[])
      prompt_for_action(bet_box, dealer_up_card, other_hands)
    end

    def bet_amount
      @main_bet_maker.get_command.to_i
    end

    def insurance?(bet_box)
      bet_box.hand.blackjack? ? Action::EVEN_MONEY : Action::NO_INSURANCE
    end

    def insurance_bet_amount(bet_box)
      max_bet = bet_box.bet_amount/2.0
      insurance_bet_maker = CommandPrompter.new(player.name, "Insurance Bet Amount:int:1:#{max_bet}")
      insurance_bet_maker.suggestion = max_bet
      insurance_bet_maker.get_command.to_i
    end

    def double_down_bet_amount(bet_box)
      bet_box.bet_amount
    end

    def num_bets
      player.bank.balance <= player.bank.initial_deposit/8 ? Action::LEAVE : config[:num_bets]
    end

    def error(strategy_step, message)
      sep = "="*[80, (message.length)].min
      puts ''
      puts sep
      puts message
      puts sep
      puts ''
    end

    private

    def setup_prompters
      @get_user_decision = CommandPrompter.new(player.name, "Hit", "Stand", "Double", "sPlit")
      @map = {
        'h' => Action::HIT,
        's' => Action::STAND,
        'd' => Action::DOUBLE_DOWN,
        'p' => Action::SPLIT
      }

      min_bet = table.config[:minimum_bet]
      max_bet = table.config[:maximum_bet]
      @main_bet_maker = CommandPrompter.new(player.name, "Bet Amount:int:#{min_bet}:#{max_bet}")
      @main_bet_maker.suggestion = min_bet
    end

    def show_other_hands(other_hands)
      #
      # brief form so card counting can be done
      #
      puts other_hands
    end

    def show_dealer_up_card(up_card)
      up_card.print
    end

    def show_player_hand(player_hand)
      player_hand.print
    end

    def prompt_for_action(bet_box, dealer_up_card, other_hands=[])
      show_other_hands(other_hands)
      show_dealer_up_card(dealer_up_card)
      show_player_hand(bet_box.hand)
      @map[@get_user_decision.get_command]
    end
  end

  class PromptWithSuggestionStrategy < PromptPlayerHandStrategy

    attr_reader   :suggestion_strategy

    def initialize(table, player, options={})
      super
      @reverse_map = @map.invert 
      @suggestion_strategy = options[:suggestion_strategy]
    end

    def prompt_for_action(bet_box, dealer_up_card, other_hands=[])
      @get_user_decision.suggestion = @reverse_map[suggestion_strategy.decision(bet_box, dealer_up_card, other_hands)].upcase
      super
    end
  end

  class PromptWithBasicStrategyGuidance < PromptWithSuggestionStrategy
    def initialize(table, player, options={})
      super(table, player, options.merge(suggestion_strategy: BasicStrategy.new(table, player)))
    end
  end
end
