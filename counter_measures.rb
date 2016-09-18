module CounterMeasures
  ################################################
  #
  #  C O U N T E R
  #
  class Counter
    #
    #  keep incremental counts of a quantity, and maintain high and low watermarks
    #
    #  Usage:
    #
    #  counters  :visits, :absences
    #
    #    visits.incr
    #    visits.incr
    #    visits.incr
    #    visits.incr
    #    visits.count => 4
    #
    #    absences.incr
    #    absences.incr
    #    absences.decr
    #    absences.count => 2
    #    absences.reset
    #    absences.count => 0
    #
    #    counters => {visits: 4, absences: 0}
    #

    attr_reader :count
    attr_reader :high
    attr_reader :low

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
      set(count + n)
    end

    def sub(n)
      set(count - n)
    end

    def set(n)
      @count = n
      @high = count if count > high
      @low = count if count < low
    end

    def reset
      @count = 0
      @high = -9999999999
      @low = -high
    end

    def inspect
      count
    end

    def export
      count
    end
  end

  class StatsKeeper
    def initialize(stat_class, *stats_names)
      @keeper = Hash.new
      stats_names.each {|stat_name| @keeper[stat_name] = stat_class.new(stat_name)}
    end

    def to_hash
      Hash[@keeper.map {|stat_name, stat| [stat_name, stat.export]}].freeze
    end

    def reset
      @keeper.values.each {|stat| stat.reset}
    end

    def [](sym)
      @keeper[sym]
    end
  end

  class EventStatsKeeper < StatsKeeper
    def initialize(condition_lambdas, *stats_names)
      @keeper = Hash.new
      lambda_iter = condition_lambdas.each
      stats_names.each {|stat_name| @keeper[stat_name] = Event.new(stat_name, lambda_iter.next)}
    end

    def update
      @keeper.values.each {|event| event.update}
    end
  end

  def self.included(base)
    base.extend ClassMethods
  end

  #########################
  #
  #  H I S T O R Y
  #
  class History

    ################
    #
    #  R I N G   B U F F E R
    #
    class RingBuffer < Array
      attr_reader :max_size

      def initialize(max_size, enum = nil)
        @max_size = max_size
        enum.each { |e| self << e } if enum
      end

      def <<(el)
        if self.size < @max_size || @max_size.nil?
          super
        else
          self.shift
          self.push(el)
        end
      end

      alias :push :<<
    end

    DEFAULT_HISTORY_LENGTH=50

    attr_reader :buffer

    def initialize(length=DEFAULT_HISTORY_LENGTH)
      @buffer = RingBuffer.new(length)
    end

    def record(m)
      buffer << m
    end

    def <<(m)
      record(m)
    end

    def last(n=1)
      l = buffer.last(n)
      n > 1 ? l : l.first
    end

    def reset
      buffer.clear
    end
  end

  ################################################
  #
  #  M E A S U R E
  #
  class Measure
    #
    # keep totals, avg, min and max for ongoing measurement of a quantity
    # e.g. measurements of daily rainfall
    #
    # incr and commit provide a way to count occurences then commit them
    # as a measure
    #
    # Usage:
    #
    #  measures :temp, :rainfall
    #
    #  temp.add(75) # record a temp
    #  temp.add(74) # record a temp
    #  temp.add(62) # record a temp
    #  temp.add(85) # record a temp
    #  temp.add(75, 73) # record 2 temps
    #  temp.min => "62"
    #  temp.max => "85"
    #  temp.avg => "74.0"
    #  temp.count => 6
    #  temp.last(3) => [85, 74, 73]
    #  temp.reset
    #  measures => {temp: {total: 0, count: 0, avg: '-', min: '-', max: '-'}}
    #
    #  rainfall.incr # incrementally add inch at a time
    #  rainfall.incr # incrementally add inch at a time
    #  rainfall.incr # incrementally add inch at a time
    #  rainfall.commit # records a measurement of 3 inches of rain
    #
    #  rainfall.add(1) # records a measurement of 1 inche of rain
    #  rainfall.total => 4
    #  rainfall.count => 2
    #


    attr_reader   :name
    attr_reader   :tally   # ongoing measurement until committed
    attr_reader   :count   # number of times measured
    attr_reader   :total   # ongoing sum of measurements
    attr_reader   :min     # ongoing min
    attr_reader   :max     # ongoing max

    def initialize(name)
      @name = name
      @history = History.new
      reset
    end

    def incr(val=1)
      @tally += val
    end

    def commit
      add(tally)
      @tally = 0
    end

    def add(*measurement)
      measurement.each do |m|
        @count += 1
        @total += m
        keep_min(m)
        keep_max(m)
        @history.record(m)
      end
      self
    end

    def last(n=1)
      @history.last(n)
    end

    def reset
      @tally = 0
      @count = 0
      @total = 0
      @min = nil
      @max = nil
      @history.reset
    end

    def average
     return "0.00" if count == 0
     a = (total * 1.0)/count
     "%6.2f" % a
    end

    def export
      {
        count:  count,
        total:  total,
          min:  min||'-',
          max:  max||'-',
          avg:  average||'-'
      }
    end

    def to_s
      "#{name} - #{export}"
    end

    def inspect
      to_s
    end

    private

    def keep_min(measurement)
      @min = measurement if @min.nil? || @min > measurement
    end

    def keep_max(measurement)
      @max = measurement if @max.nil? || @max < measurement
    end
  end

  ################################################
  #
  #  E V E N T
  #
  class Event
    #
    # event definer must have an event condition method
    # defined that returns true if the event passed
    # or false if event failed.  The condition method
    # must be named "#{event_name}?"
    #
    #   include CounterMeasures
    #
    #   event   :hot_day
    #
    #   def hot_day?
    #     @todays_temps.max >= 90
    #   end
    #
    attr_reader   :name
    attr_reader   :condition_lambda

    def initialize(name_sym, condition_lambda, options = {})
      @name = name_sym.to_s
      @condition_lambda = condition_lambda
      @_passed = Counter.new(name + '_passed')
      @_failed = Counter.new(name + '_failed')
      @history = History.new
    end

    def passed
      @_passed.count
    end

    def failed
      @_failed.count
    end

    def count
      passed + failed
    end

    def last(n=1)
      @history.last(n)
    end

    def update
      result = condition_lambda.call
      if result
        @_passed.incr
      else
        @_failed.incr
      end
      @history << result
      self
    end

    def reset
      @_passed.reset
      @_failed.reset
      @history.reset
      self
    end

    def export
      {
         count:  count,
        passed:  passed,
        failed:  failed
      }
    end

    def to_s
      "#{name} - #{export}"
    end

    def inspect
      to_s
    end

  end

  module ClassMethods
    def counters(*counter_name_symbols)
      counter_name_symbols.each do |s|
        class_eval %Q{
          def #{s}
            @_#{s}_counter ||= counters_[:#{s}]
          end
        }
      end
      class_eval %Q{
        def counters_
          @__counters ||= StatsKeeper.new(Counter, *#{counter_name_symbols})
        end
      }
    end

    def measures(*measure_name_symbols)
      measure_name_symbols.each do |s|
        class_eval %Q{
          def #{s}
            @_#{s}_measure ||= measures_[:#{s}]
          end
        }
      end
      class_eval %Q{
        def measures_
          @__measures ||= StatsKeeper.new(Measure, *#{measure_name_symbols})
        end
      }
    end

    def events(*event_name_symbols)
      event_name_symbols.each do |s|
        class_eval %Q{
          def #{s}
            @_#{s}_event ||= events_[:#{s}]
          end
        }
      end
      class_eval %Q{
        def events_
          @__event_lambdas ||= [*#{event_name_symbols}].map {|name| lambda(&method((name.to_s + "?").to_sym))}
          @__events ||= EventStatsKeeper.new(@__event_lambdas, *#{event_name_symbols})
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

  def measures
    measures_.to_hash
  end

  def reset_measures
    measures_.reset
  end

  def events
    events_.to_hash
  end

  def update_events
    events_.update
  end

  def reset_events
    events_.reset
  end
end
