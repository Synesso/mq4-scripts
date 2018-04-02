#property link      "chenandjem@loftinspace.com.au"
#property strict

//--- input parameters
input int      above=65;
input int      below=35;
input int      period=14;

static int NumBars;

void OnTick() {
  double RSI0  = iRSI(NULL,0,period,PRICE_OPEN,0);
  double RSI1  = iRSI(NULL,0,period,PRICE_OPEN,1);

  bool can_notify = NumBars != Bars;

  if (can_notify && RSI0 > above && RSI1 < above) {
    SendNotification("" + Symbol() + " RSI " + DoubleToStr(RSI0, 3) + " has crossed above " + DoubleToStr(above, 0));
    NumBars = Bars;
  } else if (can_notify && RSI0 < below && RSI1 > below) {
    SendNotification("" + Symbol() + " RSI " + DoubleToStr(RSI0, 3) + " has crossed below " + DoubleToStr(below, 0));
    NumBars = Bars;
  }

}
