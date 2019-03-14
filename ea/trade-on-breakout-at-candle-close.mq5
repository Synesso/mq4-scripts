//+------------------------------------------------------------------+
//|                                    chenandjem@loftinspace.com.au |
//|                                               loftinspace.com.au |
//+------------------------------------------------------------------+
#include <MT4Orders.mqh>

#define Bid SymbolInfoDouble(_Symbol, SYMBOL_BID)
#define Ask SymbolInfoDouble(_Symbol, SYMBOL_ASK)

#property copyright "chenandjem@loftinspace.com.au"
#property link      "loftinspace.com.au"
#property version   "1.00"
#property strict

input double    breakout_level;
input double    lots = 0.1;
input double    open_buffer = 0.00002;
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
    ensure(TerminalInfoInteger(TERMINAL_TRADE_ALLOWED), "Check if automated trading is allowed in the terminal settings!");
    ensure(MQLInfoInteger(MQL_TRADE_ALLOWED), StringFormat("Automated trading is forbidden in the program settings for %s", __FILE__));

    if (stop_loss < take_profit) {
        direction = LONG;
        trigger = breakout_level + buffer;
        Print("[tob@candle-close] Direction is Long. Trigger is ", trigger);
    } else if (stop_loss > take_profit) {
        direction = SHORT;
        trigger = breakout_level - buffer;
        Print("[tob@candle-close] Direction is Short. Trigger is ", trigger);
    } else {
        MessageBox("Exiting: Cannot determine if direction is short or long. Must match (tp > open > sl) or (tp < open < sl)");
        ExpertRemove();
    }

    chart_id = ChartID();
    
    Print(StringFormat("[tob@candle-close] Config: breakout_level=%d, lots=%d, open_buffer=%d, sl=%d, tp=%d, buffer=%d", 
        breakout_level, lots, open_buffer, stop_loss, take_profit, buffer));

    ObjectCreate("breakout_level", OBJ_HLINE, 0, iTime(_Symbol, _Period, 0), breakout_level, 0, 0);
    ObjectCreate("trigger", OBJ_HLINE, 0,  iTime(_Symbol, _Period, 0), trigger, 0, 0);
    ObjectCreate("stop_loss", OBJ_HLINE, 0,  iTime(_Symbol, _Period, 0), stop_loss, 0, 0);
    ObjectCreate("take_profit", OBJ_HLINE, 0,  iTime(_Symbol, _Period, 0), take_profit, 0, 0);

    ObjectSetInteger(chart_id, "stop_loss", OBJPROP_COLOR, clrPaleVioletRed);
    ObjectSetInteger(chart_id, "stop_loss", OBJPROP_STYLE, STYLE_DOT);
    ObjectSetInteger(chart_id, "take_profit", OBJPROP_COLOR, clrSeaGreen);
    ObjectSetInteger(chart_id, "take_profit", OBJPROP_STYLE, STYLE_DOT);
    ObjectSetInteger(chart_id, "breakout_level", OBJPROP_COLOR, clrForestGreen);
    ObjectSetInteger(chart_id, "trigger", OBJPROP_COLOR, clrForestGreen);
    ObjectSetInteger(chart_id, "trigger", OBJPROP_STYLE, STYLE_DASH);

    return(INIT_SUCCEEDED);
}

void OnTick() {
    if (isNewCandle()) {
        if (direction == LONG && iClose(NULL, PERIOD_CURRENT, 1) > trigger) {
            int slippage = int(2.0 * (Ask - Bid) / _Point);
            Print(StringFormat("[tob@candle-close] Issuing OrderSend(%s, OP_BUYLIMIT, lots=%f, open=%f, slippage=%d, stop_loss=%f, take_profit=%f)",
                Symbol(), lots, Ask - open_buffer, slippage, stop_loss, take_profit
            ));
            int ticket = OrderSend(Symbol(), OP_BUYLIMIT, lots, Ask - open_buffer, slippage, stop_loss, take_profit, "trade_on_breakout_EA");
            if (ticket < 0) {
                SendNotification("Unable to create buy limit order: " + IntegerToString(GetLastError()));
            }
            ExpertRemove();
        } else if (direction == SHORT && iClose(NULL, PERIOD_CURRENT, 1) < trigger) {
            int slippage = int(2.0 * (Ask - Bid) / _Point);
            Print(StringFormat("[tob@candle-close] Issuing OrderSend(%s, OP_SELLLIMIT, lots=%f, open=%f, slippage=%d, stop_loss=%f, take_profit=%f)",
                Symbol(), lots, Bid + open_buffer, slippage, stop_loss, take_profit
            ));
            int ticket = OrderSend(Symbol(), OP_SELLLIMIT, lots, Bid + open_buffer, slippage, stop_loss, take_profit, "trade_on_breakout_EA");
            if (ticket < 0) {
                SendNotification("Unable to create sell limit order: " + IntegerToString(GetLastError()));
            }
            ExpertRemove();
        }
    }
}

bool isNewCandle() {
    bool isNew = bars_on_chart != Bars(_Symbol,_Period);
    bars_on_chart = Bars(_Symbol,_Period);
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
            Print("[tob@candle-close] Selected ticket " + DoubleToString(order_ticket_number));
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
    // ObjectDelete(chart_id, "open");
    ObjectDelete(chart_id, "stop_loss");
    ObjectDelete(chart_id, "take_profit");
    ObjectDelete(chart_id, "breakout_level");
    ObjectDelete(chart_id, "trigger");
}
