#property link "chenandjem@loftinspace.com.au"
#property strict

input double trigger_price;
input double new_stop;

const int state_initial = 0;
const int state_order_found = 1;

int order_ticket_number = 0;
int state = state_initial;

void OnTick() {
    if (state == state_initial) {
        int num_open_orders = selectOrder();
        ensure(num_open_orders == 1, "Expected exactly 1 open trade. Found " + IntegerToString(num_open_orders));
        Print("Order Type: " + DoubleToString(OrderType()));
        Print("OP_BUY=" + DoubleToString(OP_BUY) + ", OP_SELL=" + DoubleToString(OP_SELL));
        Print("Open Price: " + DoubleToString(OrderOpenPrice())); 
        Print("Lots: " + DoubleToString(OrderLots()));
        Print("Take Profit: " + DoubleToString(OrderTakeProfit()));
        Print("Stop Loss: " + DoubleToString(OrderStopLoss()));

        if (OrderType() == OP_BUY) {
            ensure(trigger_price > Ask, "Trigger price " + DoubleToString(trigger_price) + " is less than the current Ask. It would execute immediately.");
            ensure(OrderTakeProfit() == 0 || trigger_price <= OrderTakeProfit(), "Trigger price " + DoubleToString(trigger_price) + " is greater than the real TP. It would never execute.");
            ensure(new_stop >= OrderStopLoss(), "Break-even SL " + DoubleToString(new_stop) + " is less than the original stop loss.");
            ensure(new_stop < trigger_price, "Break-even SL " + DoubleToString(new_stop) + " is greater than the trigger price.");
        } else if (OrderType() == OP_SELL) {
            ensure(trigger_price < Bid, "Trigger price " + DoubleToString(trigger_price) + " is greater than the current Bid. It would execute immediately.");
            ensure(OrderTakeProfit() == 0 || trigger_price >= OrderTakeProfit(), "Trigger price " + DoubleToString(trigger_price) + " is less than the real TP. It would never execute.");
            ensure(new_stop <= OrderStopLoss(), "Break-even SL " + DoubleToString(new_stop) + " is greater than the original stop loss.");
            ensure(new_stop > trigger_price, "Break-even SL " + DoubleToString(new_stop) + " is less than the trigger price.");
        } else {
            die("Do not know how to proceed with order of type " + IntegerToString(OrderType()));
        }
        // string object_name = "interim_tp_line_" + IntegerToString(order_ticket_number);
        // warn(ObjectCreate(ChartID(), object_name, OBJ_HLINE, 0, 0, trigger_price), "Unable to draw interim TP line: " + IntegerToString(GetLastError()));
        // warn(ObjectSet(object_name, OBJPROP_COLOR, Green), "Unable to set interim TP line green");
        // warn(ObjectSet(object_name, OBJPROP_STYLE, STYLE_DASH), "Unable to set interim TP line dashed");
        state = state_order_found;
    } else if (state == state_order_found) {
        ensure(OrderSelect(order_ticket_number, SELECT_BY_TICKET), "Unable to select Order by ticket number");
        if (OrderType() == OP_BUY && Ask > trigger_price) {
            ensure(OrderModify(order_ticket_number, OrderOpenPrice(), new_stop, OrderTakeProfit(), OrderExpiration(), Red), "Unable to modify SL");
            MessageBox("Trigger hit. Set SL to " + DoubleToString(new_stop));
            ExpertRemove();
        } else if (OrderType() == OP_SELL && Bid < trigger_price) {
            ensure(OrderModify(order_ticket_number, OrderOpenPrice(), new_stop, OrderTakeProfit(), OrderExpiration(), Red), "Unable to modify SL");
            MessageBox("Trigger hit. Set SL to " + DoubleToString(new_stop));
            ExpertRemove();
        }
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
    if (num_open_orders == 1) {
         ensure(OrderSelect(order_ticket_number, SELECT_BY_TICKET), "trouble selecting previously found order");
    }
    return num_open_orders;
}

void warn(bool predicate, string msg) {
    if (!predicate) {
        Print("WARNING: " + msg);
    }
}

void ensure(bool predicate, string msg) {
    if (!predicate) {
        die(msg);
    }
}

void die(string msg) {
    MessageBox("Exiting: " + msg + ": " + IntegerToString(GetLastError()));
    ExpertRemove();
}
