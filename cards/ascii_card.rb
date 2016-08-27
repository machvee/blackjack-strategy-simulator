require 'card'
require 'ascii_card_printer'

module Cards
  class AsciiCard < Card
    def initialize(*)
      super
      @card_printer = AsciiCardPrinter.new
    end
  end
end
