module Blackjack
  class GamePlay
    attr_reader   :table
    attr_reader   :dealer
    attr_reader   :players

    def initialize(table, options={})
      @table =  table
      @dealer = table.dealer
      @players = table.seated_players
    end

    def run
      while players_at_table?
        shuffle_check
        wait_for_player_bets
        play_a_hand_of_blackjack if any_player_bets?
        reset
      end
      table.game_announcer.says("Table has no players.  Goodbye.")
    end

    def reset
      table.bet_boxes.reset
    end

    def play_a_hand_of_blackjack
      opening_deal

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
      dealer.deal_one_card_face_up_to_each_active_bet_box
      dealer.deal_up_card
      dealer.deal_one_card_face_up_to_each_active_bet_box
      dealer.deal_hole_card
      announce_hands
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
        table.bet_boxes.each_active do |bet_box|
          player = bet_box.player

          table.game_announcer.says("%s, Insurance?" % player.name)

          response = dealer.ask_player_insurance?(bet_box)

          case response
            when Action::NO_INSURANCE
              next
            when Action::INSURANCE
              insurance_bet_amt = dealer.ask_player_insurance_bet_amount(bet_box)
              player.make_insurance_bet(bet_box, insurance_bet_amt)
            when Action::EVEN_MONEY
              #
              # pay and clear this hand out now
              #
              if bet_box.hand.blackjack?
                player.won_bet(bet_box)
                winnings = dealer.pay(bet_box, [1,1])
                table.game_announcer.hand_outcome(bet_box, Outcome::WON, winnings)
                bet_box.discard
              end
          end
        end
      elsif !dealer.up_card.ten?
        return false
      end

      has_black_jack = dealer.hand.blackjack?
      if has_black_jack
        dealer.flip_hole_card
      else
        table.game_announcer.says("Dealer doesn't have Blackjack")
      end
      has_black_jack
    end

    def payout_any_blackjacks
      table.bet_boxes.each_active do |bet_box|
        player = bet_box.player
        if bet_box.hand.blackjack?
          winnings = dealer.pay(bet_box, table.config[:blackjack_payout])
          table.game_announcer.hand_outcome(bet_box, Outcome::WON, winnings)
          player.won_bet(bet_box)
          player.blackjack(bet_box)
          bet_box.discard
        end
      end
    end

    def players_at_table?
      table.any_seated_players?
    end

    def shuffle_check
      #
      # Does the shoe report, needs_shuffle?
      # If so, shuffle the shoe and place card
      # 
      if table.shoe.needs_shuffle?
        table.game_announcer.says("Shuffling...")
        table.shoe.shuffle
        table.shoe.place_cut_card
        table.game_announcer.says("Cut card placed.")
      end
    end

    def any_player_bets?
      table.bet_boxes.any_bets?
    end

    def players_play_their_hands
      #
      # for each active? bet_box
      #
      # ask the player strategy what it wants
      #   until one of the following happens:
      #     a. player chooses STAND
      #     b. player BUSTS (hard total > 21)
      #     c. player HAS soft total of 21
      #
      #  Player strategy responses:
      #     HIT
      #       Dealer deals one card face up to the player's hand
      #     STAND
      #     DOUBLE
      #     SPLIT
      #       Dealer calls bet_box split, and deals one new card face up to
      #       each new hand. play then iteraters over each new hand
      #     SURRENDER
      #       take discard hand and 1/2 the player bet
      #       
      #
      #  Validate the player strategy response
      #     DOUBLE - must have 2 cards and meet house rules
      #     SPLIT - must have 2 identical cards, and be under max splits
      #     SURRENDER - must have only 2 cards
      #
      table.bet_boxes.each_active do |bet_box|
        player_plays_hand_until_end(bet_box)
      end
    end

    def player_plays_hand_until_end(bet_box)
 
      player = bet_box.player

      while(true) do

        response = bet_box.hand.twentyone? ? Action::STAND : dealer.ask_player_decision(bet_box)

        case response
          when Action::HIT
            deal_player_card(bet_box)
            if dealer.check_player_hand_busted?(bet_box)
              table.game_announcer.hand_outcome(bet_box, Outcome::BUST)
              player.busted(bet_box)
              dealer.collect(bet_box)
              bet_box.discard
              break
            end
          when Action::STAND
            break
          when Action::SPLIT
            bet_box.split
            bet_box.iter do |split_bet_box|
              deal_player_card(split_bet_box)
            end
            bet_box.iter do |split_bet_box|
              player_plays_hand_until_end(split_bet_box)
            end
            break
          when Action::DOUBLE_DOWN
            double_down_bet_amt = dealer.ask_player_double_down_bet_amount(bet_box)
            player.make_double_down_bet(bet_box, double_down_bet_amt)
            deal_player_card(bet_box)
            break
          when Action::SURRENDER
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
      announce_hand(bet_box)
    end

    def pay_any_winners
      #
      # 1. for each active bet_box, check hand
      # 2. If dealer had blackjack
      # 3.   if A-10, pay any insurance bets and even money. all other hands lose
      # 4. if > dealer hand (or dealer BUSTED), pay 1-1 transfer house to table
      # 5. if == dealer hand, no money transfer (PUSH)
      # 6. if < dealer hand, transfer bet from table to house
      # 7. discard player hand 
      #
      dealer_has = dealer.hand.hard_sum
      table.bet_boxes.each_active do |bet_box|
        player = bet_box.player
        player_has = bet_box.hand.hard_sum
        if dealer.busted? || player_has > dealer_has
          #
          # player wins
          #
          winning_amount = dealer.pay(bet_box, [1,1])
          table.game_announcer.hand_outcome(bet_box, Outcome::WON, winning_amount)
          player.won_bet(bet_box)
        elsif dealer_has > player_has
          #
          # dealer wins
          #
          table.game_announcer.hand_outcome(bet_box, Outcome::LOST)
          player.lost_bet(bet_box)
          dealer.collect(bet_box)
        else
          #
          # push - player removes bet
          #
          table.game_announcer.hand_outcome(bet_box, Outcome::PUSH)
          player.push_bet(bet_box)
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

    def announce_game_state
      table.game_announcer.overview
    end

    def announce_hand(bet_box)
      table.game_announcer.player_hand_status(bet_box)
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
