module Blackjack
  class HistoHandStats
    attr_reader  :name
    attr_reader  :num_buckets
    attr_reader  :buckets

    DFLT_NUM_BUCKETS = 5
    MIN_RANGE=0.0
    MAX_RANGE=100.0

    def initialize(name, num_buckets=DFLT_NUM_BUCKETS)
      @name = name
      @num_buckets = num_buckets
      @buckets = Array.new(num_buckets+1) {|i| new_bucket(i)}
    end

    def stats_for(value)
      @buckets.each do |b|
        return b.stats if b.within?(value)
      end
      raise("couldn't find %6.2f in buckets" % value)
    end

    def reset
      buckets.each {|b| b.reset}
    end

    def print
      buckets.each {|b| b.print}
      puts "="*25
      print_totals
    end

    def totals
      total_counters = Hash.new(0)
      buckets.each do |b|
        b.stats.counters.each_pair do |k,v|
          total_counters[k] += v
        end
      end
      total_counters
    end

    def print_totals
      t = totals
      played = totals[:played]
      return if played == 0
      puts "==>   Total #{name}:"
      t.each_pair do |key, value|
        next if value == 0
        puts "==>     %13.13s: %6d [%6.2f%%]" % [key, value, value/(played*1.0) * 100.0]
      end
      puts ""
    end

    private

    def new_bucket(index)
      bucket_range = MAX_RANGE / num_buckets
      HandStatsBucket.new(name, index*bucket_range, ((index+1)*bucket_range)-0.01)
    end
  end
end
