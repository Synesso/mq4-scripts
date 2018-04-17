#property link      "chenandjem@loftinspace.com.au"
#property strict

/*
 * A key reversal (higher high [lower low] than previous bar and close below [above] prior close) and range of bar
 * is greater than the average range of the last 20 days or weeks.  A J Spike is a reversal warning (not a signal).
 * During strong trends, there will be some terrible false warnings.  In other words, additional analysis (pattern, 
 * momentum and trend analysis) is required…as always.  Weekly J Spikes carry more weight than daily J Spikes, which 
 * is more prone to alerting a false reversal.
 */


static int NumBars;

void OnTick() {
  if (NumBars == Bars || Bars <= 21) {
    return;
  }
  NumBars = Bars;

  if (High[1] > High[2] && Close[1] < Close[2] && (High[1] - Low[1]) > avg_range()) {
    SendNotification("" + Symbol() + " " + Period() + " J-Spike. Higher high, close below & range > avg of last 20");
  } else if (Low[1] < Low[2] && Close[1] > Close[2] && (High[1] - Low[1]) > avg_range()) {
    SendNotification("" + Symbol() + " " + Period() + " J-Spike. Lower low, close above & range > avg of last 20");
  }
}

double avg_range() {
    int count = 0;
    double sum = 0.0;
    for (int i = 2; i <= 21; i++) {
        count += 1;
        sum += High[i] - Low[i];
    }
    return sum / count;
}