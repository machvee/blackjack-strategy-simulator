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

    def opening_deal
      # 
      # 1. Players have put amounts of money in bet_boxes (or are sitting out) and
      #    have indicated ready
      # 2. dealer from his left to right, deals one card face up to each active? bet_box
      # 3. dealer deals himself one card face up (up-card)
      # 4. dealer from his left to right, deals one additional card face up to each active bet_box
      # 5. dealer deals himself one card face down (hole-card)
      #
      dealer.deal_one_card_face_up_to_bet_active_bet_box
      dealer.deal_up_card
      dealer.deal_one_card_face_up_to_bet_active_bet_box
      dealer.deal_hole_card
    end

    def blackjack_check
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
      if dealer.up_card.ace?
        table.bet_boxes.each_active do |bet_box|
          response = dealer.ask_insurance?(bet_box.player, bet_box.hand)
          case response
            when Action::NO_INSURANCE
            when Action::INSURANCE
            when Action::EVEN_MONEY
          end
        end
      elsif dealer.up_card.ten?
      else
      end
    end

    def player_hand
      #
      # for each active? bet_box
      #
      # ask the player strategy what it wants
      #   until one of the following happens:
      #     a. player chooses HOLD
      #     b. player BUSTS (hard total > 21)
      #     c. player HAS hard total of 21
      #
      #  Player strategy responses:
      #     HIT
      #       Dealer deals one card face up to the player's hand
      #     STAND
      #     DOUBLE
      #     SPLIT
      #
      #  Validate the player strategy response
      #     DOUBLE - must have 2 cards and meet house rules
      #     SPLIT - must have 2 identical cards, and be under max splits
      #
    end

    def dealer_hand
      #
      # if dealer didn't already have blackjack
      #   1. turn over hole card
      #   2. until deal hand soft value >= 17 or BUST
      #      deal one card face up
      #
    end

    def close_out
      #
      # 1. for each active bet_box, check hand
      # 2. if > dealer hand (or dealer BUSTED), pay 1-1 transfer house to table
      # 3. if == dealer hand, no money transfer (PUSH)
      # 4. if < dealer hand, transfer bet from table to house
      # 5. discard player hand 
      #
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

    def wait_for_player_bets
      players.each do |player|
        catch :player_leaves_table do
          table.bet_boxes.available_for(player) do |bet_box|
            case dealer.ask_play?(player)
              when Action::LEAVE
                player.leave_table
                throw :player_leaves_table
              when Action::SIT_OUT
                break
              when Action::BET
                bet_amount = dealer.ask_bet_amount(player)
                player.make_bet(bet_box, bet_amount)
            end # case
          end # table.bet_boxes
        end # catch
      end # players
    end

    def run
      # Open the table (Set house bank, assign a dealer, configure, shoe needs shuffle)
      # While table remains open:
      #
      # If the table is empty, wait for players to join table
      # When/if players are at the table
      # GamePlay#shuffle_check
      # Wait for players to make bets. When one or more bets have been made, and other
      # players have signified they're in or out:
      #   GamePlay#opening_deal
      #   GamePlay#blackjack_check
      #   for each bet_box that has a bet
      #     GamePlay#player_hand
      #   GamePlay#dealer_hand
      #   GamePlay#close_out
      # Go to 
      #   
      #
      # Close table (record stats)
      #
      while table.any_seated_players?
        shuffle_check
        wait_for_player_bets
        next unless table.bet_boxes.any_bets? 
        opening_deal
        blackjack_check
      end
    end
  end
end
