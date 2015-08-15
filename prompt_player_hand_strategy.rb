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
      @bets_to_make = options[:bets_to_make_each_play]||1
      @bet_count = 0
    end

    def decision(bet_box, dealer_up_card, other_hands=[])
      @bet_count = 0
      player_hand = bet_box.hand
      show_other_hands(other_hands)
      show_dealer_up_card(dealer_up_card)
      show_player_hand(player_hand)
      prompt_for_action
    end

    def bet_amount
      @main_bet_maker.get_command.to_i
    end

    def insurance?(bet_box)
      Action::NO_INSURANCE
    end

    def insurance_bet_amount(bet_box)
      max_bet = bet_box.bet_amount/2.0
      insurance_bet_maker = CommandPrompter.new("Insurance Bet Amount:int:1:#{max_bet}")
      insurance_bet_maker.default_value = max_bet
      insurance_bet_maker.get_command.to_i
    end

    def double_down_bet_amount(bet_box)
      max_bet = bet_box.bet_amount
      double_down_bet_maker = CommandPrompter.new("Double Down Bet Amount:int:1:#{max_bet}")
      double_down_bet_maker.default_value = max_bet
      double_down_bet_maker.get_command.to_i
    end

    def num_bets
      player.bank.balance <= player.bank.initial_deposit/8 ? Action::LEAVE : @bets_to_make
    end

    def outcome(win_lose_draw, dealer_hand)
      dealer_hand.print
      puts "Dealer has #{dealer_hand.hard_sum}"
      case win_lose_draw
        when Outcome::WON
          puts "You WON"
        when Outcome::LOST
          puts "You LOST"
        when Outcome::PUSH
          puts "PUSH"
      end
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
      @get_user_decision = CommandPrompter.new("Hit", "Stand", "Double", "sPlit")
      @get_user_decision.default_value = "H"
      @map = {
        'h' => Action::HIT,
        's' => Action::STAND,
        'd' => Action::DOUBLE_DOWN,
        'p' => Action::SPLIT
      }

      min_bet = table.config[:minimum_bet]
      max_bet = table.config[:maximum_bet]
      @main_bet_maker = CommandPrompter.new("Bet Amount:int:#{min_bet}:#{max_bet}")
      @main_bet_maker.default_value = min_bet
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

    def prompt_for_action
      @map[@get_user_decision.get_command]
    end
  end
end
