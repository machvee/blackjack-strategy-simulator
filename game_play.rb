module Blackjack
  class StrategyQuitter < StandardError; end

  class GamePlay
    attr_reader   :table
    attr_reader   :dealer
    attr_reader   :players

    def initialize(table, options={})
      @table =  table
      @dealer = table.dealer
      @players = table.seated_players
    end

    def run(options={})
      @hand_count = 0
      @num_hands = (options[:num_hands]||"10000").to_i
      begin
        table.game_announcer.says("Hands: #@num_hands, Seed: #{table.seed}")
        while players_at_table?
          shuffle_check
          announce_game_state
          wait_for_player_bets
          play_a_hand_of_blackjack if any_player_bets?

          @hand_count += 1
          reset
          break if @hand_count == @num_hands
        end
        exit_run
      rescue StrategyQuitter => q
        exit_run("Run aborted")
      end
    end

    def reset
      table.bet_boxes.reset
    end

    def exit_run(msg="Run complete")
      table.game_announcer.says("#{msg}. Goodbye.")
      table.game_announcer.says("")
      announce_game_state
    end

    def play_a_hand_of_blackjack
      opening_deal
      announce_hands

      unless dealer_has_blackjack?
        payout_any_blackjacks
        players_play_their_hands
        dealer_plays_hand
      end
      pay_any_winners
    end

    def opening_deal
      # 
      # 1. Players have put amounts of money in bet_boxes (or are sitting out) and
      #    have indicated ready
      # 2. dealer from his left to right, deals one card face up to each active? bet_box
      # 3. dealer deals himself one card face up (up-card)
      # 4. dealer from his left to right, deals one additional card face up to each active bet_box
      # 5. dealer deals himself one card face down (hole-card)
      #
      table.rounds_played.incr

      dealer.deal_one_card_face_up_to_each_active_bet_box
      dealer.deal_up_card
      dealer.deal_one_card_face_up_to_each_active_bet_box
      dealer.deal_hole_card
    end

    def dealer_has_blackjack?
      #
      # 1. If the dealers up-card is an Ace:
      #     a. invokes each active bet_box player's PlayerStrategy#insurance?  Response can be
      #        YES, NO, or EVEN_MONEY (the player must have 21)
      #     b. if YES, the player makes an insurance bet up to 1/2 the amount in bet_box in the insurance box
      #     c. if EVEN_MONEY, dealer pays the player the blackjack payout and player hand is discarded
      #     d. all players must respond, and when they all have the dealer checks his hole-card and:
      #     e. If has blackjack:
      #          - hole-card is turned over
      #          - each YES gets paid 1-1 and players transfer from table to bank
      #          - each NO gets bet transferred from table to house
      #          - all player's hands are discarded
      #     f. If doesn't have blackjack
      #          - each YES gets bet transferred from table to house
      # 2. If the dealers up-card is a 10-point:
      #     a. dealer checks hole-card, and if Ace, turns over and:
      #          - if player has natural 21, PUSH, else bet transferred from table to house
      #          - all player hands are discarded
      # 3. If the dealer's up-card is not A or 10-point:
      #     a. check each players hand for blackjack, pay them the BJ payout, and discard the players hand
      #
      # returns true if dealer had blackjack, else false
      #
      if dealer.up_card.ace?
        table.insurance.ask_players_if_they_want_insurance
      elsif !dealer.up_card.ten?
        return false
      end

      has_black_jack = dealer.hand.blackjack?
      if has_black_jack
        dealer.up_card.ten? ? dealer.ten_up_blackjacks.incr : dealer.ace_up_blackjacks.incr
        dealer.flip_hole_card
        table.insurance.payout_any_insurance_bets
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
          player.blackjack(bet_box)
          bet_box.discard
        end
      end
    end

    def players_at_table?
      table.any_seated_players?
    end

    def shuffle_check
      if table.shoe.needs_shuffle?
        table.shoe.shuffle
        table.game_announcer.says("Shuffling [%d]...Marker card placed." % table.shoe.num_shuffles.count)
        table.shoe.place_marker_card
      end
    end

    def any_player_bets?
      table.bet_boxes.any_bets?
    end

    def players_play_their_hands
      table.bet_boxes.each_active do |bet_box|
        player_plays_hand_until_end(bet_box)
      end
    end

    def player_plays_hand_until_end(bet_box)
 
      player = bet_box.player

      while(true) do

        response = (bet_box.hand.twentyone? || bet_box.from_split_aces?) ? Action::STAND : dealer.ask_player_decision(bet_box)

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
              player_plays_hand_until_end(split_bet_box)
            end
            break
          when Action::DOUBLE_DOWN
            double_down_bet_amt = dealer.ask_player_double_down_bet_amount(bet_box)
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
      dealer.hands_busted.incr if dealer.busted?

      table.bet_boxes.each_active do |bet_box|
        player = bet_box.player
        player_has = bet_box.hand.hard_sum
        if dealer.busted? || player_has > dealer_has
          dealer.player_won(bet_box, Table::EVEN_MONEY_PAYOUT)
          dealer.hands_lost.incr
        elsif dealer_has > player_has
          dealer.player_lost(bet_box)
          dealer.hands_won.incr
        else
          dealer.player_push(bet_box)
          dealer.hands_pushed.incr
        end
        bet_box.discard
      end
      dealer.discard_hand
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

    def wait_for_player_bets
      table.each_player do |player|
        num_bets = dealer.ask_player_num_bets(player)
        case num_bets
          when Action::LEAVE
            player.leave_table
            next
          else
            bet_counter = 0
            table.bet_boxes.available_for(player) do |bet_box|
              break if bet_counter == num_bets
              bet_amount = dealer.ask_player_bet_amount(player, bet_box)
              player.make_bet(bet_amount, bet_box)
              bet_counter += 1
            end 
        end 
      end
    end

  end
end
