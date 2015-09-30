//+------------------------------------------------------------------+
//| This MQL is generated by Expert Advisor Builder                  |
//|                http://sufx.core.t3-ism.net/ExpertAdvisorBuilder/ |
//|                                                                  |
//|  In no event will author be liable for any damages whatsoever.   |
//|                      Use at your own risk.                       |
//|                                                                  |
//|   Modified by Lucas Liew                                         |                                                                 
//|                                                                  |
//+------------------- DO NOT REMOVE THIS HEADER --------------------+

   /* 
      BELINDA ENTRY RULES:
      If Current Volatility (ATR(20)) is greater than Volatility (ATR(20)) 10 hours ago:
      Enter a long trade when SMA(10) crosses SMA(40) from bottom
      Enter a short trade when SMA(10) crosses SMA(40) from top
   
      BELINDA EXIT RULES:
      Exit the long trade when SMA(10) crosses SMA(40) from top
      Exit the short trade when SMA(10) crosses SMA(40) from bottom
      30 pips hard stop (30pips from initial entry price)
      Trailing stop of 30 pips
   
      BELINDA POSITION SIZING RULE:
      Sizing based on account size
   */

#define SIGNAL_NONE 0
#define SIGNAL_BUY   1
#define SIGNAL_SELL  2
#define SIGNAL_CLOSEBUY 3
#define SIGNAL_CLOSESELL 4

#property copyright "Expert Advisor Builder"
#property link      "http://sufx.core.t3-ism.net/ExpertAdvisorBuilder/"

extern int MagicNumber = 12345;
extern bool SignalMail = False;
extern double Lots = 1.0;
extern int Slippage = 3;
extern bool UseStopLoss = True;
extern int StopLoss = 30;
extern bool UseTakeProfit = False;
extern int TakeProfit = 0;
extern bool UseTrailingStop = True;
extern int TrailingStop = 30;

extern int sma_short = 10;
extern int sma_long = 40;
extern int atr_period = 20;
extern int atr_shift = 11;

extern bool isSizingOn = true;
extern double Risk = 1;

int P = 1;
int Order = SIGNAL_NONE;
int Total, Ticket, Ticket2;
double StopLossLevel, TakeProfitLevel, StopLevel;
double sma10_1, sma10_2, sma40_1, sma40_2;
double atr_current, atr_past;
bool isYenPair = false;

//TDL 1: Declare variables needed for Cross function (see Function Notes below)

int current_direction, last_direction;
bool first_time;
int hasCrossed;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int init() {
   
   if(Digits == 5 || Digits == 3 || Digits == 1)P = 10;else P = 1; // To account for 5 digit brokers
   if(Digits == 3 || Digits == 2) isYenPair = true; // Adjust for YenPair

   return(0);
}
//+------------------------------------------------------------------+
//| Expert initialization function - END                             |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit() {
   return(0);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function - END                           |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert start function                                            |
//+------------------------------------------------------------------+
int start() {

   Total = OrdersTotal();
   Order = SIGNAL_NONE;

   //+------------------------------------------------------------------+
   //| Variable Setup                                                   |
   //+------------------------------------------------------------------+

   sma10_1 = iMA(NULL, 0, sma_short, 0, MODE_SMA, PRICE_CLOSE, 1); // c
   sma10_2 = iMA(NULL, 0, sma_short, 0, MODE_SMA, PRICE_CLOSE, 2); // b
   sma40_1 = iMA(NULL, 0, sma_long, 0, MODE_SMA, PRICE_CLOSE, 1); // d
   sma40_2 = iMA(NULL, 0, sma_long, 0, MODE_SMA, PRICE_CLOSE, 2); // a
   
   // Part of TDL 3
   hasCrossed = Crossed(sma10_1, sma40_1);
   
   atr_current = iATR(NULL, 0, atr_period, 1);    // ATR(20) now
   atr_past = iATR(NULL, 0, atr_period, atr_shift);      // ATR(20) 10 periods ago
   
   StopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL) + MarketInfo(Symbol(), MODE_SPREAD); // Defining minimum StopLevel

   if (StopLoss < StopLevel) StopLoss = StopLevel;
   if (TakeProfit < StopLevel) TakeProfit = StopLevel;
   
   if (isSizingOn == true) {
      Lots = Risk * 0.01 * AccountBalance() / (MarketInfo(Symbol(),MODE_LOTSIZE) * StopLoss * P * Point); // Sizing Algo based on account size
      if(isYenPair == true) Lots = Lots * 100; // Adjust for Yen Pairs
      Lots = NormalizeDouble(Lots, 2); // Round to 2 decimal place
   }
   //+------------------------------------------------------------------+
   //| Variable Setup - END                                             |
   //+------------------------------------------------------------------+

   //Check position
   bool IsTrade = False;

   for (int i = 0; i < Total; i ++) {
      Ticket2 = OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if(OrderType() <= OP_SELL &&  OrderSymbol() == Symbol()) {
         IsTrade = True;
         if(OrderType() == OP_BUY) {
            //Close

            //+------------------------------------------------------------------+
            //| Signal Begin(Exit Buy)                                           |
            //+------------------------------------------------------------------+

            /* BELINDA EXIT RULES:
               Exit the long trade when SMA(10) crosses SMA(40) from top
               Exit the short trade when SMA(10) crosses SMA(40) from bottom
               30 pips hard stop (30pips from initial entry price)
               Trailing stop of 30 pips
            */
            
            // TDL 3: Replace exit rules with cross function
            
            // ----> See line 109. 
            
            /*
            We can only call the Crossed function once every tick. This is so as calling it more than once a tick will 
            lead to inaccurate data in current_direction and last_direction.
            
            Eg. Let's assume we call it 4 times in a tick. A cross happens. Only the first instance of the Crossed function will register a cross.
            The next 3 instances will never register a cross as current_direction will always equal to last_direction.
            */
            
            /*
            Note: We place it at line 109 because we want it above line 131. This ensures it gets called every tick.
            */
                        
            if(hasCrossed == 2) Order = SIGNAL_CLOSEBUY; // Rule to EXIT a Long trade

            //+------------------------------------------------------------------+
            //| Signal End(Exit Buy)                                             |
            //+------------------------------------------------------------------+

            if (Order == SIGNAL_CLOSEBUY) {
               Ticket2 = OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, MediumSeaGreen);
               if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Bid, Digits) + " Close Buy");
               IsTrade = False;
               continue;
            }
            //Trailing stop
            if(UseTrailingStop && TrailingStop > 0) {                 
               if(Bid - OrderOpenPrice() > P * Point * TrailingStop) {
                  if(OrderStopLoss() < Bid - P * Point * TrailingStop) {
                     Ticket2 = OrderModify(OrderTicket(), OrderOpenPrice(), Bid - P * Point * TrailingStop, OrderTakeProfit(), 0, MediumSeaGreen);
                     continue;
                  }
               }
            }
         } else {
            //Close

            //+------------------------------------------------------------------+
            //| Signal Begin(Exit Sell)                                          |
            //+------------------------------------------------------------------+

            if (hasCrossed == 1) Order = SIGNAL_CLOSESELL; // Rule to EXIT a Short trade

            //+------------------------------------------------------------------+
            //| Signal End(Exit Sell)                                            |
            //+------------------------------------------------------------------+

            if (Order == SIGNAL_CLOSESELL) {
               Ticket2 = OrderClose(OrderTicket(), OrderLots(), Ask, Slippage, DarkOrange);
               if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Ask, Digits) + " Close Sell");
               continue;
            }
            //Trailing stop
            if(UseTrailingStop && TrailingStop > 0) {                 
               if((OrderOpenPrice() - Ask) > (P * Point * TrailingStop)) {
                  if((OrderStopLoss() > (Ask + P * Point * TrailingStop)) || (OrderStopLoss() == 0)) {
                     Ticket2 = OrderModify(OrderTicket(), OrderOpenPrice(), Ask + P * Point * TrailingStop, OrderTakeProfit(), 0, DarkOrange);
                     continue;
                  }
               }
            }
         }
      }
   }

   //+------------------------------------------------------------------+
   //| Signal Begin(Entries)                                            |
   //+------------------------------------------------------------------+

   /* BELINDA ENTRY RULES:
      If Current Volatility (ATR(20)) is greater than Volatility (ATR(20)) 10 hours ago:
      Enter a long trade when SMA(10) crosses SMA(40) from bottom
      Enter a short trade when SMA(10) crosses SMA(40) from top
   */
   
   // TDL 2: Replace entry rules with cross function
   
   if (atr_current > atr_past) {
   
      if (hasCrossed == 1) Order = SIGNAL_BUY; // Rule to ENTER a Long trade
   
      if (hasCrossed == 2) Order = SIGNAL_SELL; // Rule to ENTER a Short trade

   }
   
   //+------------------------------------------------------------------+
   //| Signal End                                                       |
   //+------------------------------------------------------------------+

   //Buy
   if (Order == SIGNAL_BUY) {
      if(!IsTrade) {
         //Check free margin
         if (AccountFreeMargin() < (1000 * Lots)) {
            Print("We have no money. Free Margin = ", AccountFreeMargin());
            return(0);
         }

         if (UseStopLoss) StopLossLevel = Ask - StopLoss * Point * P; else StopLossLevel = 0.0;
         if (UseTakeProfit) TakeProfitLevel = Ask + TakeProfit * Point * P; else TakeProfitLevel = 0.0;

         Ticket = OrderSend(Symbol(), OP_BUY, Lots, Ask, Slippage, StopLossLevel, TakeProfitLevel, "Buy(#" + MagicNumber + ")", MagicNumber, 0, DodgerBlue);
         if(Ticket > 0) {
            if (OrderSelect(Ticket, SELECT_BY_TICKET, MODE_TRADES)) {
				Print("BUY order opened : ", OrderOpenPrice());
                if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Ask, Digits) + " Open Buy");
			} else {
				Print("Error opening BUY order : ", GetLastError());
			}
         }
         return(0);
      }
   }

   //Sell
   if (Order == SIGNAL_SELL) {
      if(!IsTrade) {
         //Check free margin
         if (AccountFreeMargin() < (1000 * Lots)) {
            noMoneyPrint();
            return(0);
         }

         if (UseStopLoss) StopLossLevel = Bid + StopLoss * Point * P; else StopLossLevel = 0.0;
         if (UseTakeProfit) TakeProfitLevel = Bid - TakeProfit * Point * P; else TakeProfitLevel = 0.0;

         Ticket = OrderSend(Symbol(), OP_SELL, Lots, Bid, Slippage, StopLossLevel, TakeProfitLevel, "Sell(#" + MagicNumber + ")", MagicNumber, 0, DeepPink);
         if(Ticket > 0) {
            if (OrderSelect(Ticket, SELECT_BY_TICKET, MODE_TRADES)) {
				Print("SELL order opened : ", OrderOpenPrice());
                if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Bid, Digits) + " Open Sell");
			} else {
				Print("Error opening SELL order : ", GetLastError());
			}
         }
         return(0);
      }
   }

   return(0);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
// FUNCTION LIBRARY                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
// Customized Print                                                  |
//+------------------------------------------------------------------+
void noMoneyPrint(){

   Print("We have no money. Free Margin = ", AccountFreeMargin());

}
//+------------------------------------------------------------------+
// End of Customized Print                                           |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
// Cross                                                             |
//+------------------------------------------------------------------+

/* 

Function Notes:

Declare these before the init() of the EA 

int current_direction, last_direction;
bool first_time;

----  

If Output is 0: No cross happened
If Output is 1: Line 1 crossed Line 2 from Bottom
If Output is 2: Line 1 crossed Line 2 from top 

*/

int Crossed(double line1 , double line2) 
  {

//----
    if(line1 > line2)
        current_direction = 1;  // line1 above line2
    if(line1 < line2)
        current_direction = 2;  // line1 below line2
//----
    if(first_time == true) // Need to check if this is the first time the function is run
      {
        first_time = false; // Change variable to false
        last_direction = current_direction; // Set new direction
        return (0);
      }

    if(current_direction != last_direction && first_time == false)  // If not the first time and there is a direction change
      {
        last_direction = current_direction; // Set new direction
        return(current_direction); // 1 for up, 2 for down
      }
    else
      {
        return (0);  // No direction change
      }
  }


//+------------------------------------------------------------------+
// End of Cross                                                      |
//+------------------------------------------------------------------+

