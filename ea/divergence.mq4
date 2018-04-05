#property link      "chenandjem@loftinspace.com.au"
#property strict

//--- input parameters
input int period = 21;
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

    if (lastSignalBars != Bars) {
        lastSignalBars = Bars;

        // RSIs
        double rsi_1 = iRSI(_Symbol, 0, rsi_period, PRICE_CLOSE, 1);
        double rsi_2 = iRSI(_Symbol, 0, rsi_period, PRICE_CLOSE, 2);
        double rsi_3 = iRSI(_Symbol, 0, rsi_period, PRICE_CLOSE, 3);

        bool rsiHigh = rsi_1 < rsi_2 && rsi_3 < rsi_2;
        bool rsiLowerHigh = rsiHigh && rsiPreviousHigh != 0.0 && rsi_2 < rsiPreviousHigh;

        bool rsiLow = rsi_1 > rsi_2 && rsi_3 > rsi_2;
        bool rsiHigherLow = rsiLow && rsiPreviousLow != 0.0 && rsi_2 > rsiPreviousLow;

        // Prices
        bool priceHigh = High(1) < High(2) && High(3) < High(2);
        bool priceHigherHigh = priceHigh && pricePreviousHigh != 0.0 && High(2) > pricePreviousHigh;

        bool priceLow = Low(1) > Low(2) && Low(3) > Low(2);
        bool priceLowerLow = priceLow && pricePreviousLow != 0.0 && Low(2) < pricePreviousLow;

        // Set state for next iteration
        if (rsiHigh) {
            rsiPreviousHigh = rsi_2;
        } else if (rsiLow) {
            rsiPreviousLow = rsi_2;
        }

        if (priceHigh) {
            pricePreviousHigh = High(2);
        } else if (priceLow) {
            pricePreviousLow = Low(2);
        }

        if (priceHigherHigh && rsiLowerHigh) {
            SendNotification("" + Symbol() + " RSI Divergence(" + period + ") Bearish");
        } else if (priceLowerLow && rsiHigherLow) {
            SendNotification("" + Symbol() + " RSI Divergence(" + period + ") Bullish");
        }
    }
}

double High(int idx) {
    return(MathMax(Close[idx], Open[idx]));
}

double Low(int idx) {
    return(MathMin(Close[idx], Open[idx]));
}
