#property link      "chenandjem@loftinspace.com.au"
#property strict

static int NumBars;

const int state_waiting = 0;
const int state_inside_formed = 1;

double entry_buy, entry_sell, mother_high, mother_low;
int current_state = state_waiting;


void OnTick() {
  if (NumBars == Bars) {
    return;
  }
  NumBars = Bars;

  if (current_state == state_waiting) {
    if (High[1] <= High[2] && Low[1] >= Low[2]) {
      current_state = state_inside_formed;
      mother_high = High[2];
      mother_low = Low[2];
      SendNotification("" + Symbol() + "Inside bar formed.");
    }
  } else if (current_state == state_inside_formed) {
    if (Close[0] > mother_high) {
      SendNotification("" + Symbol() + " Inside bar broke above mother");
      current_state = state_waiting;
    } else if (Close[1] < mother_low) {
      SendNotification("" + Symbol() + " Inside bar broke below mother");
      current_state = state_waiting;
    }
  }
}
