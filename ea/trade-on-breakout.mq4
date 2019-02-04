//+------------------------------------------------------------------+
//|                                            trade_on_breakout.mq4 |
//|                                    chenandjem@loftinspace.com.au |
//|                                               loftinspace.com.au |
//+------------------------------------------------------------------+
#property copyright "chenandjem@loftinspace.com.au"
#property link      "loftinspace.com.au"
#property version   "1.00"
#property strict

input double    breakout_level;
input double    lots = 0.1;
input double    open;
input double    stop_loss;
input double    take_profit;
input double    buffer = 0.0005;

const int       LONG = 0;
const int       SHORT = 1;

double          trigger;
int             direction;
int             order_ticket_number;
int             bars_on_chart;
long            chart_id;

int OnInit() {
    if (stop_loss < open && open < take_profit) {
        direction = LONG;
        trigger = breakout_level + buffer;
        Print("Direction is Long. Trigger is ", trigger);
    } else if (stop_loss > open && open > take_profit) {
        direction = SHORT;
        trigger = breakout_level - buffer;
        Print("Direction is Short. Trigger is ", trigger);
    } else {
        MessageBox("Exiting: Cannot determine if direction is short or long. Must match (tp > open > sl) or (tp < open < sl)");
        ExpertRemove();
    }

    chart_id = ChartID();
    
    double minimum_stop = MarketInfo(Symbol(), MODE_STOPLEVEL);
    require(MathAbs(trigger - open) >= minimum_stop, StringFormat("Open is too close to trigger. Must be at least %f", minimum_stop));
    require(MathAbs(open - stop_loss) >= minimum_stop, StringFormat("Stop loss is too close to open. Must be at least %f", minimum_stop));
    require(MathAbs(open - take_profit) >= minimum_stop, StringFormat("Take profit is too close to open. Must be at least %f", minimum_stop));

    ObjectCreate("breakout_level", OBJ_HLINE, 0, Time[0], breakout_level, 0, 0);
    ObjectCreate("trigger", OBJ_HLINE, 0, Time[0], trigger, 0, 0);
    ObjectCreate("open", OBJ_HLINE, 0, Time[0], open, 0, 0);
    ObjectCreate("stop_loss", OBJ_HLINE, 0, Time[0], stop_loss, 0, 0);
    ObjectCreate("take_profit", OBJ_HLINE, 0, Time[0], take_profit, 0, 0);

    ObjectSetInteger(chart_id, "open", OBJPROP_COLOR, clrLightBlue);
    ObjectSetInteger(chart_id, "open", OBJPROP_STYLE, STYLE_DOT);
    ObjectSetInteger(chart_id, "stop_loss", OBJPROP_COLOR, clrLightPink);
    ObjectSetInteger(chart_id, "stop_loss", OBJPROP_STYLE, STYLE_DOT);
    ObjectSetInteger(chart_id, "take_profit", OBJPROP_COLOR, clrHoneydew);
    ObjectSetInteger(chart_id, "take_profit", OBJPROP_STYLE, STYLE_DOT);
    ObjectSetInteger(chart_id, "breakout_level", OBJPROP_COLOR, clrForestGreen);
    ObjectSetInteger(chart_id, "trigger", OBJPROP_COLOR, clrForestGreen);
    ObjectSetInteger(chart_id, "trigger", OBJPROP_STYLE, STYLE_DASH);

    return(INIT_SUCCEEDED);
}

void OnTick() {
    if (isNewCandle()) {
        if (direction == LONG && Close[1] > trigger) {
            int slippage = int(2.0 * (Ask - Bid) / _Point);
            Print(StringFormat("Issuing OrderSend(%s, OP_BUYLIMIT, lots=%f, open=%f, slippage=%d, stop_loss=%f, take_profit=%f)",
                Symbol(), lots, open, slippage, stop_loss, take_profit
            ));
            int ticket = OrderSend(Symbol(), OP_BUYLIMIT, lots, open, slippage, stop_loss, take_profit, "trade_on_breakout_EA");
            if (ticket < 0) {
                SendNotification("Unable to create buy limit order: " + IntegerToString(GetLastError()));
            }
            ExpertRemove();
        } else if (direction == SHORT && Close[1] < trigger) {
            int slippage = int(2.0 * (Ask - Bid) / _Point);
            Print(StringFormat("Issuing OrderSend(%s, OP_SELLLIMIT, lots=%f, open=%f, slippage=%d, stop_loss=%f, take_profit=%f)",
                Symbol(), lots, open, slippage, stop_loss, take_profit
            ));
            int ticket = OrderSend(Symbol(), OP_SELLLIMIT, lots, open, slippage, stop_loss, take_profit, "trade_on_breakout_EA");
            if (ticket < 0) {
                SendNotification("Unable to create sell limit order: " + IntegerToString(GetLastError()));
            }
            ExpertRemove();
        }
    }
}

bool isNewCandle() {
    bool isNew = bars_on_chart != Bars;
    bars_on_chart = Bars;
    return(isNew);
}

void require(bool predicate, string msg) {
    if (!predicate) {
        MessageBox("Exiting: " + msg + ": " + IntegerToString(GetLastError()));
        ExpertRemove();
    }
}

int selectOrder() {
    int num_open_orders = 0;
    for (int i = 0; i < OrdersTotal(); i++) { 
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) && OrderSymbol() == Symbol()) {
            order_ticket_number = OrderTicket();
            Print("Selected ticket " + DoubleToString(order_ticket_number));
            num_open_orders += 1;
        }
    }
    ensure(OrderSelect(order_ticket_number, SELECT_BY_TICKET), "trouble selecting previously found order");
    return num_open_orders;
}

bool ensure(bool predicate, string msg) {
    if (!predicate) {
        SendNotification("Requirement failed: " + msg + ": " + IntegerToString(GetLastError()));
    }
    return predicate;
}

void OnDeinit(const int reason) {
    ObjectDelete(chart_id, "open");
    ObjectDelete(chart_id, "stop_loss");
    ObjectDelete(chart_id, "take_profit");
    ObjectDelete(chart_id, "breakout_level");
    ObjectDelete(chart_id, "trigger");
}