require 'counter_measures'

module Blackjack
  class Bank

    include CounterMeasures

    counters   :deposits, :credits, :debits

    attr_reader :initial_deposit

    def initialize(initial_deposit)
      @initial_deposit = initial_deposit
      reset
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
      deposits.add(amount)
      credits.incr
    end

    def debit(amount)
      raise "insufficient funds to debit #{amount}. (current balance = #{balance})" \
        if balance - amount < 0
      deposits.sub(amount)
      debits.incr
    end

    def balance
      deposits.count
    end

    def reset
      reset_counters
      deposits.set(initial_deposit)
    end
  end
end
