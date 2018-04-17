#property link      "chenandjem@loftinspace.com.au"
#property strict

//--- input parameters
input int period = 60;
input int rsi_period = 14;

int lastSignalBars = -1;

double rsiPreviousHigh = 0.0,
       rsiPreviousLow = 0.0,
       pricePreviousHigh = 0.0,
       pricePreviousLow = 0.0;

/*
 * Checks once per hour and notifies most once per candle.
 */
void OnTick() {

    // todo - BullDiv when >= 35.0, Bear when <= 65.0

    if (lastSignalBars != Bars) {
        lastSignalBars = Bars;

        double lastRSI = iRSI(_Symbol, 0, rsi_period, PRICE_CLOSE, 1);
        double lastPrice = Close[1];

        bool lowestRSI = true;
        bool highestRSI = true;
        bool lowestPrice = true;
        bool highestPrice = true;

        Print("rsi="+lastRSI+", price="+lastPrice);

        for (int i = 2; i < MathMin(period, Bars) && (lowestPrice || highestPrice); i++) {
            double rsi = iRSI(_Symbol, 0, rsi_period, PRICE_CLOSE, i);
            lowestRSI = lowestRSI && rsi >= lastRSI;
            lowestPrice = lowestPrice && Close[i] >= lastPrice;
            highestRSI = highestRSI && rsi <= lastRSI;
            highestPrice = highestPrice && Close[i] <= lastPrice;
            Print("i="+i+", rsi="+rsi+", lowestRSI="+lowestRSI+", lowestPrice="+lowestPrice+", highestRSI="+highestRSI+", highestPrice="+highestPrice);
        }

        if (lowestPrice && !lowestRSI) {
            SendNotification("" + Symbol() + " RSI Divergence(" + period + ") Bullish");
        } else if (highestPrice && !highestRSI) {
            SendNotification("" + Symbol() + " RSI Divergence(" + period + ") Bearish");
        }
    }
}
