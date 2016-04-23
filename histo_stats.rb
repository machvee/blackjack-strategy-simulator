module Blackjack
  class HistoStats
    attr_reader  :name
    attr_reader  :num_buckets
    attr_reader  :buckets
    attr_reader  :stats_class
    #
    # There are 4x10,4xJ,4xQ,4xK = 16 10's in a 52 card deck
    # thats 16.0/52.0  =  .30769 = ~31% 
    # These buckets keep separate hand/bet stats for players
    # and the dealer based on the % of 10's left in the deck
    #
    # TODO:  Refactor for Hi-Lo.  Keep stats on low card percentage
    # (2-6 remaining in deck) and Hi cards (10's, A)
    # 
    #
    DFLT_BUCKETS = [
       [0,28],    # low % of 10's remaining in deck
       [28,35],   # avg % of 10's remaining in deck
       [35,100]   # higher % of 10's remaining in deck
    ]
    MIN_RANGE=0.0
    MAX_RANGE=100.0

    def initialize(name, stats_class, bucket_ranges=DFLT_BUCKETS)
      @name = name
      @stats_class = stats_class
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
      puts print_header
      all_keys.each do |key|
        key_total = totals_for(key)
        next if key_total.zero?

        line = "%13.13s" % key
        buckets.each do |bucket|
          line << bucket.stats.print_stat(key) + (" "*6)
        end
        line << stats_class.format_stat(key_total)
        puts line
      end
    end

    def percentage_print
      #
      #
      # HANDS               ( 0 - 20 )            ( 20 - 40 )            ( 40 - 100 )              Total  
      #        played    30 [ 100.00%]         951 [ 100.00%]          50 [ 100.00%]        1031 [ 100.00%]
      #           won    12 [  40.00%]         426 [  44.79%]          27 [  54.00%]         465 [  45.10%]
      #        pushed     3 [  10.00%]          78 [   8.20%]           2 [   4.00%]          83 [   8.05%]
      #          lost    12 [  40.00%]         320 [  33.65%]          14 [  28.00%]         346 [  33.56%]
      #        busted     2 [   6.67%]         127 [  13.35%]           8 [  16.00%]         137 [  13.29%]
      #    blackjacks     0 [   0.00%]          42 [   4.42%]           3 [   6.00%]          45 [   4.36%]
      #
    
      played_total = totals_for(:played)
      return if played_total.zero?

      puts print_header
      all_keys.each do |key|
        key_total = totals_for(key)
        next if key_total.zero?

        line = "%13.13s" % key
        buckets.each do |bucket|
          line << bucket.stats.print_stat(key) + (" "*6)
        end
        line << stats_class.format_stat(key_total, played_total)
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
      stats = stats_class.new(name)
      HistoBucket.new(name, min, max, stats)
    end
  end
end
