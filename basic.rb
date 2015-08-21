require 'table'
include Blackjack

shoe_opts = {
  shuffle_seed: ARGV[1]
}

table_opts = {
  shoe: SixDeckShoe.new(shoe_opts),
  minimum_bet: 25,
  maximum_bet: 5000
}

player_opts = {
  strategy_class: BasicStrategy,
  start_bank: 2500
}

@table = TableWithAnnouncer.new("Aria High Roller Table", table_opts)
@dave = Player.new("Dave", player_opts)
@alexis = Player.new("Alexis", player_opts)
@dave.join(@table)
@alexis.join(@table)
num_hands = ARGV[0]||"1000"
@table.run(num_hands: num_hands)
