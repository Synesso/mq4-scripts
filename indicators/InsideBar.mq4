//+------------------------------------------------------------------+
//|                                                    InsideBar.mq4 |
//|                                                                  |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright ""
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_chart_window

#property indicator_buffers 1
#property indicator_color1 clrGreen
#property indicator_width1 1

double child[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0, child);
   SetIndexStyle(0, DRAW_ARROW);
   SetIndexArrow(0, 234);
   
   /* 
   // WebRequest only works in EA and scripts, but not indicators    
   string payload="payload={\"channel\":\"#general\",\"text\":\"test message mate\"}";
   char data[];
   char result[];
   int res;
   string headers;
  // ArrayResize(data, StringToCharArray(payload, data, 0,WHOLE_ARRAY,CP_UTF8)-1);
   StringToCharArray(payload, data, 0,WHOLE_ARRAY,CP_UTF8);  
   res=WebRequest("POST", "https://hooks.slack.com/services/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", NULL, NULL,
     1000, data, ArraySize(data), result, headers);
   Print(res);
   */
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---

  int limit;
  if (prev_calculated == 0) {
    limit = rates_total - 1;
  } else {
    limit = rates_total - prev_calculated + 1;
  }

  for (int i=1; i < limit; i++) {
    if (i+1 < limit && High[i+1]>High[i] && Low[i+1]<Low[i]) {
      child[i]=High[i] + 0.005;
      if (i==1) {
        Alert("Inside Bar formed on " + Symbol());
      }
    }
  }
//   for(i=1; i<=InpAtrPeriod; i++)
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
