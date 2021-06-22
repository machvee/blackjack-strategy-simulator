require 'table'
include Blackjack

PLAYER="Dave"
TABLE="High Limit Blackjack"
DFLT_MIN_BET = 25
DFLT_MAX_BET = DFLT_MIN_BET * 200
STRATEGY=PromptWithBasicStrategyGuidance
SHOE_SIZE=SixDeckShoe


def sane_argval(argvi, dflt)
  ARGV[argvi] ? ARGV[argvi].to_i : dflt
end

min_bet = sane_argval(0, DFLT_MIN_BET)
buyin =   sane_argval(1, min_bet * 80)
max_bet = min_bet * 200

opt_table_seed = ARGV[2] ? {random_seed: ARGV[2].to_i} : {}

table_options = {
  shoe_class: SHOE_SIZE,
  minimum_bet: min_bet,
  maximum_bet: max_bet,
  dealer_hits_soft_17: true
}.merge(opt_table_seed)

player_options = {
  strategy_class: STRATEGY,
  strategy_options: {num_hands: 1},
  start_bank: buyin
}

@table = TableWithAnnouncer.new(TABLE, table_options)
@dave = Player.new(PLAYER, player_options)
@dave.join(@table)
@table.run
@table.report_stats
@dave.stats.print
