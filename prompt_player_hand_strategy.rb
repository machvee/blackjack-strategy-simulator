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

    def stay?
      #
      # to prevent having to endless prompt the human player "Do you want to stay?"
      # we'll make stay? the bet prompter.  If a player is out of money
      # and doesn't get a marker, or he decides to bet $0, we'll take that
      # as a Action::LEAVE.  Else Action::STAY
      #
      if player.bank.balance < table.config[:minimum_bet]
        puts "You're down to #{player.bank.balance} which is below the minimum bet."
        resp = @marker_prompter.get_command
        amt = (resp == 'q' ? 0 : resp.to_i)
        player.marker_for(amt) if amt != 0
      end
      
      bet_response = @main_bet_maker.get_command
      if bet_response == 'q'
        Action::LEAVE
      else
        @bet_amount = bet_response.to_i
        Action::PLAY
      end
    end

    def play(bet_box, dealer_up_card, other_hands=[])
      prompt_for_action(bet_box, dealer_up_card, other_hands)
    end

    def bet_amount
      @main_bet_maker.suggestion = @bet_amount
      @bet_amount
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
      [bet_box.bet_amount, player.bank.balance].min
    end

    def num_hands
      options[:num_hands]
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

      @map = {
        'h' => Action::HIT,
        's' => Action::STAND,
        'd' => Action::DOUBLE_DOWN,
        'p' => Action::SPLIT
      }

      min_bet = table.config[:minimum_bet]
      max_bet = table.config[:maximum_bet]

      @get_user_decision = CommandPrompter.new(player.name, "Hit", "Stand", "Double", "sPlit")
      @marker_prompter = CommandPrompter.new(player.name, "Marker Amount:int:0:#{player.bank.initial_deposit}")
      @marker_prompter.suggestion = player.bank.initial_deposit

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
      hand_val = "#{player_hand.soft_sum}" +
        (player_hand.soft_sum < player_hand.hard_sum ? "/#{player_hand.hard_sum}" : "")
      player_hand.print(value: hand_val)
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
      @get_user_decision.suggestion = @reverse_map[suggestion_strategy.play(bet_box, dealer_up_card, other_hands).first].upcase
      super
    end
  end

  class PromptWithBasicStrategyGuidance < PromptWithSuggestionStrategy
    def initialize(table, player, options={})
      super(table, player, options.merge(suggestion_strategy: BasicStrategy.new(table, player)))
    end
  end
end
