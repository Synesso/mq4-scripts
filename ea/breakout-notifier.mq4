#property link "chenandjem@loftinspace.com.au"
#property strict

input double level_1 = 1.0517;
input double level_2 = 1.0515;
input double level_3 = 1.0510;
input double level_4 = 1.0500;

int count_zone_A_from_below = 0;
int count_zone_A_from_above = 0;
int count_zone_C_from_below = 0;
int count_zone_C_from_above = 0;

double zone_boundaries[4];

const int ZONE_A = 0;
const int ZONE_B = 1;
const int ZONE_C = 2;
const int ZONE_D = 3;
const int ZONE_E = 4;

int zone;

/*
Notify when price goes into zones B & D
    This means non of the prior candle has been in that zone, but the price has just ticked into the zone.
Notify when candle closes in zone A or zone E.

Questions:
1. should it check back a few bars on init?
*/

int OnInit() {
    // configure zones boundaries from input levels.
    zone_boundaries[0] = level_1;
    zone_boundaries[1] = level_2;
    zone_boundaries[2] = level_3;
    zone_boundaries[3] = level_4;
    ArraySort(zone_boundaries);

    // determine the current zone
    zone = zoneForPrice(Close[1]);

    Print("[breakout] boundaries={", zone_boundaries[0], ", ", zone_boundaries[1], ", ", 
        zone_boundaries[2], ", ", zone_boundaries[3], "}, zone=", zone);

    return(INIT_SUCCEEDED);
}

void OnTick() {

}

int zoneForPrice(double price, int z = 0) {
    if (z == ZONE_E || price < zone_boundaries[z] ) {
        return z;
    } else {
        return zoneForPrice(price, z + 1);
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