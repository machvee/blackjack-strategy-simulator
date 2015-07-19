require 'counter_measures'

module Blackjack
  class Bank

    include CounterMeasures

    counters   :balance

    def initialize(initial_deposit)
      balance.set 0
    end

    def transfer_from(from_bank, amount)
      from_bank.debit(amount)
      credit(amount)
      amount
    end

    def transfer_to(to_bank, amount)
      debit(amount)
      to_bank.credit(amount)
      amount
    end

    def credit(amount)
      balance.add(amount)
    end

    def debit(amount)
      raise "insufficient funds" if balance.count - amount < 0
      balance.sub(amount)
    end

    def current_balance
      balance.count
    end
  end
end
