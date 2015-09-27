module Blackjack
  class HistoHandStats
    attr_reader  :name
    attr_reader  :num_buckets
    attr_reader  :buckets

    DFLT_BUCKETS = [
       [0,20],    # low % of 10's remaining in deck
       [20,40],   # avg % of 10's remaining in deck
       [40,100]   # higher % of 10's remaining in deck
    ]
    MIN_RANGE=0.0
    MAX_RANGE=100.0

    def initialize(name, bucket_ranges=DFLT_BUCKETS)
      @name = name
      @num_buckets = bucket_ranges.length
      @buckets = Array.new(num_buckets) {|i| new_bucket(*bucket_ranges[i])}
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
      played_total = totals_for(:played)
      return if played_total.zero?

      puts print_header
      all_keys.each do |key|
        line = "%13.13s" % key
        buckets.each do |bucket|
          line << bucket.stats.print_stat(key) + (" "*6)
        end
        line << HandStats.format_stat(totals_for(key), played_total)
        puts line
      end
    end

    def totals_for(key)
      buckets.inject(0) {|counter, b| counter += b.stats.counters[key]}
    end

    private

    def all_keys
      @_ak ||= buckets.first.stats.counters.keys
    end

    def print_header
      @_hdr ||= ("\n%-20.20s" % name.upcase) + buckets.inject([]) {|h, b| h << b.range_string}.push("  Total  ").join(" "*12)
    end

    def new_bucket(min, max)
      HandStatsBucket.new(name, min, max)
    end
  end
end
