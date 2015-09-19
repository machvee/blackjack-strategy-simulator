require 'table'
include Blackjack

num_hands = (ARGV[0]||"1000").to_i
opt_num_bets = (ARGV[1].nil? || ARGV[1] == '-') ? 1 : ARGV[1].to_i
opt_table_seed = ARGV[2].nil? ? {} : {random_seed: ARGV[2].to_i}

run_options = {
  num_hands: num_hands
}

announcer_class = (num_hands > 25000 ? RoundsPlayedGameAnnouncer : StdoutGameAnnouncer)


table_options = {
  shoe_class: TwoDeckShoe,
  minimum_bet: 25,
  maximum_bet: 5000
}.merge(opt_table_seed).merge(game_announcer_class: announcer_class)

player_options = {
  strategy_class: BasicStrategy,
  strategy_options: {num_bets: opt_num_bets},
  start_bank: 2500
}

@table = Table.new("Aria High Roller Table", table_options)
@dave = Player.new("Dave", player_options)
@dave.join(@table)
@table.run(run_options)
