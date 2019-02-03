#property link "chenandjem@loftinspace.com.au"
#property strict

input double level_a = 1.0517;
input double level_b = 1.0515;
input double level_c = 1.0510;
input double level_d = 1.0500;

int count_zone_1_from_below = 0;
int count_zone_1_from_above = 0;
int count_zone_3_from_below = 0;
int count_zone_3_from_above = 0;

double zone_boundaries[4];

int num_bars_when_last_notified = 0;


/*
Send alert when price moves above b from below, and the previous candle did not enter zone 1 - $Symbol $nth attempt at approaching resistance
Send alert when price moves below c from above, and the previous candle did not enter zone 3 - $Symbol $nth attempt at approaching support
Send alert when price moves from above, and the previous candle did not enter zone 1         - $Symbol coming down to resistance after topside break $nth attempt
Send alert when price moves from below, and the previous candle did not enter zone 3         - $Symbol coming up to support after downside break $nth attempt
*/

// TODO - draw lines at input levels

int OnInit() {
    // configure zones boundaries from input levels.
    zone_boundaries[0] = level_a;
    zone_boundaries[1] = level_b;
    zone_boundaries[2] = level_c;
    zone_boundaries[3] = level_d;
    ArraySort(zone_boundaries);

    Print("[breakout] boundaries={", zone_boundaries[0], ", ", zone_boundaries[1], ", ", 
        zone_boundaries[2], ", ", zone_boundaries[3], "}");

    return(INIT_SUCCEEDED);
}

void OnTick() {
    if (notifiedThisCandle()) { return; }

    int zone = zoneForPrice(Ask);

    if (zone == 1 && !priorCandleWasInZone(1)) {
        if (priorCandleWasInZone(0)) {
            count_zone_1_from_above += 1;
            notify(StringFormat("%s coming down to resistance after topside break, %s attempt.", Symbol(), ordinal(count_zone_1_from_above)));
        } else {
            count_zone_1_from_below += 1;
            notify(StringFormat("%s %s attempt at approaching resistance.", Symbol(), ordinal(count_zone_1_from_below)));
        }
    }

    if (zone == 3 && !priorCandleWasInZone(3)) {
        if (priorCandleWasInZone(4)) {
            count_zone_3_from_below += 1;
            notify(StringFormat("%s coming up to support after downside break, %s attempt.", Symbol(), ordinal(count_zone_3_from_below)));
        } else {
            count_zone_3_from_above += 1;
            notify(StringFormat("%s %s attempt at approaching support.", Symbol(), ordinal(count_zone_3_from_above)));
        }
    }
}

void notify(string msg) {
    Print("[breakout] Notifying: ", msg);
    SendNotification(msg);
    num_bars_when_last_notified = Bars;
}

string ordinal(int i) {
    if (i % 10 == 1) {
        return StringFormat("%dst", i);
    } else if (i % 10 == 2) {
        return StringFormat("%dnd", i);
    } else if (i % 10 == 3) {
        return StringFormat("%drd", i);
    } else {
        return StringFormat("%dth", i);
    }
}

bool notifiedThisCandle() {
    return num_bars_when_last_notified == Bars;
}

bool priorCandleWasInZone(int zone) {
    return zoneForPrice(Low[1]) <= zone && zone <= zoneForPrice(High[1]);
}

int zoneForPrice(double price, int z = 0) {
    if (z == 4 || price < zone_boundaries[z] ) {
        return z;
    } else {
        return zoneForPrice(price, z + 1);
    }
}
