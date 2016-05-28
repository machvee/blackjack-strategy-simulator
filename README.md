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

     a. Players know of the 'Basic Rules of Blackjack..Thorpe book, etc'.   They want to try them out
        and really see that its better to hit a 16 than it is to stand when the Dealer shows 7 or higher.
     b. Players have hunches they want to try out.   Maybe stand on a 16 when they've been dealt A 3 2 A.
        Is it still better to hit that?
     c. Players want to know if its really better to bet more when there are lots of 10's left in a short deck
     d. Players want to make subtle changes to an existing strategy and then try it out.
     e. Players want to save a strategy so they can replay it later.  Or share it.  Get rewarded for it, etc.
     f. Back Testing.  Replaying a sequence of cards on a strategy (save and reuse a seed)
     g. Realtime Analysis.  Try a strategy with a new, random sequence of cards.
     h. Keep run stats:
         - number of hands dealt, shuffles
         - number of player hands won, pushed, lost, busted
         - number of player blackjacks, splits, doubles
         - dealer wins, pushes, losses, busts, blackjacks (A up/10 up)
         - player bank stats.  High (profit), low (drawdown), start balances, end balances
         - keep house advantage for each run
         - keep stats for each rule and strategy decision. e.g. If my strategy says:
            "don't hit 16 when within 30 cards of the marker and greater than 5 tens remain",
            show me how many wins/losses were made when this rule was applied.

8. Events.   
     - instrument code to have named events that can be passed quantities
     - events can have user-defined callbacks invoked when they are triggered.
     - by definining the event via a DSL, there are automatic hooks into a strategy language
       that can propose player hand decisions and game actions based on the firing of events
     - support AND, OR, NOT and () operations so events can be chained


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


Handling Splits


Dealer
BetBox
 ^ Player
 |_SplitBoxes
 
BetBoxes
  [Bet Box] => SplitBoxes
                 [Bet Box]
                 [Bet Box]
  [Bet Box] => SplitBoxes
                 [Bet Box]
  [Bet Box] => SplitBoxes
                 [Bet Box]
  [Bet Box] => SplitBoxes
  [Bet Box] => SplitBoxes
  [Bet Box] => SplitBoxes


II.  Decisions, Actions, Rules, Strategies, Outcomes and Strategy Stats

  Definitions:

    1. Decision        One of the several points in the Blackjack game that the player must take an Action.
         play?         Sit and Play (possibly getting markers when player funds are low), or Cash out and Quit.  
                         Valid Action: true/false

         num_bets      How many bet boxes/hands to have dealt.
                         Valid Action: integer 0-n

         bet_amount    Bet amount placed in bet box.
                         Valid Action: integer table_min to table_max

         insurance?    Take insurance when dealer has A up card? (boolean)
                         Valid Action: Action::INSURANCE, Action::NO_INSURANCE, Action::EVEN_MONEY

         insurance_    Amount bet as insurance
         bet_amount      Valid Action: integer up to 1/2 the bet_box bet_amount
                         

         hand_play     Dealer prompts for this for each player hand until player Stands, the hand busts, 
                       or the hands hard value equals 21.  Some Actions are not valid given the current hand 
                       value or card count
                         Valid Action: 'H'it, 'S'tand, 'D'ouble down, s'P'lit.

         double_down_  Amount of additional bet when doubling down
         bet_amount      Valid Action: positive integer up to the bet_box bet_amount


    2.  Action        For each Decision, one of the Valid Action above chosen by a player's rules

    3.  Rules         For each Decision, the players logic in place that assesses the current state of
                      play and uses that logic to produce a Valid Action.  Rules can be static, or can
                      be driven by current state of play such as dealer up card or by card counting
                      techniques.  Rules assign themselves a name which is used to keep statistics
                        e.g  insurance?  return false Never take insurance
                             hand_play   return 'S' when hand hard_value >= 17
                             bet_amount  return table_min * card_counting_multiple

    4. RuleBased      A family of Rules that cohesively define Actions taken for the Decisions during play.
       Strategy       
    
    5. Outcomes       When the player Busts, or after dealer plays his hand, whether the player WINS, LOSES, or PUSHES
                      The amount WON is associated with the Outcome.   > 0 WIN, 0 PUSH, < 0 LOSE

    6. Strategy       Statistics kept automatically by the blackjack table for each player.  As the dealer
       Stats          prompts the player for each Decision, the player returns the Action and the Strategy's
                      Rule used to produce it.  The Rule is added to a bet box Decision Chain.  When an Outcome
                      is determined, the Stategy Stats are updated with the Outcome and the WIN/LOSE amount for each
                      Rule referenced in the Decision Chain.  The player can view the stats 
