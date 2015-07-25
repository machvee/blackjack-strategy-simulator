require 'counter_measures'

module Blackjack
  class Bank

    include CounterMeasures

    counters   :balance, :credits, :debits

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
      balance.add(amount)
      credits.incr
    end

    def debit(amount)
      raise "insufficient funds to transfer #{amount}. current balance = #{current_balance}" \
        if current_balance - amount < 0
      balance.sub(amount)
      debits.incr
    end

    def current_balance
      balance.count
    end

    def reset
      reset_counters
      balance.set(initial_deposit)
    end
  end
end
