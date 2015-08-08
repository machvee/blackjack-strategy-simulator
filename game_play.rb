module Blackjack
  class GamePlay
    attr_reader   :table
    attr_reader   :dealer
    attr_reader   :players

    def initialize(table)
      @table =  table
      @dealer = table.dealer
      @players = table.seated_players
    end

    def run
      while players_at_table?
        shuffle_check
        wait_for_player_bets
        play_a_hand_of_blackjack if any_player_bets?
      end
    end

    def play_a_hand_of_blackjack
      opening_deal
      unless dealer_has_blackjack?
        payout_any_blackjacks
        players_play_hands
        dealer_plays_hand
      end
      pay_out
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
          response = dealer.ask_player_insurance?(bet_box)
          case response
            when Action::NO_INSURANCE
              next
            when Action::INSURANCE
              insurance_bet_amt = dealer.ask_player_insurance_bet_amount(bet_box)
              player.insurance_bet(insurance_bet_amt)
            when Action::EVEN_MONEY
              #
              # pay and clear this hand out now
              #
              player.won_bet(bet_box)
              dealer.pay(bet_box, [1,1])
              bet_box.hand.discard
          end
        end
      end

      has_black_jack = dealer.hand.blackjack?
      dealer.flip_hole_card if has_black_jack
      has_blackjack 
    end

    def payout_any_blackjacks
      table.bet_boxes.each_active do |bet_box|
        if bet_box.hand.blackjack?
          player.blackjack(bet_box)
          player.won_bet(bet_box)
          dealer.pay(bet_box, table.config[:blackjack_payout])
          bet_box.hand.discard
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
        table.shoe.shuffle
        table.shoe.place_cut_card
      end
    end

    def any_player_bets?
      table.bet_boxes.any_bets?
    end

    def players_play_hands
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
      table.bet_boxes.each_active? do |bet_box|
        play_hand_until_end(bet_box)
      end
    end

    def played_hand_until_end(bet_box)
      while(true) do

        break if bet_box.hand.twentyone?

        response = dealer.ask_player_decision(bet_box)

        case response
          when Action::HIT
            dealer.deal_card_face_up_to(bet_box)
            if dealer.check_player_hand_busted?(bet_box)
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
              dealer.deal_card_face_up_to(split_bet_box)
            end
            bet_box.iter do |split_bet_box|
              played_hand_until_end(split_bet_box)
            end
            break
          when Action::DOUBLE
            player.make_double_down_bet(bet_box)
            dealer.deal_card_face_up_to(bet_box)
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

    def pay_out
      #
      # 1. for each active bet_box, check hand
      # 2. If dealer had blackjack
      # 3.   if A-10, pay any insurance bets and even money. all other hands lose
      # 4. if > dealer hand (or dealer BUSTED), pay 1-1 transfer house to table
      # 5. if == dealer hand, no money transfer (PUSH)
      # 6. if < dealer hand, transfer bet from table to house
      # 7. discard player hand 
      #
      
      dealers_has = dealer.hand.hard_sum
      table.bet_boxes.each_active do |bet_box|
        player_has = bet_box.hand.hard_sum
      end
    end

    def dealer_plays_hand
      dealer.play_hand
    end

    def wait_for_player_bets
      players.each do |player|
        catch :player_leaves_table do
          table.bet_boxes.available_for(player) do |bet_box|
            case dealer.ask_player_play?(player)
              when Action::LEAVE
                player.leave_table
                throw :player_leaves_table
              when Action::SIT_OUT
                break
              when Action::BET
                bet_amount = dealer.ask_player_bet_amount(player)
                player.make_bet(bet_amount, bet_box)
            end # case
          end # table.bet_boxes
        end # catch
      end # players
    end

  end
end
