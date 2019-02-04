//+------------------------------------------------------------------+
//|                                            trade_on_breakout.mq4 |
//|                                    chenandjem@loftinspace.com.au |
//|                                               loftinspace.com.au |
//+------------------------------------------------------------------+
#property copyright "chenandjem@loftinspace.com.au"
#property link      "loftinspace.com.au"
#property version   "1.00"
#property strict

input double    trigger = 1.145;
input double    lots = 0.1;
input double    open = 1.144;
input double    stop_loss = 1.142;
input double    take_profit = 1.148;

const int       LONG = 0;
const int       SHORT = 1;

int             direction;
int             order_ticket_number = 0;
int             bars_on_chart = 0;

int OnInit() {
    if (stop_loss < open && open < take_profit) {
        direction = LONG;
        Print("Direction is Long");
    } else if (stop_loss > open && open > take_profit) {
        direction = SHORT;
        Print("Direction is Short");
    } else {
        MessageBox("Exiting: Cannot determine if direction is short or long. Must match (tp > open > sl) or (tp < open < sl)");
        ExpertRemove();
    }

    double min_stop_level = MarketInfo(Symbol(), MODE_STOPLEVEL);
    require(MathAbs(trigger - open) >= min_stop_level, StringFormat("Open is too close to trigger. Must be at least %f", minimum_stop);
    require(MathAbs(open - stop_loss) >= min_stop_level, StringFormat("Stop loss is too close to open. Must be at least %f", minimum_stop);
    require(MathAbs(open - take_profit) >= min_stop_level, StringFormat("Take profit is too close to open. Must be at least %f", minimum_stop);

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
