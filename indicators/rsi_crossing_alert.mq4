#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//--- input parameters
input int      above=65;
input int      below=35;
input int      period=14;

static int NumBars;

void OnTick() {
  Print("NumBars=" + IntegerToString(NumBars));
  Print("Bars=" + IntegerToString(Bars));
  
  if (NumBars == Bars) {
    return;
  }
  NumBars = Bars;

  double RSI0  = iRSI(NULL,0,period,PRICE_OPEN,0);
  double RSI1  = iRSI(NULL,0,period,PRICE_OPEN,1);

  Print("RSI0="+RSI0);
  Print("RSI1=" + RSI1);

  if (RSI0 > above && RSI1 < above) {
    SendNotification("" + Symbol() + " RSI " + DoubleToStr(RSI0, 3) + " has crossed above " + DoubleToStr(above, 0));
  }

  if (RSI0 < below && RSI1 > below) {
    SendNotification("" + Symbol() + " RSI " + DoubleToStr(RSI0, 3) + " has crossed below " + DoubleToStr(below, 0));
  }

}
