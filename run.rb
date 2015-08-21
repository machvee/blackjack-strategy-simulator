require 'table'
include Blackjack

shoe_opts = ARGV[0] ? {shuffle_seed: ARGV[0].to_i} : {}

@table = TableWithAnnouncer.new("Blackjack Table 3", shoe: TwoDeckShoe.new(shoe_opts), minimum_bet: 10, maximum_bet: 2000)
@dave = Player.new("Dave", strategy_class: PromptWithBasicStrategyGuidance)
@dave.join(@table)
@table.run
