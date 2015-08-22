require 'table'
include Blackjack

opt_table_seed = ARGV[0] ? {random_seed: ARGV[0].to_i} : {}

table_options = {
  shoe_class: TwoDeckShoe,
  minimum_bet: 10,
  maximum_bet: 2000
}.merge(opt_table_seed)

player_options = {
  strategy_class: PromptWithBasicStrategyGuidance
}

@table = TableWithAnnouncer.new("Blackjack Table 3", table_options)
@dave = Player.new("Dave", player_options)
@dave.join(@table)
@table.run
