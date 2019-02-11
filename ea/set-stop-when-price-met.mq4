#property link "chenandjem@loftinspace.com.au"
#property strict

input int    order_ticket_number;
input double trigger_price;
input double new_stop;

bool going_long = false;
long chart_id;

int OnInit() {

    require(OrderSelect(order_ticket_number, SELECT_BY_TICKET), "trouble selecting previously found order");

    Print("[set-stop-when-price-met] Current Order: #", order_ticket_number, " ", OrderSymbol(), 
        ", direction=", typeCode(OrderType()),
        ", open=", DoubleToString(OrderOpenPrice()),
        ", lots=", DoubleToString(OrderLots()),
        ", tp=", DoubleToString(OrderTakeProfit()),
        ", sl=", DoubleToString(OrderStopLoss())); 

    Print("[set-stop-when-price-met] Config: trigger_price=", DoubleToString(trigger_price),
        ", new_stop=", DoubleToString(new_stop));

    if (OrderType() == OP_BUY) {
        require(trigger_price > Bid, "Trigger " + DoubleToString(trigger_price) + " is less than the current Bid (" + DoubleToString(Bid) + "). It would execute immediately.");
        require(OrderTakeProfit() == 0 || trigger_price <= OrderTakeProfit(), "Trigger " + DoubleToString(trigger_price) + " is greater than the TP. It would never execute.");
        require(new_stop > OrderStopLoss(), "New stop loss " + DoubleToString(new_stop) + " is less than the original stop loss.");
        require(new_stop < trigger_price, "New stop loss " + DoubleToString(new_stop) + " is greater than the trigger.");
        going_long = true;
    } else if (OrderType() == OP_SELL) {
        require(trigger_price < Bid, "Trigger " + DoubleToString(trigger_price) + " is greater than the current Bid (" + DoubleToString(Bid) + "). It would execute immediately.");
        require(OrderTakeProfit() == 0 || trigger_price >= OrderTakeProfit(), "Trigger " + DoubleToString(trigger_price) + " is less than the TP. It would never execute.");
        require(new_stop < OrderStopLoss() || OrderStopLoss() == 0, "New stop loss " + DoubleToString(new_stop) + " is greater than the original stop loss.");
        require(new_stop > trigger_price, "New stop loss " + DoubleToString(new_stop) + " is less than the trigger.");
    } else {
        require(false, "Do not know how to proceed with order of type " + IntegerToString(OrderType()));
    }

    chart_id = ChartID();
    ObjectCreate("trigger_price", OBJ_HLINE, 0, Time[0], trigger_price, 0, 0);
    ObjectCreate("new_stop", OBJ_HLINE, 0, Time[0], new_stop, 0, 0);
    ObjectSetInteger(chart_id, "trigger_price", OBJPROP_COLOR, clrDodgerBlue);
    ObjectSetInteger(chart_id, "trigger_price", OBJPROP_STYLE, STYLE_DOT);
    ObjectSetInteger(chart_id, "new_stop", OBJPROP_COLOR, clrPaleVioletRed);
    ObjectSetInteger(chart_id, "new_stop", OBJPROP_STYLE, STYLE_DOT);

    return(INIT_SUCCEEDED);
}

void OnTick() {
    if (going_long && Bid > trigger_price) {
        ensure(OrderModify(order_ticket_number, OrderOpenPrice(), new_stop, OrderTakeProfit(), OrderExpiration(), Red), "Unable to modify SL");
        MessageBox("Trigger hit. Set SL to " + DoubleToString(new_stop));
        ExpertRemove();
    } else if (!going_long && Bid < trigger_price) {
        ensure(OrderModify(order_ticket_number, OrderOpenPrice(), new_stop, OrderTakeProfit(), OrderExpiration(), Red), "Unable to modify SL"); 
        MessageBox("Trigger hit. Set SL to " + DoubleToString(new_stop));
        ExpertRemove();
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
        Print("Requirement failed: " + msg + ": " + IntegerToString(GetLastError()));
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
    ObjectDelete(chart_id, "trigger_price");
    ObjectDelete(chart_id, "new_stop");
}