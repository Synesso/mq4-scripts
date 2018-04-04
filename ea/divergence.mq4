#property link      "chenandjem@loftinspace.com.au"
#property strict

//--- input parameters
input int period = 21;
input int rsi_period = 14;

int lastSignalBars = -1;

/*
 * Checks once per hour and notifies most once per candle.
 */
void OnTick() {

    if (lastSignalBars != Bars) {
        lastSignalBars = Bars;

        double rsi_lows[];
        double rsi_highs[];
        double price_lows[];
        double price_highs[];

        ArrayResize(rsi_lows, 0);
        ArrayResize(rsi_highs, 0);
        ArrayResize(price_lows, 0);
        ArrayResize(price_highs, 0);

        for (int i = 2; i < MathMin(period + 1, Bars); i++) {
            double a = iRSI(_Symbol, 0, rsi_period, PRICE_CLOSE, i - 1);
            double b = iRSI(_Symbol, 0, rsi_period, PRICE_CLOSE, i);
            double c = iRSI(_Symbol, 0, rsi_period, PRICE_CLOSE, i + 1);
            if (a < b && b > c && b >= 65.0) {
                int l = ArraySize(rsi_highs);
                ArrayResize(rsi_highs, l + 1);
                rsi_highs[l] = b;
            } else if (a > b && b < c && a < 35.0) {
                int l = ArraySize(rsi_lows);
                ArrayResize(rsi_lows, l + 1);
                rsi_lows[l] = b;
            }

            a = High[i - 1];
            b = High[i];
            c = High[i + 1];
            if (a < b && b > c) {
                int l = ArraySize(price_highs);
                ArrayResize(price_highs, l + 1);
                price_highs[l] = b;
            }
            
            a = Low[i - 1];
            b = Low[i];
            c = Low[i + 1];
            if (a > b && b < c) {
                int l = ArraySize(price_lows);
                ArrayResize(price_lows, l + 1);
                price_lows[l] = b;
            }
        }

        int rsi_peak = JustPeaked();

        if (rsi_peak == 1 && ArraySize(rsi_highs) >= 2 && rsi_highs[0] < rsi_highs[1] && ArraySize(price_highs) >= 2 && price_highs[0] > price_highs[1]) {
            Print("" + _Symbol + " RSI Divergence(" + period + ") SHORT - Price higher highs (" + 
                price_highs[1] +", " + price_highs[0]+"), RSI lower highs (" + rsi_highs[1] +", "+ rsi_highs[0]+")");
        }

        if (rsi_peak == -1 && ArraySize(rsi_lows) >= 2 && rsi_lows[0] > rsi_lows[1] && ArraySize(price_lows) >= 2 && price_lows[0] < price_lows[1]) {
            Print("" + _Symbol + " RSI Divergence(" + period + ") LONG - Price lower lows (" + 
                price_lows[1] +", " + price_lows[0]+"), RSI higher lows (" + rsi_lows[1] +", "+ rsi_lows[0]+")");
        }



/*        
        if (currentRSI == minRSI && currentPrice != minPrice) {
            SendNotification("" + Symbol() + " SB Hidden Divergence(" + period + ") *long*, RSI(" + rsi_period + ")=" + DoubleToStr(currentRSI, 3) + "(min), Price=" + DoubleToStr(currentPrice, 5));
            lastSignalBars = Bars;
        }

        else if (currentRSI == maxRSI && currentPrice != maxPrice) {
            SendNotification("" + Symbol() + " SB Hidden Divergence(" + period + ") *short*, RSI(" + rsi_period + ")=" + DoubleToStr(currentRSI, 3) + "(max), Price=" + DoubleToStr(currentPrice, 5));
            lastSignalBars = Bars;
        }
*/
    }
}

int JustPeaked() {
    double a = iRSI(_Symbol, 0, rsi_period, PRICE_CLOSE, 1;
    double b = iRSI(_Symbol, 0, rsi_period, PRICE_CLOSE, 2);
    double c = iRSI(_Symbol, 0, rsi_period, PRICE_CLOSE, 3);
    if (a < b && b > c) {
        return(1);
    } else if (a < b && b > c) {
        return(-1);
    } else {
        return(0);
    }
}