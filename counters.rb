module Counters

  def self.included(base)
    base.extend ClassMethods
    base.class_eval do
      self.counter_names = []
    end
  end

  module ClassMethods
    def counters(*counter_symbols)
      @@counter_names += counter_symbols
    end

    def counter_names=(value)
      @@counter_names = value
    end

    def counter_names
      @@counter_names
    end
  end

  def reset_counters
    zero_out
  end

  def reset_counter(counter_name)
    valid_counter_name?(counter_name)
    _counters[counter_name] = 0
  end

  def incr_counter(counter_name)
    add_to(counter_name, 1)
  end

  def decr_counter(counter_name)
    add_to(counter_name, -1)
  end

  def counter_value(counter_name)
    valid_counter_name?(counter_name)
    _counters[counter_name]
  end

  def counters
    _counters.clone
  end

  private

  def _counters
    @__counters ||= counter_hash
  end

  def zero_out
    @__counters = counter_hash
  end

  def counter_hash
    h = Hash[self.class.counter_names.zip([0]*self.class.counter_names.length)]
    h.default_proc = proc do |hash, key|
      raise "no such counter #{key} defined for #{self.class.name}"
    end
    h
  end

  def valid_counter_name?(counter_name)
    _counters[counter_name]
  end

  def add_to(counter_name, value)
    _counters[counter_name] += value
  end
end
