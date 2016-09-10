require 'table'
include Blackjack

DFLT_MIN_BET = 10
DFLT_MAX_BET = 2000

def sane_argval(argvi, dflt)
  [dflt, ARGV[argvi] ? ARGV[argvi].to_i : dflt].max
end

min_bet = sane_argval(0, DFLT_MIN_BET)
max_bet = sane_argval(1, DFLT_MAX_BET)

opt_table_seed = ARGV[2] ? {random_seed: ARGV[2].to_i} : {}

table_options = {
  shoe_class: SixDeckShoe,
  minimum_bet: min_bet,
  maximum_bet: max_bet
}.merge(opt_table_seed)

player_options = {
  strategy_class: PromptWithBasicStrategyGuidance,
  strategy_options: {num_hands: 1},
  start_bank: min_bet * 100
}

@table = TableWithAnnouncer.new("Blackjack Table 3", table_options)
@dave = Player.new("Dave", player_options)
@dave.join(@table)
@table.run
@dave.stats.print
