module Blackjack
  class Dealer

    class MoneyHandler
      #
      # all dealers interaction with house/player chips and cash
      # is encapsulated here
      #
      attr_reader  :table
      attr_reader  :dealer
      attr_reader  :house
      attr_reader  :cash

      def initialize(table)
        @house = table.house
        @cash = table.cash
      end

      def buy_chips(player, amount)
        cash.credit(amount)
        house.transfer_to(player.bank, amount)
      end

      def collect_bet(bet_box)
        #
        # call to transfer losing bet_box bet to house
        #
        collect_house_winnings(bet_box.box)
        collect_house_winnings(bet_box.double) if bet_box.double_down?
      end

      def pay_bet(bet_box, payout_odds)
        #
        # transfer winnings from the house account to
        # the bet_box.box based on the payout_odds and
        # the bet_box bet_amount
        #
        # payout_odds is an array of ints
        #  [3,2]  payout 3 for every 2
        #  [1,1]  payout 1 for every 1
        #
        pay_account(bet_box.box, payout_odds) +
        pay_account(bet_box.double, payout_odds)
      end

      def collect_insurance_bet(bet_box)
        collect_house_winnings(bet_box.insurance)
      end

      def pay_insurance(bet_box)
        pay_account(bet_box.insurance, Table::INSURANCE_PAYOUT)
      end

      private
      
      def pay_account(account, payout_odds)
        bet_amount = account.balance
        return 0 if bet_amount.zero?
        pay_this  = payout_odds[0]
        for_every = payout_odds[1]
        bet_amount = bet_amount.to_f unless even_payout(bet_amount, for_every)
        amount = (bet_amount / for_every) * pay_this
        house.transfer_to(account, amount)
        amount
      end

      def even_payout(bet_amount, for_every)
        bet_amount % for_every == 0
      end

      def collect_house_winnings(from_account)
        from_account.transfer_to(house, from_account.balance)
        self
      end

    end

    attr_accessor   :hand
    attr_reader     :table
    attr_reader     :money
    attr_reader     :soft_hit_limit
    attr_reader     :stats
    attr_reader     :shoe

    def initialize(table)
      @table = table
      @stats = DealerStats.new(self)
      @soft_hit_limit = table.config[:dealer_hits_soft_17] ? 17 : 16
      @hand = table.new_dealer_hand
      @shoe = table.shoe
      @money = MoneyHandler.new(table)
    end

    def deal_first_up_card_to_each_active_bet_box
      table.bet_boxes.each_active do |bet_box|
        table.shoe.hands_dealt.incr
        deal_card_face_up_to(bet_box)
      end
      self
    end

    def deal_one_card_face_up_to_each_active_bet_box
      table.bet_boxes.each_active do |bet_box|
        deal_card_face_up_to(bet_box)
      end
      self
    end

    def deal_card_face_up_to(bet_box)
      shoe.deal_one_up(bet_box.hand)
    end

    def deal_up_card
      shoe.hands_dealt.incr
      shoe.deal_one_up(hand)
      self
    end

    def check_player_hand_busted?(bet_box)
      bet_box.hand.bust?
    end

    def deal_hole_card
      shoe.deal_one_down(hand)
      self
    end

    def flip_hole_card
      hand.flip
      table.game_announcer.dealer_hand_status
      self
    end

    def deal_card_to_hand
      shoe.deal_one_up(hand)
      table.game_announcer.dealer_hand_status
      self
    end

    def busted?
      hand.bust?
    end

    def not_busted?
      !busted?
    end

    def bust_check
      stats.bust.update
    end

    def play_hand
      while hit? do
        deal_card_to_hand
      end
      self
    end

    def hit?
      not_busted? && (hit_soft_hand? || hit_hard_hand?)
    end

    def discard_hand
      hand.fold
      self
    end

    def player_lost(bet_box)
      table.game_announcer.hand_outcome(bet_box, Outcome::LOST, bet_box.total_player_bet)
      bet_box.player.lost_bet(bet_box)
      money.collect_bet(bet_box)
      stats.player_lost
    end

    def player_won(bet_box, payout)
      winnings = money.pay_bet(bet_box, payout)
      table.game_announcer.hand_outcome(bet_box, Outcome::WON, winnings)
      bet_box.player.won_bet(bet_box, winnings)
      stats.player_won
    end

    def player_push(bet_box)
      table.game_announcer.hand_outcome(bet_box, Outcome::PUSH)
      bet_box.player.push_bet(bet_box)
      stats.player_push
    end

    def up_card
      hand.up_card
    end

    def showing
      up_card.ace? ? 'A' : up_card.hard_value.to_s
    end

    def hole_card
      hand.hole_card
    end

    def print_stats
      stats.print
    end

    def reset
      stats.reset
    end

    private

    def hit_soft_hand?
      # hit if soft 16 (or if configured, soft 17) or less
      hand.soft? && (hand.hard_sum <= soft_hit_limit)
    end

    def hit_hard_hand?
      # hit if hard hand < 17
      !hand.soft? && (hand.hard_sum < 17)
    end

  end
end
