module Blackjack
  module Condition
    class ShoeCondition < Condition
       attr_reader  :shoe
       def initialize(table)
         super
         @shoe = table.shoe
       end

       def num_decks?(nd)
         shoe.num_decks == nd
       end

       def ten_percentage?(tp_range_min, tp_range_max)
         (tp_range_min..tp_range_max).include?(shoe.current_ten_percentage)
       end

       def cards_until_shuffle_less_than?(nc)
         shoe.remaining_until_shuffle < nc
       end
    end
  end
end
