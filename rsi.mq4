#property link      "chenandjem@loftinspace.com.au"
#property strict

//--------------------------------------------------------------------

extern int     period_RSI           = 14,
               stoploss             = 500,
               takeprofit           = 500,
               slippage             = 10,
               buy_level            = 35,
               buy_trigger_level    = 20,
               sell_level           = 70,
               sell_trigger_level   = 85,
               Magic                = 777;
extern double  Lot                  = 0.1;

bool buy_trigger_hit = False;
bool sell_trigger_hit = False;

//--------------------------------------------------------------------

void OnTick()
{
   for (int i=0; i<OrdersTotal(); i++)
      if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
         if (OrderSymbol()==Symbol() && Magic==OrderMagicNumber()) return;
         
   double RSI0  = iRSI(NULL,0,period_RSI,PRICE_OPEN,0);
   double RSI1  = iRSI(NULL,0,period_RSI,PRICE_OPEN,1);
   double SL=0,TP=0;
   
   if (!buy_trigger_hit && RSI0 <= buy_trigger_level) {
       buy_trigger_hit = True;
       SendNotification("" + Symbol() + " RSI " + DoubleToStr(RSI0, 3) + " is below " + DoubleToStr(buy_trigger_level, 0));
   }
   
   if (!sell_trigger_hit && RSI0 >= sell_trigger_level) {
       sell_trigger_hit = True;
       SendNotification("" + Symbol() + " RSI " + DoubleToStr(RSI0, 3) + " is above " + DoubleToStr(sell_trigger_level, 0));

   }
   
   if (buy_trigger_hit && RSI0 > buy_level && RSI1 < buy_level)
   {
      // Print("buying at ", RSI0);
      buy_trigger_hit = False;
      if (takeprofit!=0) TP  = NormalizeDouble(Ask + takeprofit*Point,Digits);
      if (stoploss!=0)   SL  = NormalizeDouble(Ask - stoploss*  Point,Digits);     
      if (OrderSend(Symbol(),OP_BUY, Lot,NormalizeDouble(Ask,Digits),slippage,SL,TP,NULL,Magic)==-1) Print(GetLastError());
   } else if (sell_trigger_hit && RSI0 < sell_level && RSI1 > sell_level)
   {
      // Print("selling at ", RSI0);
      sell_trigger_hit = False;
      if (takeprofit!=0) TP = NormalizeDouble(Bid - takeprofit*Point,Digits);
      if (stoploss!=0)   SL = NormalizeDouble(Bid + stoploss*  Point,Digits);            
      if (OrderSend(Symbol(),OP_SELL,Lot,NormalizeDouble(Bid,Digits),slippage,SL,TP,NULL,Magic)==-1) Print(GetLastError());
   }
}
