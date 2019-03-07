#define MAGIC 83879482

input datetime execute_server_time;
input double size;
input double buy_stop;
input double tp;
input double sl;

int OnInit() {
    EventSetTimer(60);
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
    EventKillTimer();
}

void OnTick() {}

void OnTimer() {
    if (TimeCurrent() >= execute_server_time) {
        MqlTradeResult result = {0};
        MqlTradeRequest request = {0};
        request.action = TRADE_ACTION_PENDING;
        request.symbol = _Symbol;
        request.volume = size;
        request.sl = sl;
        request.tp = tp;
        request.type = ORDER_TYPE_BUY_STOP;
        request.price = buy_stop;
        request.magic = MAGIC;
        request.type_filling = ORDER_FILLING_IOC;

        if (!OrderSend(request, result)) {
            PrintFormat("[place_order] OrderSend %d error %d", request.price, GetLastError());
        }
        ExpertRemove();
    }
}
