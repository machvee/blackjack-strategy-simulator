module Blackjack
  module Condition
    class DealerCondition < Condition
       attr_reader  :dealer

       def initialize(dealer)
         super(dealer.table)
         @dealer = dealer
       end

       def up_card?(n)
         dealer.up_card == n
       end
    end
  end
end
