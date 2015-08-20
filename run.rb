require 'table'
include Blackjack

@table = TableWithAnnouncer.new("Blackjack Table 3", shoe: TwoDeckShoe.new, minimum_bet: 10, maximum_bet: 2000)
@dave = Player.new("Dave", strategy_class: PromptWithBasicStrategyGuidance)
@dave.join(@table)
@table.run
