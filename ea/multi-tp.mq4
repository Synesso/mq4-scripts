#property link "chenandjem@loftinspace.com.au"
#property strict

input int       order_num;
input double    trigger;
input double    close_lots;
input double    move_stop;

bool going_long = false;
bool stop_needs_modifying = true;
long chart_id;
int  order_number;

int OnInit() {
    order_number = order_num;
    require(OrderSelect(order_number, SELECT_BY_TICKET), "cannot select order" + IntegerToString(order_number));

    Print("[multitp] Current Order: #", order_number, " ", OrderSymbol(), 
        ", direction=", typeCode(OrderType()),
        ", open=", DoubleToString(OrderOpenPrice()),
        ", lots=", DoubleToString(OrderLots()),
        ", tp=", DoubleToString(OrderTakeProfit()),
        ", sl=", DoubleToString(OrderStopLoss())); 

    Print("[multitp] Config: order_number=", DoubleToString(order_number),
        ", trigger=", DoubleToString(trigger),
        ", close_lots=", DoubleToString(close_lots),
        ", move_stop=", DoubleToString(move_stop));

    if (OrderType() == OP_BUY) {
        require(trigger > Bid, "First TP " + DoubleToString(trigger) + " is less than the current Bid. " + DoubleToString(Ask) + " It would execute immediately.");
        require(OrderTakeProfit() == 0 || trigger <= OrderTakeProfit(), "First TP " + DoubleToString(trigger) + " is greater than the real TP. It would never execute.");
        require(move_stop >= OrderStopLoss(), "Break-even SL " + DoubleToString(move_stop) + " is less than the original stop loss.");
        require(move_stop < trigger, "Break-even SL " + DoubleToString(move_stop) + " is greater than the first TP.");
        going_long = true;
        stop_needs_modifying = OrderStopLoss() != move_stop;
    } else if (OrderType() == OP_SELL) {
        require(trigger < Ask, "First TP " + DoubleToString(trigger) + " is greater than the current Ask. " + DoubleToString(Bid) + " It would execute immediately.");
        require(OrderTakeProfit() == 0 || trigger >= OrderTakeProfit(), "First TP " + DoubleToString(trigger) + " is less than the real TP. It would never execute.");
        require(move_stop <= OrderStopLoss() || OrderStopLoss() == 0, "Break-even SL " + DoubleToString(move_stop) + " is greater than the original stop loss.");
        require(move_stop > trigger, "Break-even SL " + DoubleToString(move_stop) + " is less than the first TP.");
        stop_needs_modifying = OrderStopLoss() != move_stop;
    } else {
        require(false, "Do not know how to proceed with order of type " + IntegerToString(OrderType()));
    }

    Print("Stop needs modifying? ", stop_needs_modifying);

    chart_id = ChartID();
    ObjectCreate("trigger", OBJ_HLINE, 0, Time[0], trigger, 0, 0);
    ObjectSetInteger(chart_id, "trigger", OBJPROP_COLOR, clrDodgerBlue);
    ObjectSetInteger(chart_id, "trigger", OBJPROP_STYLE, STYLE_DOT);
    if (stop_needs_modifying) {
        ObjectCreate("move_stop", OBJ_HLINE, 0, Time[0], move_stop, 0, 0);
        ObjectSetInteger(chart_id, "move_stop", OBJPROP_COLOR, clrTomato);
        ObjectSetInteger(chart_id, "move_stop", OBJPROP_STYLE, STYLE_DOT);
    }

    return(INIT_SUCCEEDED);
}

void OnTick() {
    if (going_long) {
        if (Bid > trigger) {
            int slippage = int(2.0 * (Ask - Bid) / _Point);
            string symbol = OrderSymbol();
            double open = OrderOpenPrice();
            double stop = OrderStopLoss();
            double tp = OrderTakeProfit();
            if (ensure(OrderClose(order_number, close_lots, Bid, slippage, Red), "Unable to close order")) {
                if (stop_needs_modifying) {
                    selectOrder(symbol, open, stop, tp); // it has a new order number after closing half
                    ensure(OrderModify(order_number, OrderOpenPrice(), move_stop, OrderTakeProfit(), OrderExpiration(), Red), "Unable to modify SL"); 
                }
                SendNotification("First TP hit. Closed out " + DoubleToString(close_lots) + " lots. Set SL to " + DoubleToString(move_stop));
                ExpertRemove();
            }
        }
    } else {
        if (Ask < trigger) {
            int slippage = int(2.0 * (Ask - Bid) / _Point);
            string symbol = OrderSymbol();
            double open = OrderOpenPrice();
            double stop = OrderStopLoss();
            double tp = OrderTakeProfit();
            if (ensure(OrderClose(order_number, close_lots, Ask, slippage, Red), "Unable to close order")) {
                if (stop_needs_modifying) {
                    selectOrder(symbol, open, stop, tp); // it has a new order number after closing half
                    ensure(OrderModify(order_number, OrderOpenPrice(), move_stop, OrderTakeProfit(), OrderExpiration(), Red), "Unable to modify SL"); 
                }
                SendNotification("First TP hit. Closed out " + DoubleToString(close_lots) + " lots. Set SL to " + DoubleToString(move_stop));
                ExpertRemove();
            }
        }
    }
}

bool require(bool predicate, string msg) {
    if (!predicate) {
        MessageBox("Exiting: " + msg + ": " + IntegerToString(GetLastError()));
        ExpertRemove();
    }
    return predicate;
}

bool ensure(bool predicate, string msg) {
    if (!predicate) {
        SendNotification("Requirement failed: " + msg + ": " + IntegerToString(GetLastError()));
    }
    return predicate;
}

string typeCode(double code) {
    if (code == 0.0) {
        return "Long";
    } else if (code == 1.0) {
        return "Short";
    } else {
        return "???";
    }
}

void OnDeinit(const int reason) {
    ObjectDelete(chart_id, "trigger");
    if (stop_needs_modifying) {
        ObjectDelete(chart_id, "move_stop");
    }
}

bool selectOrder(string symbol, double open, double sl, double tp) {
    bool found = false;
    Print("[multitp] selecting order, looking for symbol=", symbol, ", open=", open, ", sl=", sl, ", tp=", tp);

    for (int i = 0; i < OrdersTotal() && !found; i++) {

        bool selected = OrderSelect(i, SELECT_BY_POS, MODE_TRADES);

        Print("[multitp] selecting order, checking #", i, ": selected=", selected, ", symbol=", OrderSymbol(), 
            ", open=", OrderOpenPrice(), ", sl=", OrderStopLoss(), ", tp=", OrderTakeProfit());

        if (selected
            && OrderSymbol() == symbol
            && OrderOpenPrice() == open
            && OrderStopLoss() == sl
            && OrderTakeProfit() == tp) {

                order_number = OrderTicket();
                found = true;
        }
    }
    return found;
}
