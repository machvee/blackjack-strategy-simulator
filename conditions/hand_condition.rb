module Blackjack
  module Condition
    class HandCondition < Condition
       attr_reader  :bet_box

       def initialize(table, bet_box)
         super(table)
         @bet_box = bet_box
       end

       def num_cards?()
         bet_box.hand.length
       end

    end
  end
end
