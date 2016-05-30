require 'counter_measures'

module Blackjack
  class Bank

    include CounterMeasures

    counters   :credits, :debits
    measures   :ledger

    attr_reader :initial_deposit

    def initialize(initial_deposit)
      @initial_deposit = nil
      initial_deposit_check(initial_deposit)
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
      if amount > 0
        initial_deposit_check(amount)
        ledger.add(amount + balance)
        credits.incr
      end
      self
    end

    def debit(amount)
      raise "insufficient funds to debit #{amount}. (current balance = #{balance})" \
        if balance - amount < 0
      if amount > 0
        ledger.add(balance - amount)
        debits.incr
      end
      self
    end

    def balance
      ledger.last
    end

    def high_balance
      ledger.max.to_i
    end

    def low_balance
      ledger.min.to_i
    end

    def balance_check(amount)
      balance >= amount
    end

    def reset
      reset_counters
      reset_measures
      ledger.add(initial_deposit||0)
      self
    end

    private

    def initial_deposit_check(amount)
      @initial_deposit = amount if initial_deposit.nil? unless amount == 0
    end
  end
end
