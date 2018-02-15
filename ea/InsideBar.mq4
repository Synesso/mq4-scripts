#property link      "chenandjem@loftinspace.com.au"
#property strict

//--------------------------------------------------------------------

extern int    sl_points            = 10,
              open_after           = 20,
              slippage             = 10,
              start_hour           = 2,
              end_hour             = 18,
              avg_volume_periods   = 14,
              Magic                = 778;
extern double Lot                  = 0.1,
              tp_multiplier        = 1.3,
              volume_trigger       = 1.5;
extern bool   require_time_check   = false,
              require_volume_check = false;

const int state_waiting = 0;
const int state_inside_formed = 1;
double entry_buy, entry_sell, mother_high, mother_low;
const int state_inside_broken_up = 2;
const int state_inside_broken_down = 3;
double buy_trigger_price;

int current_state = state_waiting;
double tp = 0, sl = 0;
datetime last_action_time;

//--------------------------------------------------------------------

void OnTick()
{
   for (int i=0; i<OrdersTotal(); i++)
      if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
         if (OrderSymbol()==Symbol() && Magic==OrderMagicNumber()) return;
               
   double avg_volume = 0.0;
   for (int i=1; i<=avg_volume_periods; i++) {
     avg_volume += Volume[i] * 1.0;
   }
   avg_volume /= avg_volume_periods;
   bool ok_volume = !require_volume_check || ((Volume[0] / avg_volume) >= volume_trigger);
      
   bool ok_time = !require_time_check || (
     (start_hour < end_hour && TimeHour(Time[0]) >= start_hour && TimeHour(Time[0]) < end_hour) ||
     (start_hour > end_hour && (TimeHour(Time[0]) >= start_hour || TimeHour(Time[0]) < end_hour))
   );
   
   bool ok_candle = last_action_time != Time[0];
   
   if (current_state == state_waiting && ok_candle) {
     if (High[1] <= High[2] && Low[1] >= Low[2]) {
       current_state = state_inside_formed;
       entry_buy = High[1] + (open_after * Point);
       entry_sell = Low[1] - (open_after * Point);
       mother_high = High[2];
       mother_low = Low[2];
       Print("Inside bar formed. Will place order above ", entry_buy, " or below ", entry_sell);
     }
   }
   
   if (current_state == state_inside_formed) {
     if (Close[0] > entry_buy) {
       current_state = state_inside_broken_up;
     } else if (Close[0] < entry_sell) {
       current_state = state_inside_broken_down;
     }
   }
   
   if (current_state == state_inside_broken_up) {
     current_state = state_waiting;
     last_action_time = Time[0];
     sl = NormalizeDouble(mother_low - (sl_points * Point),Digits); // sl is below low of mother by `sl_points`
     double distance_tp = (Close[0] - sl) * tp_multiplier; // tp is `tp_multiplier` x distance to stop loss
     tp = Close[0] + distance_tp;
     // Print("sl=", sl, " & close[0]=", Close[0], " & distance_tp=", distance_tp);
     // Print("broken up. sl=", sl, " being low of mother - ", sl_points, ". tp is ", tp, " being ", tp_multiplier, " * ", distance_tp);
     if (ok_time && ok_volume && OrderSend(Symbol(),OP_BUY, Lot,NormalizeDouble(Ask,Digits),slippage,sl,tp,NULL,Magic)==-1) Print(GetLastError());
     
   } else if (current_state == state_inside_broken_down) {
     current_state = state_waiting;
     last_action_time = Time[0];
     sl = NormalizeDouble(mother_high + (sl_points * Point),Digits); // sl is below low of mother by `sl_points`
     double distance_tp = (sl - Close[0]) * tp_multiplier; // tp is `tp_multiplier` x distance to stop loss
     tp = Close[0] - distance_tp;
     // Print("broken down. sl=", sl, " being high of mother + ", sl_points, ". tp is ", tp, " being ", tp_multiplier, " * ", distance_tp);
     // Print("sl=", sl, " & close[0]=", Close[0], " & distance_tp=", distance_tp);
     if (ok_time && ok_volume && OrderSend(Symbol(),OP_SELL,Lot,NormalizeDouble(Bid,Digits),slippage,sl,tp,NULL,Magic)==-1) Print(GetLastError());
   }
}
