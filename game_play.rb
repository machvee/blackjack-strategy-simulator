module Blackjack
  class GamePlay
    attr_reader   :table
    attr_reader   :dealer
    attr_reader   :players

    include CounterMeasures

    counters :hands_dealt

    def initialize(table, options={})
      @table =  table
      @dealer = table.dealer
      @players = table.seated_players
    end

    def run(options={})
      hands_dealt.reset
      while players_at_table?
        shuffle_check
        players_make_bets
        play_a_hand_of_blackjack if any_player_bets?
      end
      exit_run
    end

    def exit_run(msg="Run complete")
      table.game_announcer.says("#{msg}. Goodbye.")
      table.game_announcer.says("")
      announce_game_state
    end

    def play_a_hand_of_blackjack
      hands_dealt.incr
      opening_deal
      announce_hands

      unless dealer_has_blackjack?
        payout_any_blackjacks
        players_play_their_hands
        dealer_plays_hand
      end
      pay_any_winners
      reset
    end

    def opening_deal
      table.stats.rounds_played.incr

      dealer.deal_first_up_card_to_each_active_bet_box
      dealer.deal_up_card
      dealer.deal_one_card_face_up_to_each_active_bet_box
      dealer.deal_hole_card
    end

    def dealer_has_blackjack?
      if dealer.up_card.ace?
        table.insurance.ask_players_if_they_want_insurance
      elsif !dealer.up_card.ten?
        return false
      end

      has_black_jack = dealer.hand.blackjack?
      if has_black_jack
        dealer.flip_hole_card
        table.insurance.payout_any_insurance_bets
        dealer.stats.blackjack
      else
        table.game_announcer.says("Dealer doesn't have Blackjack")
        table.insurance.collect_insurance_bets
      end
      has_black_jack
    end

    def payout_any_blackjacks
      table.bet_boxes.each_active do |bet_box|
        player = bet_box.player
        if bet_box.hand.blackjack?
          dealer.player_won(bet_box, table.config[:blackjack_payout])
          player.blackjack(bet_box, bet_box.hand[0])
          bet_box.discard
        end
      end
    end

    def players_at_table?
      announce_game_state
      table.each_player do |player|
        decision = player.decisions[:stay].prompt
        player.leave_table if decision == Action::LEAVE
      end
      table.any_seated_players?
    end

    def shuffle_check
      if table.shoe.needs_shuffle?
        table.game_announcer.says("Shuffling %d Deck Shoe [%d] after %d hands...Marker card placed." %
          [table.shoe.num_decks, table.shoe.num_shuffles.count, table.shoe.hands_dealt.tally])
        table.shoe.shuffle
        table.shoe.place_marker_card
      end
    end

    def any_player_bets?
      table.bet_boxes.any_bets?
    end

    def players_play_their_hands
      table.bet_boxes.each_active do |bet_box|
        player_plays_hand(bet_box)
      end
    end

    def player_plays_hand(bet_box)
 
      player = bet_box.player

      while(true) do

        response = player_must_stand?(bet_box) ? Action::STAND : bet_box.player_decisions[:play].prompt

        case response
          when Action::HIT
            deal_player_card(bet_box)
            if dealer.check_player_hand_busted?(bet_box)
              table.game_announcer.hand_outcome(bet_box, Outcome::BUST, bet_box.bet_amount)
              player.busted(bet_box)
              dealer.money.collect_bet(bet_box)
              bet_box.discard
              break
            end
            announce_hand(bet_box, response)
          when Action::STAND
            announce_hand(bet_box, response)
            break
          when Action::SPLIT
            bet_box.split
            bet_box.iter do |split_bet_box|
              deal_player_card(split_bet_box)
              announce_hand(split_bet_box, response)
              player_plays_hand(split_bet_box)
            end
            break
          when Action::DOUBLE_DOWN
            double_down_bet_amt = bet_box.player_decisions[:double_down_bet_amount].prompt
            bet_box.double_down(double_down_bet_amt)
            deal_player_card(bet_box)
            announce_hand(bet_box, response, double_down_bet_amt)
            break
          when Action::SURRENDER
            table.game_announcer.says("%s SURRENDERS", player.name)
            player.surrendered(bet_box)
            bet_box.box.transfer_to(table.house, bet_amount/2.0)
            bet_box.box.transfer_to(player.bank, bet_amount/2.0)
            bet_box.discard
            break
        end
      end
    end

    def deal_player_card(bet_box)
      dealer.deal_card_face_up_to(bet_box)
    end

    def pay_any_winners
      dealer_has = dealer.hand.hard_sum
      dealer.bust_check

      table.bet_boxes.each_active do |bet_box|
        player = bet_box.player
        player_has = bet_box.hand.hard_sum
        if dealer.busted? || player_has > dealer_has
          dealer.player_won(bet_box, Table::EVEN_MONEY_PAYOUT)
        elsif dealer_has > player_has
          dealer.player_lost(bet_box)
        else
          dealer.player_push(bet_box)
        end
        bet_box.discard
      end
      dealer.discard_hand
    end

    def reset
      table.bet_boxes.reset
    end

    def player_must_stand?(bet_box)
      bet_box.hand.twentyone? || bet_box.from_split_aces?
    end

    def dealer_plays_hand
      dealer.flip_hole_card
      dealer.play_hand if any_player_bets?
    end

    def announce_hands
      table.game_announcer.dealer_hand_status
      table.bet_boxes.each_active { |bet_box| announce_hand(bet_box) }
    end

    def announce_hand(bet_box, decision=nil, opt_bet_amt=nil)
      table.game_announcer.player_hand_status(bet_box, decision, opt_bet_amt)
    end

    def announce_game_state
      table.game_announcer.overview
    end

    def players_make_bets
      table.each_player do |player|
        num_hands = player.decisions[:num_hands].prompt
        hand_counter = 0
        table.bet_boxes.available_for(player) do |bet_box|
          break if hand_counter == num_hands
          bet_amount = player.decisions[:bet_amount].prompt
          player.make_bet(bet_amount, bet_box)
          hand_counter += 1
        end 
      end
    end
  end
end
