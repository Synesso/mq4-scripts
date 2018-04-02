#property link      "chenandjem@loftinspace.com.au"
#property strict

//--- input parameters
input double      above;

static int NumBars;

void OnTick() {
  if (NumBars == Bars) {
    return;
  }
  NumBars = Bars;

  if (Close[1] > above) {
    SendNotification("" + Symbol() + " closed above " + DoubleToStr(above, 3));
  }

}
