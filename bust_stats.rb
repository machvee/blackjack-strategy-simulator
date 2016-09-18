module Blackjack
  class BustStats

    attr_reader  :dealer
    attr_reader  :bust_up_faces
    attr_reader  :no_bust_up_faces
    attr_reader  :total

    UP_FACES=[2,3,4,5,6,7,8,9,10,'A'].map(&:to_s)

    def initialize(dealer)
      @dealer = dealer
      reset
    end

    def reset
      @bust_up_faces = Hash[UP_FACES.zip([0]*UP_FACES.length)]
      @no_bust_up_faces = Hash[UP_FACES.zip([0]*UP_FACES.length)]
      @total = 0
      self
    end

    def update
      if dealer.busted?
        dealer.stats.hand.busted.incr
        inc_busted(dealer.hand)
      else
        inc_not_busted(dealer.hand)
      end
    end

    def print
      print_header
      UP_FACES.each do |face|
        print_stat(face)
      end
    end

    private

    def inc_busted(dealer_hand)
      @total += 1
      bust_up_faces[face_val(dealer_hand.up_card)] += 1
    end

    def inc_not_busted(dealer_hand)
      no_bust_up_faces[face_val(dealer_hand.up_card)] += 1
    end

    def face_val(card)
       card.ten? ? "10" : card.face
    end

    def print_header
      puts "\n"
      puts "BUSTS (%d/%d)" % [total, total_hands_played]
    end

    def total_hands_played
      dealer.stats.hand.counters[:played]
    end

    def print_stat(face)
      puts "%4s: %s" % [face, percentage_format(face)]
    end

    def total_face(face)
      bust_up_faces[face] + no_bust_up_faces[face]
    end

    def percentage_format(face)
      t = total_face(face)
      t.zero? ? "          -      " : "%6d [%7.2f%%]" % [bust_up_faces[face], bust_up_faces[face]/(t*1.0) * 100.0]
    end

  end
end
