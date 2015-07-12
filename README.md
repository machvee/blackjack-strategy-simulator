# blackjack
blackjack strategy simulator

Goals:

1. A working blackjack game with an automated dealer
2. Player can be a human being prompted for what bet and hand action to take
3. Player can be automated and have a programmed bet and hand strategy
4. Full game stats for player and house keeping track of wins, losses and outcomes
5. Game play can be automated with player strategies making bets and playing hands
6. A DSL will allow a player to build a strategy using natural language that can
   reference card counts, dealer up card, current player hand, shoe varieties and game stats
7. Strategies can be tested and compared in runs, dealing 1000's of hands and storing player outcomes
]



Design

  Table
    Config (limits, payouts)
    Dealer 
    Bank
    Shoe
    Seats
    Players
    BetBoxes


  Dealer
    Hand
    DealerStrategy
      - operates the shoe
      - 

