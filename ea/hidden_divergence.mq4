#property link      "chenandjem@loftinspace.com.au"
#property strict

//--- input parameters
input int period = 21;
input int rsi_period = 14;
input double minstoplevel = 1000.0;

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

/*
 * Checks once per hour and notifies most once per candle.
 */
void OnTick() {

    int block = Hour();

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
            SendNotification("" + Symbol() + " SB Hidden Divergence(" + period + ") *long*, RSI(" + rsi_period + ")=" + DoubleToStr(currentRSI, 3) + "(min), Price=" + DoubleToStr(currentPrice, 5));
            lastSignalBars = Bars;
        }

        else if (currentRSI == maxRSI && currentPrice != maxPrice) {
            SendNotification("" + Symbol() + " SB Hidden Divergence(" + period + ") *short*, RSI(" + rsi_period + ")=" + DoubleToStr(currentRSI, 3) + "(max), Price=" + DoubleToStr(currentPrice, 5));
            lastSignalBars = Bars;
        }
    }
}
