require 'table'
include Blackjack

@table = Table.new("Blackjack Table 3")
@dave = Player.new("Dave", strategy_class: PromptPlayerHandStrategy)
@dave.join(@table)
@table.run
