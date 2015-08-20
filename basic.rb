require 'table'
include Blackjack

table_opts = {
  shoe: ContinuousShuffleShoe.new,
  minimum_bet: 10,
  maximum_bet: 2000
}

player_opts = {
  strategy_class: BasicStrategy,
  start_bank: 1000
}

@table = TableWithAnnouncer.new("Aria High Roller Table", table_opts)
@dave = Player.new("Dave", player_opts)
@alexis = Player.new("Alexis", player_opts)
@dave.join(@table)
@alexis.join(@table)
num_hands = ARGV[0]||"1000"
@table.run(num_hands: num_hands)
