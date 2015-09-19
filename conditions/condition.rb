module Blackjack
  module Condition
    class Condition
       attr_reader  :table
       def initialize(table)
         @table = table
       end
    end
  end
end
