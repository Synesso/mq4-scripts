#property link      "chenandjem@loftinspace.com.au"
#property strict

//--- input parameters
input int period = 21;
input int rsi_period = 14;
extern double Lot = 0.1;
extern int slippage = 10,
           magic = 62;

int lastBlock = -1;
int lastSignalBars = -1;

int OnInit() {
  Print(MarketInfo(Symbol(), MODE_LOTSIZE));
  Print(MarketInfo(Symbol(), MODE_MINLOT));
  Print(MarketInfo(Symbol(), MODE_LOTSTEP));
  Print(MarketInfo(Symbol(), MODE_MAXLOT));
  return(0);
}

void OnTick() {

    int block = Minute() / 6;

    if (lastBlock != block && lastSignalBars != Bars) {
        lastBlock = block;

        double currentPrice = Close[0];
        double currentRSI = iRSI(_Symbol,0,rsi_period,PRICE_CLOSE,0);

        double minRSI = currentRSI;
        double minPrice = currentPrice;
        double maxRSI = currentRSI;
        double maxPrice = currentPrice;

        for (int i = 1; i < MathMin(period, Bars); i++) {
            double rsi = iRSI(_Symbol,0,rsi_period,PRICE_CLOSE,i);
            double price = Close[i];
            minRSI = MathMin(minRSI, rsi);
            maxRSI = MathMax(maxRSI, rsi);
            minPrice = MathMin(minPrice, price);
            maxPrice = MathMax(maxPrice, price);
        }
        
        if (currentRSI == minRSI && currentPrice != minPrice) {
            if (OrderSend(Symbol(),OP_BUY,Lot,NormalizeDouble(Ask,Digits),slippage,0.0,0.0,NULL,magic)==-1) Print(GetLastError());
            lastSignalBars = Bars;
            Print("Buying when RSI is at " + DoubleToStr(currentRSI));
        }

        else if (currentRSI == maxRSI && currentPrice != maxPrice) {
            if (OrderSend(Symbol(),OP_SELL,Lot,NormalizeDouble(Bid,Digits),slippage,0.0,0.0,NULL,magic)==-1) Print(GetLastError());
            lastSignalBars = Bars;
        }


        //SendNotification("" + Symbol() + " RSI " + DoubleToStr(RSI0, 3) + " has crossed above " + DoubleToStr(above, 0));

    }
}
