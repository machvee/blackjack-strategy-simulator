require 'cards'

module Blackjack
  class Dealer

    include Cards

    attr_accessor   :hand
    attr_reader     :table

    def initialize(table)
      @table = table
    end

    def deal_one_card_face_up_to_bet_active_bet_boxes
      table.bet_boxes.each do |bet_box|
        next unless bet_box.active?
        table.shoe.deal_one_up(bet_box.hand)
      end
    end

    def deal_up_card
      @hand = Cards.new(table.shoe.decks)
      table.shoe.deal_one_up(hand)
    end

    def deal_hole_card
      table.shoe.deal_one_down(hand)
    end

    def up_card
      hand[0]
    end

    def hole_card
      hand[1]
    end

    def flip_hole_card
      hole_card.up if hole_card.face_down?
    end

  end
end
