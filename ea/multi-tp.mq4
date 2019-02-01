#property link "chenandjem@loftinspace.com.au"
#property strict

input double trigger;
input double close_lots;
input double move_stop;

int order_ticket_number = 0;
bool going_long = false;
bool stop_needs_modifying = true;

int OnInit() {
    int num_open_orders = selectOrder();
    require(num_open_orders == 1, "Expected exactly 1 open trade. Found " + IntegerToString(num_open_orders));

    Print("[multitp] Current Order: #", order_ticket_number, " ", OrderSymbol(), 
        ", direction=", typeCode(OrderType()),
        ", open=", DoubleToString(OrderOpenPrice()),
        ", lots=", DoubleToString(OrderLots()),
        ", tp=", DoubleToString(OrderTakeProfit()),
        ", sl=", DoubleToString(OrderStopLoss())); 

    Print("[multitp] Config: trigger=", DoubleToString(trigger),
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
        require(move_stop <= OrderStopLoss(), "Break-even SL " + DoubleToString(move_stop) + " is greater than the original stop loss.");
        require(move_stop > trigger, "Break-even SL " + DoubleToString(move_stop) + " is less than the first TP.");
        stop_needs_modifying = OrderStopLoss() != move_stop;
    } else {
        require(false, "Do not know how to proceed with order of type " + IntegerToString(OrderType()));
    }

    Print("Stop needs modifying? ", stop_needs_modifying);

    return(INIT_SUCCEEDED);
}

void OnTick() {
    if (going_long) {
        if (Bid > trigger) {
            int slippage = int(2.0 * (Ask - Bid) / _Point);
            if (ensure(OrderClose(order_ticket_number, close_lots, Bid, slippage, Red), "Unable to close order")) {
                if (stop_needs_modifying) {
                    int num_open_orders = selectOrder();
                    ensure(num_open_orders == 1, "Expected exactly 1 open trade. Found " + IntegerToString(num_open_orders));
                    ensure(OrderModify(order_ticket_number, OrderOpenPrice(), move_stop, OrderTakeProfit(), OrderExpiration(), Red), "Unable to modify SL"); 
                }
                MessageBox("First TP hit. Closed out " + DoubleToString(close_lots) + " lots. Set SL to " + DoubleToString(move_stop));
                ExpertRemove();
            }
        }
    } else {
        if (Ask < trigger) {
            int slippage = int(2.0 * (Ask - Bid) / _Point);
            if (ensure(OrderClose(order_ticket_number, close_lots, Ask, slippage, Red), "Unable to close order")) {
                if (stop_needs_modifying) {
                    int num_open_orders = selectOrder();
                    ensure(num_open_orders == 1, "Expected exactly 1 open trade. Found " + IntegerToString(num_open_orders));
                    ensure(OrderModify(order_ticket_number, OrderOpenPrice(), move_stop, OrderTakeProfit(), OrderExpiration(), Red), "Unable to modify SL"); 
                }
                MessageBox("First TP hit. Closed out " + DoubleToString(close_lots) + " lots. Set SL to " + DoubleToString(move_stop));
                ExpertRemove();
            }
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
    ensure(OrderSelect(order_ticket_number, SELECT_BY_TICKET), "trouble selecting previously found order");
    return num_open_orders;
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