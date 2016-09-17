module Blackjack
  class GameRandomizer

    #
    # Generators random number generators, that can all be repeatable
    # based on an optional passed in seed
    #
    BIG_NUM = 63471134932224576488256326431348018374 # arbitrary large number

    attr_reader   :init_seed

    def initialize(seed=nil)
      @init_seed = seed.nil? ? Random.new_seed : seed.to_i
      @seeder = Random.new(init_seed)
    end

    def new_prng
      Random.new(new_seed)
    end

    private

    def new_seed
      @seeder.rand(BIG_NUM)
    end
  end
end

