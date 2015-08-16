require 'table'
include Blackjack

table_opts = {
  shoe: TwoDeckShoe.new,
  minimum_bet: 10,
  maximum_bet: 2000
}

player_opts = {
  strategy_class: BasicStrategy,
  start_bank: 1000
}

@table = TableWithAnnouncer.new("Blackjack Table 1", table_opts)
@dave = Player.new("Dave", player_opts)
@dave.join(@table)
@table.run
