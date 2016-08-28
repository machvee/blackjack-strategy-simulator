require 'table'
include Blackjack
#
# Usage:  ruby basic.rb [<num_hands> <num_bets_each_play> <rand_seed>]
#
DEFAULT_NUM_HANDS="1000"
DEFAULT_NUM_BETS=1
ABBREV_OUTPUT_THRESHOLD=25000

TABLE_NAME='Aria High Roller'
SHOE_CLASS=SixDeckShoe
MIN_BET=10
MAX_BET=2000

PLAYER_NAME='Dave'
START_PLAYER_BANK=1000

num_hands = (ARGV[0]||DEFAULT_NUM_HANDS).to_i
opt_num_bets = (ARGV[1].nil? || ARGV[1] == '-') ? DEFAULT_NUM_BETS : ARGV[1].to_i
opt_table_seed = ARGV[2].nil? ? {} : {random_seed: ARGV[2].to_i}

run_options = {
  num_hands: num_hands
}

announcer_class = (num_hands > ABBREV_OUTPUT_THRESHOLD ? RoundsPlayedGameAnnouncer : StdoutGameAnnouncer)

table_options = {
  shoe_class: SHOE_CLASS,
  minimum_bet: MIN_BET,
  maximum_bet: MAX_BET
}.merge(opt_table_seed).merge(game_announcer_class: announcer_class)

player_options = {
  strategy_class: BasicStrategy,
  strategy_options: {num_bets: opt_num_bets},
  start_bank: START_PLAYER_BANK,
  auto_marker: true
}

@table = Table.new(TABLE_NAME, table_options)
@dave = Player.new(PLAYER_NAME, player_options)
@dave.join(@table)
@table.run(run_options)
