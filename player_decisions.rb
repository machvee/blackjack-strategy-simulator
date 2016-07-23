require 'decision.rb'
require 'stay_decision.rb'
require 'num_hands_decision.rb'
require 'bet_amount_decision.rb'
require 'insurance_decision.rb'
require 'insurance_bet_amount_decision.rb'
require 'play_decision.rb'
require 'double_down_bet_amount_decision.rb'

module Blackjack
  class PlayerDecisions
    attr_reader   :stay
    attr_reader   :num_hands
    attr_reader   :bet_amount
    attr_reader   :insurance
    attr_reader   :insuance_bet_amount
    attr_reader   :play
    attr_reader   :double_down_bet_amount

    def initialize(player)
      @stay                   = StayDecision.new(player)
      @num_hands              = NumHandsDecision.new(player)
      @bet_amount             = BetAmountDecision.new(player)
      @insurance              = InsuranceDecision.new(player)
      @insuance_bet_amount    = InsuranceBetAmountDecision.new(player)
      @play                   = PlayDecision.new(player)
      @double_down_bet_amount = DoubleDownBetAmountDecision.new(player)
    end
  end
end
