module Blackjack
  module Condition
    class HandCondition < Condition
       attr_reader  :bet_box

       def initialize(table, bet_box)
         super(table)
         @bet_box = bet_box
       end

       def num_cards?(n)
         bet_box.hand.length == n
       end

       def more_cards_than?(n)
         bet_box.hand.length > n
       end

       def soft?
         bet_box.hand.soft?
       end

       def soft_value?(n)
         bet_box.hand.soft_sum == n
       end

       def hard_value?(n)
         bet_box.hand.hard_sum == n
       end
    end
  end
end
