//+------------------------------------------------------------------+
//|                                      KG BOS CHOCH OrderBlock.mq4 |
//|                                       Copyright 2026, Mang Koyod |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Mang Koyod"
#property link      "https://www.mql5.com"
#property version   "10.00"
#property description "SMC BOS/CHoCH, Order Block & Fibo (XAUUSD). Object names are read by KG Trading Anti Fomo EA."
#property strict
#property indicator_chart_window

// --- Custom Enum untuk Timeframe (M1 & D1 ditambahkan di akhir agar .set lama tetap valid) ---
enum ENUM_CUSTOM_TF {
   TF_M5  = PERIOD_M5,
   TF_M15 = PERIOD_M15,
   TF_M30 = PERIOD_M30,
   TF_H1  = PERIOD_H1,
   TF_H4  = PERIOD_H4,
   TF_M1  = PERIOD_M1,
   TF_D1  = PERIOD_D1
};

// --- Custom Enum untuk Tipe Breakout ---
enum ENUM_BREAK_MODE {
   BREAK_BODY, // Body Melewati Batas
   BREAK_WICK  // Ekor Melewati Batas
};

// --- Custom Enum untuk Perhitungan Swing ---
enum ENUM_SWING_MODE {
   SWING_ZIGZAG,   // Menggunakan ZigZag (Repaint di Leg Terakhir)
   SWING_MA_CROSS, // Menggunakan Crossing MA
   SWING_FRACTAL   // Fractal Terkonfirmasi (Anti Repaint, Rekomendasi)
};

enum ENUM_OB_MODE {
   OB_4_CANDLE,  // Teori 4-Candle (Formasi Mang Koyod)
   OB_STANDARD   // Teori SMC Klasik (Last Opposite Candle)
};

enum ENUM_OB_PICK {
   OB_DECISIONAL, // Decisional: Candle Lawan Terdekat ke Breakout
   OB_EXTREME     // Extreme: Candle Lawan di Ujung Swing
};

// --- Input Parameter ---
input string            SMC_Settings       = "===== PENGATURAN UTAMA =====";
input string            Indi_ID            = "1";
input ENUM_CUSTOM_TF    TimeFrame          = TF_M5;
input int               MaxBarsToCalculate = 1000;
input bool              ConfirmOnClose     = true;           // Struktur dari Candle Close Saja (Anti Repaint)

input string            Struct_Settings    = "===== MARKET STRUCTURE =====";
input ENUM_SWING_MODE   SwingMode          = SWING_FRACTAL;
input int               Fractal_Bars       = 3;              // Fractal: Jumlah Bar Kiri & Kanan
input bool              ShowSwingLine      = false;
input color             SwingLineColor     = clrDimGray;
input ENUM_BREAK_MODE   BreakoutMode       = BREAK_BODY;
input bool              ShowLabel          = true;
input color             BullishColor       = clrLime;
input color             BearishColor       = clrRed;
input int               LineWidth          = 2;

input string            ZZ_Settings        = "===== ZIGZAG SETUP =====";
input int               ZZ_Depth           = 12;
input int               ZZ_Deviation       = 5;
input int               ZZ_Backstep        = 3;

input string            MA_Settings        = "===== CROSSING MA SETUP =====";
input int               MA_Fast_Period     = 4;
input int               MA_Slow_Period     = 8;
input ENUM_MA_METHOD    MA_Method          = MODE_SMA;
input ENUM_APPLIED_PRICE MA_Applied_Price  = PRICE_MEDIAN;

input string            OB_Settings        = "===== ORDER BLOCK SETUP =====";
input ENUM_OB_MODE      OB_Type            = OB_STANDARD;    // Pilih Logika Pembentukan OB
input ENUM_OB_PICK      StdOB_Pick         = OB_DECISIONAL;  // OB Klasik: Pilihan Candle
input bool              StdOB_RequireDisplacement = true;    // OB Klasik Wajib Diikuti FVG (Displacement)
input bool              DrawOrderBlocks    = true;
input color             BullishOBColor     = C'0,32,0';
input color             BearishOBColor     = C'48,0,0';
input bool              ShowMitigatedOB    = true;
input bool              ColorOnMitigation  = true;
input color             BullishMitigatedColor = C'0,12,0';
input color             BearishMitigatedColor = C'28,0,0';
input int               OBExtendBars       = 25;

input string            FVG_Filter_Settings = "===== FILTER FVG =====";
input bool              RequireFVG          = true;
input double            MinFVGPips          = 50;            // FVG Minimal (Pips; XAUUSD: 100 = $1)

input string            Fibo_Settings      = "===== FIBONACCI =====";
input bool              ShowFibo           = false;
input bool              DualFibo           = false;
input bool              FiboRayRight       = false;          // Fibo Memanjang Tak Terbatas (Ray)
input int               FiboExtendBars     = 10;             // Panjang Fibo ke Depan
input color             BullishFiboColor   = clrDodgerBlue;
input color             BullishFiboLevelColor = clrDodgerBlue;
input color             BearishFiboColor   = clrCrimson;
input color             BearishFiboLevelColor = clrCrimson;
input ENUM_LINE_STYLE   FiboLevelStyle     = STYLE_DOT;
input int               FiboLevelWidth     = 1;

extern string           Button_Style           = "======= Button Style =======";
int                     btn_Subwindow          = 0;
ENUM_BASE_CORNER        btn_corner             = CORNER_LEFT_UPPER;
string                  btn_Font               = "Arial";
int                     btn_FontSize           = 9;
color                   btn_text_ON_color      = clrLime;
color                   btn_text_OFF_color     = clrCoral;
color                   btn_background_color   = clrDimGray;
color                   btn_border_color       = clrBlack;
input int               button_x               = 700;
input int               button_y               = 20;
int                     btn_Width              = 90;
int                     btn_Height             = 20;
bool                    btn_Initial_Default_ON = true;

// --- Variabel Global Internal ---
string   prefixID = "";
string   buttonName = "";
bool     showTampilan = true;
string   btn_text = "SMC OB";
string   textBOS = "";

// Recalculation control: the whole structure is rebuilt once per new chart/HTF bar.
datetime g_lastChartBar = 0;
datetime g_lastHTFBar = 0;
int      g_lastHTFCount = 0;   // detects HTF history that finished loading mid-bar

// --- Struct Arrays for Rendering ---
struct SLine {
   string   name;
   string   text;
   datetime t1;
   double   p1;
   datetime t2;
   color    clr;
};
SLine linesToDraw[];
int   lineCount = 0;

struct SOB {
   string   name;
   datetime t1;
   double   top;
   datetime t2;
   double   bot;
   color    clr;
   bool     mitigated;
   datetime mitTime;   // close time of the first candle that touched the OB
};
SOB obsToDraw[];
int obCount = 0;

struct SPendingOB {
   datetime t1;
   double   top;
   double   bot;
   string   type;
   color    clr;
};
SPendingOB pendingOBs[];
int        pendingOBCount = 0;

struct SSwingLine {
   string   name;
   datetime t1;
   double   p1;
   datetime t2;
   double   p2;
   color    clr;
};
SSwingLine swingLinesToDraw[];
int        swingLineCount = 0;

string activeChartObjects[];
int    activeObjectsCount = 0;

//+------------------------------------------------------------------+
//| Initialization function                                          |
//+------------------------------------------------------------------+
int OnInit()
{
   if(Fractal_Bars < 1 || Fractal_Bars > 20 || MaxBarsToCalculate < 50 || MinFVGPips < 0)
   {
      Print("Parameter tidak valid: Fractal_Bars 1..20, MaxBarsToCalculate >= 50, MinFVGPips >= 0.");
      return(INIT_PARAMETERS_INCORRECT);
   }

   textBOS = "BOS";
   prefixID = "SMC_" + Indi_ID + "_";
   buttonName = prefixID + "TOGGLE_BTN";
   btn_text = "SMC " + Indi_ID;

   DeleteIndicatorObjects(false);   // keep the toggle button so its ON/OFF state survives re-init

   if(ObjectFind(0, buttonName) < 0)
   {
      createButton(buttonName, btn_text, btn_Width, btn_Height, btn_Font, btn_FontSize, btn_background_color, btn_border_color, btn_text_ON_color);
      ObjectSetInteger(0, buttonName, OBJPROP_STATE, btn_Initial_Default_ON);
   }
   ObjectSetInteger(0, buttonName, OBJPROP_YDISTANCE, button_y);
   ObjectSetInteger(0, buttonName, OBJPROP_XDISTANCE, button_x);

   showTampilan = (bool)ObjectGetInteger(0, buttonName, OBJPROP_STATE);
   ObjectSetInteger(0, buttonName, OBJPROP_COLOR, showTampilan ? btn_text_ON_color : btn_text_OFF_color);

   g_lastChartBar = 0;
   g_lastHTFBar = 0;
   g_lastHTFCount = 0;
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   // Timeframe change: keep the button (and its state). Removal / new inputs: delete everything.
   DeleteIndicatorObjects(reason != REASON_CHARTCHANGE);
}

void DeleteIndicatorObjects(bool includeButton)
{
   for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--)
   {
      string n = ObjectName(0, i);
      if(StringFind(n, prefixID) != 0) continue;
      if(!includeButton && n == buttonName) continue;
      ObjectDelete(0, n);
   }
}

// XAUUSD: 1 pip = $0.01 on 2- and 3-digit quotes (same convention as the EA).
double PipSize()
{
   string s = Symbol();
   StringToUpper(s);
   if(StringFind(s, "XAU") >= 0 || StringFind(s, "GOLD") >= 0) return 0.01;
   return (Digits == 3 || Digits == 5) ? Point * 10 : Point;
}

//+------------------------------------------------------------------+
//| Main Iteration function                                          |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[], const double &open[], const double &high[], const double &low[], const double &close[], const long &tick_volume[], const long &volume[], const int &spread[])
{
   ENUM_TIMEFRAMES tf = (ENUM_TIMEFRAMES)TimeFrame;
   int htfBars = iBars(NULL, tf);
   datetime htf0 = iTime(NULL, tf, 0);
   if(htfBars < 50 || htf0 == 0) return(0);   // history not ready yet: retry on the next tick

   // With closed-bar confirmation nothing changes inside a bar, so rebuild only on a new bar
   // (chart TF for the zone extension, HTF for the structure). Live mode rebuilds every tick.
   bool recalc = (!ConfirmOnClose || prev_calculated == 0 || Time[0] != g_lastChartBar ||
                  htf0 != g_lastHTFBar || htfBars != g_lastHTFCount);
   if(!recalc) return(rates_total);
   g_lastChartBar = Time[0];
   g_lastHTFBar = htf0;
   g_lastHTFCount = htfBars;

   CalculateStructure(tf, htfBars);
   return(rates_total);
}

void CalculateStructure(ENUM_TIMEFRAMES tf, int htfBars)
{
   double   lastHighPrice = 0, lastLowPrice = 0;
   datetime lastHighTime  = 0, lastLowTime  = 0;
   string   lastBreakType = "";

   bool     bullFiboActive = false, bearFiboActive = false;
   datetime bullFiboStartT = 0, bullFiboEndT = 0;
   double   bullFiboStartP = 0, bullFiboEndP = 0;
   datetime bearFiboStartT = 0, bearFiboEndT = 0;
   double   bearFiboStartP = 0, bearFiboEndP = 0;

   int      maTrend = 0;
   double   tempHigh = 0, tempLow = 999999;
   datetime tempHighTime = 0, tempLowTime = 0;
   datetime lastSwingNodeTime = 0;
   double   lastSwingNodePrice = 0;

   lineCount = 0;
   obCount = 0;
   pendingOBCount = 0;
   swingLineCount = 0;

   int limit = (int)MathMin(MaxBarsToCalculate, htfBars - 1);
   int firstBar = ConfirmOnClose ? 1 : 0;   // bar 0 is still forming: its close is not final
   if(limit <= firstBar) return;

   double minGap = MinFVGPips * PipSize();
   int periodSec = PeriodSeconds(tf);

   for(int i = limit; i >= firstBar; i--)
   {
      double   c_i = iClose(NULL, tf, i);
      double   h_i = iHigh(NULL, tf, i);
      double   l_i = iLow(NULL, tf, i);
      datetime t_i = iTime(NULL, tf, i);

      double breakPriceUp = (BreakoutMode == BREAK_BODY) ? c_i : h_i;
      double breakPriceDn = (BreakoutMode == BREAK_BODY) ? c_i : l_i;

      // ==========================================================
      // 1. SCANNING ENGINE: POLA 4-CANDLE OB & FVG
      // ==========================================================
      if(OB_Type == OB_4_CANDLE && i + 3 < htfBars)
      {
         double c_4 = iClose(NULL, tf, i + 3); double o_4 = iOpen(NULL, tf, i + 3);
         double h_4 = iHigh(NULL, tf, i + 3);  double l_4 = iLow(NULL, tf, i + 3);
         double c_3 = iClose(NULL, tf, i + 2); double o_3 = iOpen(NULL, tf, i + 2);
         double h_3 = iHigh(NULL, tf, i + 2);  double l_3 = iLow(NULL, tf, i + 2);
         double h_2 = iHigh(NULL, tf, i + 1);  double l_2 = iLow(NULL, tf, i + 1);

         if(o_4 > c_4 && o_3 < c_3) // Demand
         {
            bool hasFVG = RequireFVG ? ((l_i - h_4) >= minGap) : (l_i > h_4);
            if(hasFVG) AddPendingOB(iTime(NULL, tf, i + 3), MathMin(l_4, MathMin(l_3, l_2)), h_4, "BULLISH", BullishOBColor);
         }
         if(o_4 < c_4 && o_3 > c_3) // Supply
         {
            bool hasFVG = RequireFVG ? ((l_4 - h_i) >= minGap) : (l_4 > h_i);
            if(hasFVG) AddPendingOB(iTime(NULL, tf, i + 3), l_4, MathMax(h_4, MathMax(h_3, h_2)), "BEARISH", BearishOBColor);
         }
      }

      // ==========================================================
      // 2. INVALIDATION ENGINE: HAPUS PENDING OB YANG TERTEMBUS
      // ==========================================================
      for(int p = pendingOBCount - 1; p >= 0; p--)
      {
         bool broken = (pendingOBs[p].type == "BULLISH" && breakPriceDn < pendingOBs[p].bot) ||
                       (pendingOBs[p].type == "BEARISH" && breakPriceUp > pendingOBs[p].top);
         if(broken) RemovePendingOB(p);
      }

      // ==========================================================
      // 3. DETEKSI SWING
      // ==========================================================
      if(SwingMode == SWING_ZIGZAG)
      {
         double zz = iCustom(NULL, tf, "ZigZag", ZZ_Depth, ZZ_Deviation, ZZ_Backstep, 0, i);
         if(zz > 0.0)
         {
            if(MathAbs(zz - h_i) <= MathAbs(zz - l_i)) { lastHighPrice = zz; lastHighTime = t_i; }
            else                                         { lastLowPrice = zz;  lastLowTime = t_i; }
            if(ShowSwingLine && lastSwingNodeTime > 0 && lastSwingNodeTime != t_i)
               AddSwingLine(prefixID + "SWING_", lastSwingNodeTime, lastSwingNodePrice, t_i, zz, SwingLineColor);
            lastSwingNodeTime = t_i; lastSwingNodePrice = zz;
         }
      }
      else if(SwingMode == SWING_MA_CROSS)
      {
         double ma_fast = iMA(NULL, tf, MA_Fast_Period, 0, MA_Method, MA_Applied_Price, i);
         double ma_slow = iMA(NULL, tf, MA_Slow_Period, 0, MA_Method, MA_Applied_Price, i);

         if(maTrend == 0)
         {
            if(ma_fast > ma_slow) maTrend = 1; else if(ma_fast < ma_slow) maTrend = -1;
            tempHigh = h_i; tempHighTime = t_i; tempLow = l_i; tempLowTime = t_i;
            lastSwingNodeTime = t_i; lastSwingNodePrice = (ma_fast > ma_slow) ? l_i : h_i;
         }
         else if(maTrend == 1)
         {
            if(h_i > tempHigh) { tempHigh = h_i; tempHighTime = t_i; }
            if(ma_fast < ma_slow)
            {
               lastHighPrice = tempHigh; lastHighTime = tempHighTime; maTrend = -1;
               if(ShowSwingLine && lastSwingNodeTime > 0 && lastSwingNodeTime != tempHighTime)
                  AddSwingLine(prefixID + "SWING_", lastSwingNodeTime, lastSwingNodePrice, tempHighTime, tempHigh, SwingLineColor);
               lastSwingNodeTime = tempHighTime; lastSwingNodePrice = tempHigh;
               tempLow = l_i; tempLowTime = t_i;
            }
         }
         else if(maTrend == -1)
         {
            if(l_i < tempLow) { tempLow = l_i; tempLowTime = t_i; }
            if(ma_fast > ma_slow)
            {
               lastLowPrice = tempLow; lastLowTime = tempLowTime; maTrend = 1;
               if(ShowSwingLine && lastSwingNodeTime > 0 && lastSwingNodeTime != tempLowTime)
                  AddSwingLine(prefixID + "SWING_", lastSwingNodeTime, lastSwingNodePrice, tempLowTime, tempLow, SwingLineColor);
               lastSwingNodeTime = tempLowTime; lastSwingNodePrice = tempLow;
               tempHigh = h_i; tempHighTime = t_i;
            }
         }
      }
      else // SWING_FRACTAL: the pivot at p = i + Fractal_Bars is confirmed once bar i has closed
      {
         int pv = i + Fractal_Bars;
         if(pv + Fractal_Bars < htfBars)
         {
            if(IsFractalHigh(tf, pv, Fractal_Bars))
            {
               double ph = iHigh(NULL, tf, pv); datetime pt = iTime(NULL, tf, pv);
               lastHighPrice = ph; lastHighTime = pt;
               if(ShowSwingLine && lastSwingNodeTime > 0 && lastSwingNodeTime != pt)
                  AddSwingLine(prefixID + "SWING_", lastSwingNodeTime, lastSwingNodePrice, pt, ph, SwingLineColor);
               lastSwingNodeTime = pt; lastSwingNodePrice = ph;
            }
            if(IsFractalLow(tf, pv, Fractal_Bars))
            {
               double pl = iLow(NULL, tf, pv); datetime plt = iTime(NULL, tf, pv);
               lastLowPrice = pl; lastLowTime = plt;
               if(ShowSwingLine && lastSwingNodeTime > 0 && lastSwingNodeTime != plt)
                  AddSwingLine(prefixID + "SWING_", lastSwingNodeTime, lastSwingNodePrice, plt, pl, SwingLineColor);
               lastSwingNodeTime = plt; lastSwingNodePrice = pl;
            }
         }
      }

      // ==========================================================
      // 4. BOS / CHOCH (urutan prioritas sama dengan versi sebelumnya)
      // ==========================================================
      bool canBull = (lastHighPrice > 0 && breakPriceUp > lastHighPrice);
      bool canBear = (lastLowPrice > 0 && breakPriceDn < lastLowPrice);
      bool bullBreak = false, bearBreak = false;

      if(lastBreakType == "DOWN") { if(canBear) bearBreak = true; else if(canBull) bullBreak = true; }
      else                        { if(canBull) bullBreak = true; else if(canBear) bearBreak = true; }

      if(bullBreak)
      {
         bool isBOS = (lastBreakType == "UP");
         AddMemoryLine(prefixID + (isBOS ? "BOS" : "CH") + "_UP_", isBOS ? textBOS : "CHOCH", lastHighTime, lastHighPrice, t_i, BullishColor);
         lastBreakType = "UP";
         lastHighPrice = 0;

         if(lastLowTime > 0)
         {
            bullFiboActive = true;
            if(isBOS || !DualFibo) bearFiboActive = false;
            bullFiboStartT = lastLowTime;
            bullFiboStartP = iLow(NULL, tf, iBarShift(NULL, tf, lastLowTime));
            bullFiboEndT = t_i; bullFiboEndP = h_i;
         }

         if(DrawOrderBlocks)
         {
            if(OB_Type == OB_4_CANDLE)
            {
               for(int p = pendingOBCount - 1; p >= 0; p--)
               {
                  if(pendingOBs[p].type != "BULLISH") continue;
                  AddActiveOB("BULL", pendingOBs[p].t1, pendingOBs[p].top, pendingOBs[p].bot, pendingOBs[p].clr);
                  RemovePendingOB(p);
               }
            }
            else if(lastLowTime > 0)
            {
               double obTop = 0, obBot = 0; datetime obTime = 0;
               if(FindStandardOB(i, iBarShift(NULL, tf, lastLowTime), true, tf, minGap, obTop, obBot, obTime))
                  AddActiveOB("BULL", obTime, obTop, obBot, BullishOBColor);
            }
         }
      }
      else if(bearBreak)
      {
         bool isBOS = (lastBreakType == "DOWN");
         AddMemoryLine(prefixID + (isBOS ? "BOS" : "CH") + "_DN_", isBOS ? textBOS : "CHOCH", lastLowTime, lastLowPrice, t_i, BearishColor);
         lastBreakType = "DOWN";
         lastLowPrice = 0;

         if(lastHighTime > 0)
         {
            bearFiboActive = true;
            if(isBOS || !DualFibo) bullFiboActive = false;
            bearFiboStartT = lastHighTime;
            bearFiboStartP = iHigh(NULL, tf, iBarShift(NULL, tf, lastHighTime));
            bearFiboEndT = t_i; bearFiboEndP = l_i;
         }

         if(DrawOrderBlocks)
         {
            if(OB_Type == OB_4_CANDLE)
            {
               for(int p = pendingOBCount - 1; p >= 0; p--)
               {
                  if(pendingOBs[p].type != "BEARISH") continue;
                  AddActiveOB("BEAR", pendingOBs[p].t1, pendingOBs[p].top, pendingOBs[p].bot, pendingOBs[p].clr);
                  RemovePendingOB(p);
               }
            }
            else if(lastHighTime > 0)
            {
               double obTop = 0, obBot = 0; datetime obTime = 0;
               if(FindStandardOB(i, iBarShift(NULL, tf, lastHighTime), false, tf, minGap, obTop, obBot, obTime))
                  AddActiveOB("BEAR", obTime, obTop, obBot, BearishOBColor);
            }
         }
      }

      // ==========================================================
      // 5. EKSTENSI FIBO
      // ==========================================================
      if(bullFiboActive)
      {
         if(h_i > bullFiboEndP) { bullFiboEndP = h_i; bullFiboEndT = t_i; }
         if(c_i < bullFiboStartP) bullFiboActive = false;
      }
      if(bearFiboActive)
      {
         if(l_i < bearFiboEndP) { bearFiboEndP = l_i; bearFiboEndT = t_i; }
         if(c_i > bearFiboStartP) bearFiboActive = false;
      }

      // ==========================================================
      // 6. INVALIDASI & MITIGASI OB AKTIF
      // ==========================================================
      if(DrawOrderBlocks)
      {
         for(int j = obCount - 1; j >= 0; j--)
         {
            bool isBull = (StringFind(obsToDraw[j].name, "_OB_BULL_") >= 0);

            bool isBroken = isBull ? (breakPriceDn < obsToDraw[j].bot) : (breakPriceUp > obsToDraw[j].top);
            if(isBroken) { RemoveActiveOB(j); continue; }

            if(obsToDraw[j].mitigated) continue;
            bool touched = isBull ? (l_i <= obsToDraw[j].top) : (h_i >= obsToDraw[j].bot);
            if(!touched) continue;

            if(!ShowMitigatedOB) { RemoveActiveOB(j); continue; }
            obsToDraw[j].mitigated = true;
            obsToDraw[j].mitTime = t_i + periodSec;
            if(ColorOnMitigation) obsToDraw[j].clr = isBull ? BullishMitigatedColor : BearishMitigatedColor;
         }
         MergeOverlappingOBs();
      }
   }

   datetime liveEndTime = GetOBEndTime(0, OBExtendBars, PERIOD_CURRENT);
   for(int m = 0; m < obCount; m++) obsToDraw[m].t2 = liveEndTime;

   UpdateChartObjects();
   DrawDynamicFibo(bullFiboActive, "BULL", bullFiboStartT, bullFiboStartP, bullFiboEndT, bullFiboEndP, BullishFiboColor, BullishFiboLevelColor);
   DrawDynamicFibo(bearFiboActive, "BEAR", bearFiboStartT, bearFiboStartP, bearFiboEndT, bearFiboEndP, BearishFiboColor, BearishFiboLevelColor);
}

//+------------------------------------------------------------------+
//| SWING HELPERS                                                    |
//+------------------------------------------------------------------+
bool IsFractalHigh(ENUM_TIMEFRAMES tf, int p, int k)
{
   double h = iHigh(NULL, tf, p);
   for(int j = 1; j <= k; j++)
      if(iHigh(NULL, tf, p + j) >= h || iHigh(NULL, tf, p - j) > h) return false;
   return true;
}

bool IsFractalLow(ENUM_TIMEFRAMES tf, int p, int k)
{
   double l = iLow(NULL, tf, p);
   for(int j = 1; j <= k; j++)
      if(iLow(NULL, tf, p + j) <= l || iLow(NULL, tf, p - j) < l) return false;
   return true;
}

//+------------------------------------------------------------------+
//| VIRTUAL MEMORY MANAGERS                                          |
//+------------------------------------------------------------------+
void AddMemoryLine(string prefix, string text, datetime t1, double p1, datetime t2, color clr)
{
   if(lineCount >= ArraySize(linesToDraw)) ArrayResize(linesToDraw, lineCount + 10);
   linesToDraw[lineCount].name = prefix + TimeToString(t1, TIME_DATE|TIME_MINUTES|TIME_SECONDS);
   linesToDraw[lineCount].text = text;
   linesToDraw[lineCount].t1 = t1;
   linesToDraw[lineCount].p1 = p1;
   linesToDraw[lineCount].t2 = t2;
   linesToDraw[lineCount].clr = clr;
   lineCount++;
}

void AddSwingLine(string prefix, datetime t1, double p1, datetime t2, double p2, color clr)
{
   if(swingLineCount >= ArraySize(swingLinesToDraw)) ArrayResize(swingLinesToDraw, swingLineCount + 50);
   swingLinesToDraw[swingLineCount].name = prefix + TimeToString(t1, TIME_DATE|TIME_MINUTES|TIME_SECONDS);
   swingLinesToDraw[swingLineCount].t1 = t1;
   swingLinesToDraw[swingLineCount].p1 = p1;
   swingLinesToDraw[swingLineCount].t2 = t2;
   swingLinesToDraw[swingLineCount].p2 = p2;
   swingLinesToDraw[swingLineCount].clr = clr;
   swingLineCount++;
}

void AddPendingOB(datetime t, double bot, double top, string type, color clr)
{
   if(pendingOBCount >= ArraySize(pendingOBs)) ArrayResize(pendingOBs, pendingOBCount + 10);
   pendingOBs[pendingOBCount].t1 = t;
   pendingOBs[pendingOBCount].bot = bot;
   pendingOBs[pendingOBCount].top = top;
   pendingOBs[pendingOBCount].type = type;
   pendingOBs[pendingOBCount].clr = clr;
   pendingOBCount++;
}

void RemovePendingOB(int idx)
{
   for(int k = idx; k < pendingOBCount - 1; k++) pendingOBs[k] = pendingOBs[k + 1];
   pendingOBCount--;
}

// kind = "BULL" / "BEAR". The name (and so the object) is unique per OB candle.
void AddActiveOB(string kind, datetime t, double top, double bot, color clr)
{
   string name = prefixID + "OB_" + kind + "_" + TimeToString(t, TIME_DATE|TIME_MINUTES|TIME_SECONDS);
   for(int k = 0; k < obCount; k++) if(obsToDraw[k].name == name) return;
   if(obCount >= ArraySize(obsToDraw)) ArrayResize(obsToDraw, obCount + 10);
   obsToDraw[obCount].name = name;
   obsToDraw[obCount].t1 = t;
   obsToDraw[obCount].top = top;
   obsToDraw[obCount].bot = bot;
   obsToDraw[obCount].t2 = 0;
   obsToDraw[obCount].clr = clr;
   obsToDraw[obCount].mitigated = false;
   obsToDraw[obCount].mitTime = 0;
   obCount++;
}

void RemoveActiveOB(int idx)
{
   for(int k = idx; k < obCount - 1; k++) obsToDraw[k] = obsToDraw[k + 1];
   obCount--;
}

// Same-direction OBs that overlap become one zone (earliest start, earliest mitigation).
void MergeOverlappingOBs()
{
   bool hasMerged = true;
   while(hasMerged && obCount > 1)
   {
      hasMerged = false;
      for(int a = 0; a < obCount - 1 && !hasMerged; a++)
      {
         bool aIsBull = (StringFind(obsToDraw[a].name, "_OB_BULL_") >= 0);
         for(int b = a + 1; b < obCount; b++)
         {
            bool bIsBull = (StringFind(obsToDraw[b].name, "_OB_BULL_") >= 0);
            if(aIsBull != bIsBull) continue;
            if(obsToDraw[a].bot > obsToDraw[b].top || obsToDraw[a].top < obsToDraw[b].bot) continue;

            obsToDraw[a].top = MathMax(obsToDraw[a].top, obsToDraw[b].top);
            obsToDraw[a].bot = MathMin(obsToDraw[a].bot, obsToDraw[b].bot);
            if(obsToDraw[b].t1 < obsToDraw[a].t1) obsToDraw[a].t1 = obsToDraw[b].t1;
            if(obsToDraw[b].mitigated)
            {
               if(!obsToDraw[a].mitigated || obsToDraw[b].mitTime < obsToDraw[a].mitTime) obsToDraw[a].mitTime = obsToDraw[b].mitTime;
               obsToDraw[a].mitigated = true;
               if(ColorOnMitigation) obsToDraw[a].clr = aIsBull ? BullishMitigatedColor : BearishMitigatedColor;
            }
            RemoveActiveOB(b);
            hasMerged = true;
            break;
         }
      }
   }
}

// ====================================================================
// ORDER BLOCK SMC KLASIK
// Decisional = candle lawan terdekat ke breakout (perilaku versi lama).
// Extreme    = candle lawan di ujung swing (low untuk bullish, high untuk bearish).
// Displacement = harus ada FVG >= MinFVGPips antara OB dan candle breakout.
// ====================================================================
bool IsOppositeCandle(ENUM_TIMEFRAMES tf, int k, bool bullishOB)
{
   double o = iOpen(NULL, tf, k), c = iClose(NULL, tf, k);
   return bullishOB ? (o > c) : (c > o);
}

bool HasDisplacement(ENUM_TIMEFRAMES tf, int breakIndex, int obIndex, bool bullishOB, double minGap)
{
   double need = MathMax(minGap, Point);
   for(int k = breakIndex; k + 2 <= obIndex; k++)
   {
      double gap = bullishOB ? iLow(NULL, tf, k) - iHigh(NULL, tf, k + 2)
                             : iLow(NULL, tf, k + 2) - iHigh(NULL, tf, k);
      if(gap >= need) return true;
   }
   return false;
}

bool FindStandardOB(int breakIndex, int swingIndex, bool bullishOB, ENUM_TIMEFRAMES tf, double minGap,
                    double &obTop, double &obBot, datetime &obTime)
{
   obTop = 0; obBot = 0; obTime = 0;
   if(breakIndex < 0 || swingIndex <= breakIndex) return false;

   int obIndex = -1;
   if(StdOB_Pick == OB_DECISIONAL)
   {
      for(int k = breakIndex + 1; k <= swingIndex; k++)
         if(IsOppositeCandle(tf, k, bullishOB)) { obIndex = k; break; }
   }
   else
   {
      int count = swingIndex - breakIndex;
      int ext = bullishOB ? iLowest(NULL, tf, MODE_LOW, count, breakIndex + 1)
                          : iHighest(NULL, tf, MODE_HIGH, count, breakIndex + 1);
      int last = MathMin(swingIndex + 3, iBars(NULL, tf) - 1);
      for(int k = ext; k >= 0 && k <= last; k++)
         if(IsOppositeCandle(tf, k, bullishOB)) { obIndex = k; break; }
   }
   if(obIndex < 0) obIndex = swingIndex;   // fallback: the swing candle itself

   if(StdOB_RequireDisplacement && !HasDisplacement(tf, breakIndex, obIndex, bullishOB, minGap)) return false;

   obTop  = iHigh(NULL, tf, obIndex);
   obBot  = iLow(NULL, tf, obIndex);
   obTime = iTime(NULL, tf, obIndex);
   return true;
}

//+------------------------------------------------------------------+
//| SMART RENDERING ENGINE                                           |
//+------------------------------------------------------------------+
void UpdateChartObjects()
{
   activeObjectsCount = 0;
   int requiredSize = (lineCount * 2) + obCount + swingLineCount + 5;
   if(ArraySize(activeChartObjects) < requiredSize) ArrayResize(activeChartObjects, requiredSize);

   int visibility = showTampilan ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS;
   int lineVisibility = (showTampilan && ShowLabel) ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS;

   for(int i = 0; i < swingLineCount; i++)
   {
      string name = swingLinesToDraw[i].name;
      activeChartObjects[activeObjectsCount++] = name;
      if(ObjectFind(0, name) < 0)
      {
         ObjectCreate(0, name, OBJ_TREND, 0, swingLinesToDraw[i].t1, swingLinesToDraw[i].p1, swingLinesToDraw[i].t2, swingLinesToDraw[i].p2);
         ObjectSetInteger(0, name, OBJPROP_COLOR, swingLinesToDraw[i].clr);
         ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
         ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
         ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      }
      ObjectSetInteger(0, name, OBJPROP_TIME, 0, swingLinesToDraw[i].t1);
      ObjectSetDouble(0, name, OBJPROP_PRICE, 0, swingLinesToDraw[i].p1);
      ObjectSetInteger(0, name, OBJPROP_TIME, 1, swingLinesToDraw[i].t2);
      ObjectSetDouble(0, name, OBJPROP_PRICE, 1, swingLinesToDraw[i].p2);
      ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, visibility);
   }

   int bosCounter = 1;   // BOS numbering restarts after every CHoCH
   for(int i = 0; i < lineCount; i++)
   {
      string name = linesToDraw[i].name;
      string txtName = name + "_txt";
      activeChartObjects[activeObjectsCount++] = name;
      activeChartObjects[activeObjectsCount++] = txtName;

      if(ObjectFind(0, name) < 0)
      {
         ObjectCreate(0, name, OBJ_TREND, 0, linesToDraw[i].t1, linesToDraw[i].p1, linesToDraw[i].t2, linesToDraw[i].p1);
         ObjectSetInteger(0, name, OBJPROP_COLOR, linesToDraw[i].clr);
         ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
         ObjectSetInteger(0, name, OBJPROP_WIDTH, LineWidth);
         ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
         ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      }
      ObjectSetInteger(0, name, OBJPROP_TIME, 1, linesToDraw[i].t2);
      ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, lineVisibility);

      bool isUp = (StringFind(name, "_UP_") >= 0);
      int textAnchor = isUp ? ANCHOR_RIGHT_LOWER : ANCHOR_RIGHT_UPPER;

      string labelText = linesToDraw[i].text;
      if(StringFind(labelText, "CHOCH") >= 0) bosCounter = 1;
      else if(StringFind(labelText, textBOS) >= 0) { labelText = labelText + " " + IntegerToString(bosCounter); bosCounter++; }

      if(ObjectFind(0, txtName) < 0)
      {
         ObjectCreate(0, txtName, OBJ_TEXT, 0, linesToDraw[i].t2, linesToDraw[i].p1);
         ObjectSetInteger(0, txtName, OBJPROP_COLOR, linesToDraw[i].clr);
         ObjectSetInteger(0, txtName, OBJPROP_FONTSIZE, 9);
         ObjectSetInteger(0, txtName, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, txtName, OBJPROP_HIDDEN, true);
      }
      ObjectSetString(0, txtName, OBJPROP_TEXT, " " + labelText);
      ObjectSetInteger(0, txtName, OBJPROP_TIME, 0, linesToDraw[i].t2);
      ObjectSetInteger(0, txtName, OBJPROP_ANCHOR, textAnchor);
      ObjectSetInteger(0, txtName, OBJPROP_TIMEFRAMES, lineVisibility);
   }

   string tfName = TFLabel((ENUM_TIMEFRAMES)TimeFrame);
   for(int i = 0; i < obCount; i++)
   {
      string name = obsToDraw[i].name;
      activeChartObjects[activeObjectsCount++] = name;

      if(ObjectFind(0, name) < 0)
      {
         ObjectCreate(0, name, OBJ_RECTANGLE, 0, obsToDraw[i].t1, obsToDraw[i].top, obsToDraw[i].t2, obsToDraw[i].bot);
         ObjectSetInteger(0, name, OBJPROP_FILL, true);
         ObjectSetInteger(0, name, OBJPROP_BACK, true);
         ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      }
      ObjectSetInteger(0, name, OBJPROP_TIME, 0, obsToDraw[i].t1);
      ObjectSetDouble(0, name, OBJPROP_PRICE, 0, obsToDraw[i].top);
      ObjectSetInteger(0, name, OBJPROP_TIME, 1, obsToDraw[i].t2);
      ObjectSetDouble(0, name, OBJPROP_PRICE, 1, obsToDraw[i].bot);
      ObjectSetInteger(0, name, OBJPROP_COLOR, obsToDraw[i].clr);
      ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, visibility);

      // State for the EA: "OB|BULL|FRESH" or "OB|BULL|MIT|<unix close time of the first touch>"
      string kind = (StringFind(name, "_OB_BULL_") >= 0) ? "BULL" : "BEAR";
      string state = obsToDraw[i].mitigated ? "MIT|" + IntegerToString((long)obsToDraw[i].mitTime) : "FRESH";
      ObjectSetString(0, name, OBJPROP_TEXT, "OB|" + kind + "|" + state);
      ObjectSetString(0, name, OBJPROP_TOOLTIP, (kind == "BULL" ? "Bullish OB " : "Bearish OB ") + tfName +
                      (obsToDraw[i].mitigated ? " (tersentuh)" : " (segar)"));
   }

   // Remove this instance's objects that are no longer part of the structure (once per bar).
   int totalObj = ObjectsTotal(0, -1, -1);
   for(int i = totalObj - 1; i >= 0; i--)
   {
      string objName = ObjectName(0, i);
      if(StringFind(objName, prefixID) != 0 || objName == buttonName || StringFind(objName, prefixID + "FIBO") == 0) continue;
      bool found = false;
      for(int j = 0; j < activeObjectsCount; j++)
         if(activeChartObjects[j] == objName) { found = true; break; }
      if(!found) ObjectDelete(0, objName);
   }
}

string TFLabel(ENUM_TIMEFRAMES tf)
{
   switch(tf)
   {
      case PERIOD_M1:  return "M1";
      case PERIOD_M5:  return "M5";
      case PERIOD_M15: return "M15";
      case PERIOD_M30: return "M30";
      case PERIOD_H1:  return "H1";
      case PERIOD_H4:  return "H4";
      case PERIOD_D1:  return "D1";
   }
   return IntegerToString((int)tf);
}

// ====================================================================
// FIBONACCI (garis bantu EA "FIBO_EA_*" selalu ada, visual "FIBO_VIS_*" opsional)
// ====================================================================
void DeleteFiboSet(string basePrefix, bool withText)
{
   string lv[4] = {"_50", "_61", "_78", "_100"};
   for(int k = 0; k < 4; k++)
   {
      ObjectDelete(0, basePrefix + lv[k]);
      if(withText) ObjectDelete(0, basePrefix + lv[k] + "_TXT");
   }
}

void DrawDynamicFibo(bool active, string type, datetime t1, double p1, datetime t2, double p2, color fiboColor, color fiboLevelColor)
{
   string helperPrefix = prefixID + "FIBO_EA_" + type;
   string visualPrefix = prefixID + "FIBO_VIS_" + type;

   if(!active)
   {
      DeleteFiboSet(visualPrefix, true);
      DeleteFiboSet(helperPrefix, false);
      return;
   }

   datetime extendedT2 = t2;
   if(!FiboRayRight)
   {
      extendedT2 = GetOBEndTime(0, FiboExtendBars, PERIOD_CURRENT);
      if(extendedT2 < t2) extendedT2 = t2;
   }

   // Retracement of the leg p1 (start) -> p2 (end)
   double lvl50  = p1 + (p2 - p1) * 0.500;
   double lvl61  = p1 + (p2 - p1) * 0.382;   // 61.8% retracement
   double lvl78  = p1 + (p2 - p1) * 0.214;   // 78.6% retracement
   double lvl100 = p1;

   if(ShowFibo)
   {
      int visibility = showTampilan ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS;
      CreateVisualFiboLine(visualPrefix + "_50",  "50.0",  t1, lvl50,  extendedT2, fiboLevelColor, visibility);
      CreateVisualFiboLine(visualPrefix + "_61",  "61.8",  t1, lvl61,  extendedT2, fiboLevelColor, visibility);
      CreateVisualFiboLine(visualPrefix + "_78",  "78.6",  t1, lvl78,  extendedT2, fiboLevelColor, visibility);
      CreateVisualFiboLine(visualPrefix + "_100", "100.0", t1, lvl100, extendedT2, fiboLevelColor, visibility);
   }
   else DeleteFiboSet(visualPrefix, true);

   CreateEAFiboLine(helperPrefix + "_50",  t1, lvl50,  extendedT2, fiboColor, FiboRayRight);
   CreateEAFiboLine(helperPrefix + "_61",  t1, lvl61,  extendedT2, fiboColor, FiboRayRight);
   CreateEAFiboLine(helperPrefix + "_78",  t1, lvl78,  extendedT2, fiboColor, FiboRayRight);
   CreateEAFiboLine(helperPrefix + "_100", t1, lvl100, extendedT2, fiboColor, FiboRayRight);
}

void CreateVisualFiboLine(string objName, string labelText, datetime t1, double price, datetime t2, color clr, int visibility)
{
   if(ObjectFind(0, objName) < 0)
   {
      ObjectCreate(0, objName, OBJ_TREND, 0, t1, price, t2, price);
      ObjectSetInteger(0, objName, OBJPROP_STYLE, FiboLevelStyle);
      ObjectSetInteger(0, objName, OBJPROP_WIDTH, FiboLevelWidth);
      ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, objName, OBJPROP_HIDDEN, true);
   }
   ObjectSetInteger(0, objName, OBJPROP_TIME, 0, t1);
   ObjectSetDouble(0, objName, OBJPROP_PRICE, 0, price);
   ObjectSetInteger(0, objName, OBJPROP_TIME, 1, t2);
   ObjectSetDouble(0, objName, OBJPROP_PRICE, 1, price);
   ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, FiboRayRight);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, objName, OBJPROP_TIMEFRAMES, visibility);

   string txtName = objName + "_TXT";
   if(ObjectFind(0, txtName) < 0)
   {
      ObjectCreate(0, txtName, OBJ_TEXT, 0, t2, price);
      ObjectSetString(0, txtName, OBJPROP_TEXT, " " + labelText);
      ObjectSetInteger(0, txtName, OBJPROP_FONTSIZE, 8);
      ObjectSetInteger(0, txtName, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
      ObjectSetInteger(0, txtName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, txtName, OBJPROP_HIDDEN, true);
   }
   ObjectSetInteger(0, txtName, OBJPROP_TIME, 0, t2);
   ObjectSetDouble(0, txtName, OBJPROP_PRICE, 0, price);
   ObjectSetInteger(0, txtName, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, txtName, OBJPROP_TIMEFRAMES, visibility);
}

void CreateEAFiboLine(string objName, datetime t1, double price, datetime t2, color clr, bool rayRight)
{
   if(ObjectFind(0, objName) < 0)
   {
      ObjectCreate(0, objName, OBJ_TREND, 0, t1, price, t2, price);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, objName, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, objName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);   // invisible, read by the EA
   }
   ObjectSetInteger(0, objName, OBJPROP_TIME, 0, t1);
   ObjectSetDouble(0, objName, OBJPROP_PRICE, 0, price);
   ObjectSetInteger(0, objName, OBJPROP_TIME, 1, t2);
   ObjectSetDouble(0, objName, OBJPROP_PRICE, 1, price);
   ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, rayRight);
}

datetime GetOBEndTime(int barIndex, int extend, ENUM_TIMEFRAMES tf)
{
   if(barIndex - extend >= 0) return iTime(NULL, tf, barIndex - extend);
   int futureBars = extend - barIndex;
   int pSec = PeriodSeconds(tf);
   if(pSec == 0) pSec = PeriodSeconds();
   return iTime(NULL, tf, 0) + (futureBars * pSec);
}

void createButton(string buttonId, string buttonText, int width2, int height, string font, int fontSize, color bgColor, color borderColor, color txtColor)
{
   ObjectDelete(0, buttonId);
   ObjectCreate(0, buttonId, OBJ_BUTTON, btn_Subwindow, 0, 0);
   ObjectSetInteger(0, buttonId, OBJPROP_COLOR, txtColor);
   ObjectSetInteger(0, buttonId, OBJPROP_BGCOLOR, bgColor);
   ObjectSetInteger(0, buttonId, OBJPROP_BORDER_COLOR, borderColor);
   ObjectSetInteger(0, buttonId, OBJPROP_BORDER_TYPE, BORDER_RAISED);
   ObjectSetInteger(0, buttonId, OBJPROP_XSIZE, width2);
   ObjectSetInteger(0, buttonId, OBJPROP_YSIZE, height);
   ObjectSetString(0, buttonId, OBJPROP_FONT, font);
   ObjectSetString(0, buttonId, OBJPROP_TEXT, buttonText);
   ObjectSetInteger(0, buttonId, OBJPROP_FONTSIZE, fontSize);
   ObjectSetInteger(0, buttonId, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, buttonId, OBJPROP_CORNER, btn_corner);
   ObjectSetInteger(0, buttonId, OBJPROP_HIDDEN, true);
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id != CHARTEVENT_OBJECT_CLICK || sparam != buttonName) return;

   showTampilan = (bool)ObjectGetInteger(0, buttonName, OBJPROP_STATE);
   ObjectSetInteger(0, buttonName, OBJPROP_COLOR, showTampilan ? btn_text_ON_color : btn_text_OFF_color);

   int visibility = showTampilan ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS;
   int lineVisibility = (showTampilan && ShowLabel) ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS;

   for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--)
   {
      string objName = ObjectName(0, i);
      if(StringFind(objName, prefixID) != 0 || objName == buttonName) continue;

      if(StringFind(objName, prefixID + "FIBO_EA_") == 0)                                       // EA helpers never shown
         ObjectSetInteger(0, objName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
      else if(StringFind(objName, prefixID + "BOS_") == 0 || StringFind(objName, prefixID + "CH_") == 0)
         ObjectSetInteger(0, objName, OBJPROP_TIMEFRAMES, lineVisibility);
      else
         ObjectSetInteger(0, objName, OBJPROP_TIMEFRAMES, visibility);
   }
   ChartRedraw();
}
//+------------------------------------------------------------------+
