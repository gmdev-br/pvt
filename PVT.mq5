//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "© GM, 2022, 2023"
#property description "PVT - Pivot Point MTF"

//--- indicator buffers
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2

//--- plot UpFractals
//#property indicator_label1  "Up Fractals"
//#property indicator_type1   DRAW_ARROW
//#property indicator_color1  clrDodgerBlue
//#property indicator_style1  STYLE_SOLID
//#property indicator_width1  1

//--- plot DnFractals
//#property indicator_label2  "Down Fractals"
//#property indicator_type2   DRAW_ARROW
//#property indicator_color2  clrTomato
//#property indicator_style2  STYLE_SOLID
//#property indicator_width2  1

//--- input parameters

input string   inputAtivo = "";
input string                     Id                              = "+pvt";                         // IDENTIFICADOR
input datetime                   DefaultInitialDate              = "2023.7.10 09:00:00";          // Data inicial padrão
input datetime                   DefaultFinalDate                = -1;                             // Data final padrão
input bool                       EnableEvents                    = false;                          // Ativa os eventos de teclado
input color                      TimeFromColor                   = clrLime;                        // ESQUERDO: cor
input int                        TimeFromWidth                   = 1;                              // ESQUERDO: largura
input ENUM_LINE_STYLE            TimeFromStyle                   = STYLE_DASH;                     // ESQUERDO: estilo
input color                      TimeToColor                     = clrRed;                         // DIREITO: cor
input int                        TimeToWidth                     = 1;                              // DIREITO: largura
input ENUM_LINE_STYLE            TimeToStyle                     = STYLE_DASH;                     // DIREITO: estilo
//input bool                       AutoLimitLines                  = true;                           // Automatic limit left and right lines
input bool                       FitToLines                      = true;                           // Automatic fit histogram inside lines
input bool                       KeepRightLineUpdated            = true;                           // Automatic update of the rightmost line
input int                        ShiftCandles                    = 6;                              // Distance in candles to adjust on automatic

input bool     enable1m = true;
input bool     enable5m = false;
input bool     enable15m = false;
input bool     enable30m = false;
input bool     enable60m = false;
input bool     enable120m = false;
input bool     enable240m = false;
input bool     enableD = false;
input bool     enableW = false;
input bool     enableMN = false;
input bool     showTF = false;
input bool     showSymbols = true;
input int      InpLeftSide = 3;          // Number of bars from the left of fractal
input int      InpRightSide = 3;         // Number of bars from the right of fractal
input int      WaitMilliseconds  = 1000;  // Timer (milliseconds) for recalculation
input color    colorUp = clrRed;
input color    colorDown = clrLime;
//input bool     shortMode = true;
input int      shortStart = 8;
input int      shortEnd = 10;
input int      line_width = 2;
input int      font_size = 14;
//--- indicator buffers
//double         UpFractalsBuffer[];
//double         DnFractalsBuffer[];

//--- global variables
int            minRequiredBars;
int            leftSide, rightSide;
int            maxSide;

datetime       arrayTime[];
double         arrayOpen[], arrayHigh[], arrayLow[], arrayClose[];
double         pvtHigh[], pvtLow[];
string         ativo;

datetime       data_inicial;         // Data inicial para mostrar as linhas
datetime       data_final;         // Data final para mostrar as linhas
datetime       timeFrom;
datetime       timeTo;
datetime       minimumDate;
datetime       maximumDate;

int            barFrom, barTo;
int            indiceFinal, indiceInicial;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {

   ativo = inputAtivo;
   StringToUpper(ativo);
   if (ativo == "")
      ativo = _Symbol;

   if ( InpLeftSide < 1 ) {
      leftSide = 2;
      printf("The \"Number of bars from the left of fractal\" parameter is specified incorrectly: %d. the: %d. value will be used",
             InpLeftSide, leftSide);
   } else {
      leftSide = InpLeftSide;
   }
   if ( InpRightSide < 1 ) {
      rightSide = 2;
      printf("The \"Number of bars from the right of fractal\" parameter is specified incorrectly: %d. the: %d. value will be used",
             InpRightSide, rightSide);
   } else {
      rightSide = InpRightSide;
   }

   minRequiredBars = leftSide + rightSide + 1;
   maxSide = int(MathMax(leftSide, rightSide));

   _timeFromLine = Id + "-from";
   _timeToLine = Id + "-to";

   if (inputAtivo != "")
      ativo = inputAtivo;

   data_inicial = DefaultInitialDate;
   if (KeepRightLineUpdated && ((DefaultFinalDate == -1) || (DefaultFinalDate > iTime(ativo, PERIOD_CURRENT, 0))))
      data_final = iTime(ativo, PERIOD_CURRENT, 0) + PeriodSeconds(PERIOD_CURRENT) * ShiftCandles;

   _timeToColor = TimeToColor;
   _timeFromColor = TimeFromColor;
   _timeToWidth = TimeToWidth;
   _timeFromWidth = TimeFromWidth;
   _lastOK = false;

   SetIndexBuffer(0, pvtHigh, INDICATOR_DATA);
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, clrRed);
   PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(0, PLOT_LINE_WIDTH, 1);
   PlotIndexSetInteger(0, PLOT_LINE_STYLE, STYLE_SOLID);
   PlotIndexSetString(0, PLOT_LABEL, "PVT High");

   SetIndexBuffer(1, pvtLow, INDICATOR_DATA);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, clrLime);
   PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(1, PLOT_LINE_WIDTH, 1);
   PlotIndexSetInteger(1, PLOT_LINE_STYLE, STYLE_SOLID);
   PlotIndexSetString(1, PLOT_LABEL, "PVT Low");

//   SetIndexBuffer(0, UpFractalsBuffer, INDICATOR_DATA);
//   SetIndexBuffer(1, DnFractalsBuffer, INDICATOR_DATA);
//
//   PlotIndexSetInteger(0, PLOT_ARROW, 217);
//   PlotIndexSetInteger(1, PLOT_ARROW, 218);
//
//   PlotIndexSetInteger(0, PLOT_ARROW_SHIFT, -10);
//   PlotIndexSetInteger(1, PLOT_ARROW_SHIFT, 10);

//for ( int i = 0; i < 2; i++ ) {
//   PlotIndexSetInteger(i, PLOT_DRAW_BEGIN, minRequiredBars);
//   PlotIndexSetDouble(i, PLOT_EMPTY_VALUE, 0.0);
//}

   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   IndicatorSetString(INDICATOR_SHORTNAME, "X-bars Fractals (" + (string)leftSide + ", " + (string)rightSide + ")");

   _updateTimer = new MillisecondTimer(WaitMilliseconds, false);
   EventSetMillisecondTimer(WaitMilliseconds);

   ChartRedraw();

   return(0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {

   delete(_updateTimer);

   ObjectsDeleteAll(0, "line_up");
   ObjectsDeleteAll(0, "line_down");
   ObjectsDeleteAll(0, "text_up");
   ObjectsDeleteAll(0, "text_down");

   if(UninitializeReason() == REASON_REMOVE) {
      ObjectDelete(0, _timeFromLine);
      ObjectDelete(0, _timeToLine);
   }
//if(reason == REASON_REMOVE) {
//   ObjectsDeleteAll(0, "line_up");
//   ObjectsDeleteAll(0, "line_down");
//}

   ChartRedraw();

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void verifyDates() {

   minimumDate = iTime(ativo, PERIOD_CURRENT, iBars(ativo, PERIOD_CURRENT) - 2);
   maximumDate = iTime(ativo, PERIOD_CURRENT, 0);

   timeFrom = GetObjectTime1(_timeFromLine);
   timeTo = GetObjectTime1(_timeToLine);

   data_inicial = DefaultInitialDate;
   data_final = DefaultFinalDate;
   if (KeepRightLineUpdated && ((DefaultFinalDate == -1) || (DefaultFinalDate > iTime(ativo, PERIOD_CURRENT, 0))))
      data_final = iTime(ativo, PERIOD_CURRENT, 0) + PeriodSeconds(PERIOD_CURRENT) * ShiftCandles;

   if ((timeFrom == 0) || (timeTo == 0)) {
      timeFrom = data_inicial;
      timeTo = data_final;
      DrawVLine(_timeFromLine, timeFrom, _timeFromColor, _timeFromWidth, TimeFromStyle, true, false, true, 1000);
      DrawVLine(_timeToLine, timeTo, _timeToColor, _timeToWidth, TimeToStyle, true, false, true, 1000);
   }

   if (ObjectGetInteger(0, _timeFromLine, OBJPROP_SELECTED) == false) {
      timeFrom = data_inicial;
   }

   if (ObjectGetInteger(0, _timeToLine, OBJPROP_SELECTED) == false) {
      timeTo = data_final;
   }

   if ((timeFrom < minimumDate) || (timeFrom > maximumDate))
      timeFrom = minimumDate;

   if ((timeTo >= maximumDate) || (timeTo < minimumDate))
      timeTo = maximumDate + PeriodSeconds(PERIOD_CURRENT) * ShiftCandles;

   ObjectSetInteger(0, _timeFromLine, OBJPROP_TIME, 0, timeFrom);
   ObjectSetInteger(0, _timeToLine, OBJPROP_TIME, 0, timeTo);
}


//+------------------------------------------------------------------+
//| Check if is Up Fractal function                                  |
//+------------------------------------------------------------------+
bool isUpFractal(int bar, int max, const double &High[]) {

   for ( int i = 1; i <= max; i++ ) {
      if ( i <= leftSide && High[bar] < High[bar - i] ) {
         return(false);
      }
      if ( i <= rightSide && High[bar] <= High[bar + i] ) {
         return(false);
      }
   }

   return(true);
}

//+------------------------------------------------------------------+
//| Check if is Down Fractal function                                |
//+------------------------------------------------------------------+
bool isDnFractal(int bar, int max, const double &Low[]) {

   for ( int i = 1; i <= max; i++ ) {
      if ( i <= leftSide && Low[bar] > Low[bar - i] ) {
         return(false);
      }
      if ( i <= rightSide && Low[bar] >= Low[bar + i] ) {
         return(false);
      }
   }

   return(true);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double &price[]) {
   return (1);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam) {

//if(id == CHARTEVENT_CHART_CHANGE) {
//   _lastOK = false;
//   CheckTimer();
//}

   if(id == CHARTEVENT_OBJECT_DRAG) {
      if((sparam == _timeFromLine) || (sparam == _timeToLine)) {
         _lastOK = false;
         ChartRedraw();
         CheckTimer();
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Update(ENUM_TIMEFRAMES p_tf, int str) {

   verifyDates();

   barFrom = iBarShift(NULL, p_tf, timeFrom);
   barTo = iBarShift(NULL, p_tf, timeTo);

   ObjectSetInteger(0, _timeFromLine, OBJPROP_TIME, 0, timeFrom);
   ObjectSetInteger(0, _timeToLine, OBJPROP_TIME, 0, timeTo);

   if(timeFrom > timeTo)
      Swap(timeFrom, timeTo);

   int primeiroCandle = WindowFirstVisibleBar();
   int ultimoCandle = WindowFirstVisibleBar() - WindowBarsPerChart();
   int lineFromPosition = 0, lineToPosition = 0;
   if (FitToLines == true) {
      lineFromPosition = iBarShift(ativo, PERIOD_CURRENT, GetObjectTime1(_timeFromLine), 0);
      lineToPosition = iBarShift(ativo, PERIOD_CURRENT, GetObjectTime1(_timeToLine), 0);
   }

   int startBar, lastBar;
   string tf_name = GetTimeFrame(p_tf);
   string line_up = "line_up_" + tf_name;
   string line_down = "line_down_" + tf_name;
   string text_up = "text_up_" + tf_name;
   string text_down = "text_down_" + tf_name;

   ObjectDelete(0, line_up);
   ObjectDelete(0, line_down);

   int totalRates = SeriesInfoInteger(ativo, p_tf, SERIES_BARS_COUNT);
   if (totalRates < minRequiredBars) {
      //Print("Not enough data to calculate");
      return(0);
   }

   startBar = leftSide;
   lastBar = totalRates - rightSide;

   startBar = barFrom + rightSide;
   lastBar = totalRates - barTo - rightSide;

   int tempVar = CopyLow(ativo, p_tf, 0, totalRates, arrayLow);
   tempVar = CopyClose(ativo, p_tf, 0, totalRates, arrayClose);
   tempVar = CopyHigh(ativo, p_tf, 0, totalRates, arrayHigh);
   tempVar = CopyOpen(ativo, p_tf, 0, totalRates, arrayOpen);

   ArrayReverse(arrayLow);
   ArrayReverse(arrayClose);
   ArrayReverse(arrayHigh);
   ArrayReverse(arrayOpen);

   ArraySetAsSeries(arrayOpen, true);
   ArraySetAsSeries(arrayLow, true);
   ArraySetAsSeries(arrayClose, true);
   ArraySetAsSeries(arrayHigh, true);
   
//   ArraySetAsSeries(pvtHigh, true);
//   ArraySetAsSeries(pvtLow, true);
//   
//   ArrayResize(pvtHigh, totalRates);
//   ArrayResize(pvtLow, totalRates);
//
//   ArrayInitialize(pvtHigh, 0);
//   ArrayInitialize(pvtLow, 0);

   double pvtUp, pvtDn;
   for ( int bar = startBar; bar < lastBar; bar++ ) {
      if ( isUpFractal(bar, maxSide, arrayClose) ) {
         pvtUp = arrayClose[bar];
         //UpFractalsBuffer[bar] = arrayClose[bar];
         ObjectCreate(0, line_up, OBJ_TREND, 0, iTime(ativo, PERIOD_CURRENT, 0), 0);
         ObjectSetInteger(0, line_up, OBJPROP_TIME, 0, iTime(ativo, PERIOD_CURRENT, totalRates - bar - 1));
         ObjectSetInteger(0, line_up, OBJPROP_TIME, 0, iTime(ativo, PERIOD_CURRENT, shortStart == 0 ? barTo - 1 : 0) + PeriodSeconds(PERIOD_CURRENT) * shortStart);
         ObjectSetInteger(0, line_up, OBJPROP_TIME, 1, iTime(ativo, PERIOD_CURRENT, shortEnd == 0 ? barTo - 1 : 0) + PeriodSeconds(PERIOD_CURRENT) * shortEnd);
         ObjectSetInteger(0, line_up, OBJPROP_WIDTH, line_width);
         ObjectSetDouble(0, line_up, OBJPROP_PRICE, 0, pvtUp);
         ObjectSetDouble(0, line_up, OBJPROP_PRICE, 1, pvtUp);
         ObjectSetInteger(0, line_up, OBJPROP_COLOR, colorUp);
         if (showTF) ObjectSetString(0, line_up, OBJPROP_TEXT, tf_name);

         ObjectCreate(0, text_up, OBJ_TEXT, 0, iTime(ativo, PERIOD_CURRENT, shortStart == 0 ? barTo - 1 : 0) + PeriodSeconds(PERIOD_CURRENT) * shortStart, 0);
         ObjectSetDouble(0, text_up, OBJPROP_PRICE, 0, pvtUp);
         ObjectSetInteger(0, text_up, OBJPROP_COLOR, colorUp);
         ObjectSetInteger(0, text_up, OBJPROP_ANCHOR, ANCHOR_LOWER);
         ObjectSetInteger(0, text_up, OBJPROP_FONTSIZE, font_size);

         //pvtHigh[bar] = pvtUp;

         if (showSymbols) {
            string temp;
            for(int i = 0; i < str; i++) {
               temp = temp + "+";
            }
            //ObjectSetString(0, line_up, OBJPROP_TEXT, temp);
            ObjectSetString(0, text_up, OBJPROP_TEXT, temp);
         }

         //} else {
         //   UpFractalsBuffer[bar] = 0.0;
      } else {
         //pvtHigh[bar] = pvtUp;
      }

      if ( isDnFractal(bar, maxSide, arrayClose) ) {
         pvtDn = arrayClose[bar];
         //DnFractalsBuffer[bar] = arrayClose[bar];
         ObjectCreate(0, line_down, OBJ_TREND, 0, iTime(ativo, PERIOD_CURRENT, 0), 0);
         ObjectSetInteger(0, line_down, OBJPROP_TIME, 0, iTime(ativo, PERIOD_CURRENT, totalRates - bar - 1));
         ObjectSetInteger(0, line_down, OBJPROP_TIME, 0, iTime(ativo, PERIOD_CURRENT, shortStart == 0 ? barTo - 1 : 0) + PeriodSeconds(PERIOD_CURRENT) * shortStart);
         ObjectSetInteger(0, line_down, OBJPROP_TIME, 1, iTime(ativo, PERIOD_CURRENT, shortEnd == 0 ? barTo - 1 : 0) + PeriodSeconds(PERIOD_CURRENT) * shortEnd);
         ObjectSetInteger(0, line_down, OBJPROP_WIDTH, line_width);
         ObjectSetDouble(0, line_down, OBJPROP_PRICE, 0, pvtDn);
         ObjectSetDouble(0, line_down, OBJPROP_PRICE, 1, pvtDn);
         ObjectSetInteger(0, line_down, OBJPROP_COLOR, colorDown);
         if (showTF) ObjectSetString(0, line_down, OBJPROP_TEXT, tf_name);

         //} else {
         //   DnFractalsBuffer[bar] = 0.0;
         ObjectCreate(0, text_down, OBJ_TEXT, 0, iTime(ativo, PERIOD_CURRENT, shortStart == 0 ? barTo - 1 : 0) + PeriodSeconds(PERIOD_CURRENT) * shortStart, 0);
         ObjectSetDouble(0, text_down, OBJPROP_PRICE, 0, pvtDn);
         ObjectSetInteger(0, text_down, OBJPROP_COLOR, colorDown);
         ObjectSetInteger(0, text_down, OBJPROP_ANCHOR, ANCHOR_UPPER);
         ObjectSetInteger(0, text_down, OBJPROP_FONTSIZE, font_size);

         //pvtLow[bar] = pvtDn;

         if (showSymbols) {
            string temp;
            for(int i = 0; i < str; i++) {
               temp = temp + "+";
            }
            //ObjectSetString(0, line_down, OBJPROP_TEXT, temp);
            ObjectSetString(0, text_down, OBJPROP_TEXT, temp);
         }
      } else {
         //pvtLow[bar] = pvtDn;
      }
   }

   ChartRedraw();

   _lastOK = false;
//Print("PVT calculated: " + GetTimeFrame(p_tf));

   return true;
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class MillisecondTimer {

 private:
   int               _milliseconds;
 private:
   uint              _lastTick;

 public:
   void              MillisecondTimer(const int milliseconds, const bool reset = true) {
      _milliseconds = milliseconds;

      if(reset)
         Reset();
      else
         _lastTick = 0;
   }

 public:
   bool              Check() {
      uint now = getCurrentTick();
      bool stop = now >= _lastTick + _milliseconds;

      if(stop)
         _lastTick = now;

      return(stop);
   }

 public:
   void              Reset() {
      _lastTick = getCurrentTick();
   }

 private:
   uint              getCurrentTick() const {
      return(GetTickCount());
   }

};

bool _lastOK = false;
MillisecondTimer *_updateTimer;

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
   CheckTimer();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckTimer() {
   EventKillTimer();

   if(_updateTimer.Check() || !_lastOK) {
      if (enable1m) _lastOK = Update(PERIOD_M1, 1);
      if (enable5m) _lastOK = Update(PERIOD_M5, 2);
      if (enable15m) _lastOK = Update(PERIOD_M15, 3);
      if (enable30m) _lastOK = Update(PERIOD_M30, 4);
      if (enable60m) _lastOK = Update(PERIOD_H1, 5);
      if (enable120m) _lastOK = Update(PERIOD_H2, 6);
      if (enable240m) _lastOK = Update(PERIOD_H4, 7);
      if (enableD) _lastOK = Update(PERIOD_D1, 8);
      if (enableW) _lastOK = Update(PERIOD_W1, 9);
      if (enableMN) _lastOK = Update(PERIOD_MN1, 10);
      //Print("PVT calculated");
      EventSetMillisecondTimer(WaitMilliseconds);

      _updateTimer.Reset();
   } else {
      EventSetTimer(1);
   }
}

//+---------------------------------------------------------------------+
//| GetTimeFrame function - returns the textual timeframe               |
//+---------------------------------------------------------------------+
string GetTimeFrame(int lPeriod) {
   switch(lPeriod) {
   case PERIOD_M1:
      return("M1");
   case PERIOD_M2:
      return("M2");
   case PERIOD_M3:
      return("M3");
   case PERIOD_M4:
      return("M4");
   case PERIOD_M5:
      return("M5");
   case PERIOD_M6:
      return("M6");
   case PERIOD_M10:
      return("M10");
   case PERIOD_M12:
      return("M12");
   case PERIOD_M15:
      return("M15");
   case PERIOD_M20:
      return("M20");
   case PERIOD_M30:
      return("M30");
   case PERIOD_H1:
      return("H1");
   case PERIOD_H2:
      return("H2");
   case PERIOD_H3:
      return("H3");
   case PERIOD_H4:
      return("H4");
   case PERIOD_H6:
      return("H6");
   case PERIOD_H8:
      return("H8");
   case PERIOD_H12:
      return("H12");
   case PERIOD_D1:
      return("D1");
   case PERIOD_W1:
      return("W1");
   case PERIOD_MN1:
      return("MN1");
   }
   return IntegerToString(lPeriod);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime GetObjectTime1(const string name) {
   datetime time;

   if(!ObjectGetInteger(0, name, OBJPROP_TIME, 0, time))
      return(0);

   return(time);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MathRound(const double value, const double error) {
   return(error == 0 ? value : MathRound(value / error) * error);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
void Swap(T &value1, T &value2) {
   T tmp = value1;
   value1 = value2;
   value2 = tmp;

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime miTime(string symbol, ENUM_TIMEFRAMES timeframe, int index) {
   if(index < 0)
      return(-1);

   datetime arr[];

   if(CopyTime(symbol, timeframe, index, 1, arr) <= 0)
      return(-1);

   return(arr[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int WindowBarsPerChart() {
   return((int)ChartGetInteger(0, CHART_WIDTH_IN_BARS));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int WindowFirstVisibleBar() {
   return((int)ChartGetInteger(0, CHART_FIRST_VISIBLE_BAR));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawVLine(const string name, const datetime time1, const color lineColor, const int width, const int style, const bool back = true, const bool hidden = true, const bool selectable = true, const int zorder = 0) {
   ObjectDelete(0, name);

   ObjectCreate(0, name, OBJ_VLINE, 0, time1, 0);
   ObjectSetInteger(0, name, OBJPROP_COLOR, lineColor);
   ObjectSetInteger(0, name, OBJPROP_BACK, back);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, hidden);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, selectable);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, zorder);
}

string _timeFromLine;
string _timeToLine;

color _timeToColor;
color _timeFromColor;
int _timeToWidth;
int _timeFromWidth;
//+------------------------------------------------------------------+
