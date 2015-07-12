require 'cards'

module Blackjack
  class Dealer

    include Cards

    attr_accessor   :hand
    attr_reader     :table

    def initialize(table)
      @table = table
    end

    def deal_hands_to_bet_boxes
      table.bet_boxes.each do |bet_box|
        next unless bet_box.has_bet?
        #
        # take a card from the shoe and put it in the bet_box
        #
      end
    end

    def upcard
      hand[0]
    end

    def downcard
      hand[1]
    end

    def flip_down_card
      downcard.up if downcard.face_down?
    end

  end
end
