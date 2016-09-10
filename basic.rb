require 'table'
include Blackjack
#
# Usage:  ruby basic.rb [<num_hands> <rand_seed>]
#
DEFAULT_NUM_ROUNDS="1000"
DEFAULT_NUM_HANDS=1
ABBREV_OUTPUT_THRESHOLD=25000

TABLE_NAME='Aria High Roller'
SHOE_CLASS=SixDeckShoe
MIN_BET=10
MAX_BET=2000

PLAYER_NAME='Dave'
START_PLAYER_BANK=1000

num_rounds = (ARGV[0]||DEFAULT_NUM_ROUNDS).to_i
announcer_class = (num_rounds > ABBREV_OUTPUT_THRESHOLD ? RoundsPlayedGameAnnouncer : StdoutGameAnnouncer)

table_options = {
  shoe_class:           SHOE_CLASS,
  minimum_bet:          MIN_BET,
  maximum_bet:          MAX_BET,
  game_announcer_class: announcer_class
}

num_hands = (ARGV[1].nil? || ARGV[1] == '-') ? DEFAULT_NUM_HANDS : ARGV[1].to_i

unless ARGV[2].nil?
  table_options[:random_seed] = ARGV[2].to_i
end

player_options = {
  strategy_class: BasicStrategy,
  strategy_options: {
    num_rounds: num_rounds,
    num_hands: num_hands
  },
  start_bank: START_PLAYER_BANK,
  auto_marker: true
}

@table = Table.new(TABLE_NAME, table_options)
@dave = Player.new(PLAYER_NAME, player_options)
@dave.join(@table)
@table.run
@dave.stats.print
