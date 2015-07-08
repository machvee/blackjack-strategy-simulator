module Counters

  class Counter

    attr_reader :count

    def initialize(name)
      @name = name
      reset
    end

    def incr
      add(1)
    end

    def decr
      add(-1)
    end

    def add(n)
      @count += n
    end

    def reset
      @count = 0
    end

    def inspect
      count
    end
  end

  def self.included(base)
    base.extend ClassMethods
    base.class_eval do
      self.counter_names = []
    end
  end

  def self.inherited(base)
    base.instance_variable_set(:@counter_names, self.counter_names)
  end

  module ClassMethods
    def counters(*counter_symbols)
      @@counter_names += counter_symbols
      counter_symbols.each do |counter_name|
        class_eval %Q{
          def #{counter_name}
            @__#{counter_name} ||= Counter.new(:#{counter_name})
          end
        }
      end
    end

    def counter_names=(value)
      @@counter_names = value
    end

    def counter_names
      @@counter_names
    end
  end

  def reset_counters
    self.class.counter_names.each do |counter_name|
      instance_eval("#{counter_name}.reset")
    end
  end

  def counters
    Hash[self.class.counter_names.map{|counter_name| [counter_name, instance_eval("#{counter_name}.count")]}]
  end

end
