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
      sub(1)
    end

    def add(n)
      @count += n
    end

    def sub(n)
      @count -= n
    end

    def set(n)
      @count = n
    end

    def reset
      set(0)
    end

    def inspect
      count
    end
  end

  class AllCounters
    def initialize(*counter_symbols)
      @counter_hash = Hash.new
      counter_symbols.each {|s| @counter_hash[s] = Counter.new(s)}
    end

    def to_hash
      Hash[@counter_hash.map {|k, v| [k, v.count]}].freeze
    end

    def reset
      @counter_hash.values.each {|c| c.reset}
    end

    def [](sym)
      @counter_hash[sym]
    end
  end

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def counters(*counter_symbols)
      counter_symbols.each do |s|
        class_eval %Q{
          def #{s}
            @_#{s}_counter ||= counters_[:#{s}]
          end
        }
      end
      class_eval %Q{
        def counters_
          @__counters ||= AllCounters.new(*#{counter_symbols})
        end
      }
    end
  end

  def counters
    counters_.to_hash
  end

  def reset_counters
    counters_.reset
  end

end
