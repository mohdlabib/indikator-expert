//+------------------------------------------------------------------+
//|                                      KG Trading Anti Fomo M5.mq4 |
//|                                       Copyright 2026, Mang Koyod |
//|                                    (VERSI DASHBOARD LEADERBOARD) |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Mang Koyod"
#property link      "https://www.mql5.com"
#property version   "10.0"
#property strict

#define AREA_COUNT   21
#define TREND_SLOTS  10
#define UI_LINES     40
#define NO_ZONE      99999.0

//--- Definisi Pilihan Mode
enum ENUM_TRADING_MODE {
    MODE_AUTO,   // Otomatis (Full Robot)
    MODE_SEMI,   // Semi-Otomatis (Klik dg Validasi Sinyal)
    MODE_MANUAL  // Manual (Bebas Klik, Dibatasi Trend Besar)
};

// --- Definisi Pilihan Mode Deteksi Trend (Khusus VA/POC) ---
enum ENUM_TREND_LOGIC {
    TREND_TIME,           // Waktu Pembuatan Terbaru
    TREND_DISTANCE,       // Terdekat dengan Harga
    TREND_COLOR_CHANGE    // Waktu Perubahan Warna Terbaru (Sangat Disarankan)
};

// --- Definisi Pilihan Syarat Validitas Trend ---
enum ENUM_TREND_VALIDITY {
    TREND_STRICT,  // Ketat (100% Searah)
    TREND_LOOSE,   // Longgar (Di Atas 50% Searah)
    TREND_WEIGHTED // Skor Berbobot >= Skor Minimal (Rekomendasi)
};

// --- Definisi Pilihan Validasi Area Entry ---
enum ENUM_ENTRY_VALIDATION {
    ENTRY_MIN_1, // Minimal Satu Area
    ENTRY_MIN_2  // Minimal Dua Area (Confluence)
};

// --- Definisi Pilihan Area Entry Utama ---
// NOTE: order must match the entry-area list built in RunAnalysis() (index = value - 1).
enum ENUM_PRIMARY_AREA {
    PRIMARY_NONE,         // Bebas (Tanpa Syarat Area Utama)
    PRIMARY_VA,           // Wajib Value Area
    PRIMARY_POC,          // Wajib POC
    PRIMARY_SND,          // Wajib SnD Zone
    PRIMARY_OB1,          // Wajib Order Block 1 (Minor)
    PRIMARY_OB2,          // Wajib Order Block 2 (Medium)
    PRIMARY_OB3,          // Wajib Order Block 3 (Major)
    PRIMARY_OBSCOUT,      // Wajib Order Block Scout
    PRIMARY_FIBO1,        // Wajib SMC Fibo 1
    PRIMARY_FIBO2,        // Wajib SMC Fibo 2
    PRIMARY_FIBO3,        // Wajib SMC Fibo 3 (Major)
    PRIMARY_KGFIBO,       // Wajib KG Fibo
    PRIMARY_FIBOSCOUT,    // Wajib SMC Fibo Scout
    PRIMARY_VWAP1,        // Wajib VWAP 1
    PRIMARY_VWAP2,        // Wajib VWAP 2
    PRIMARY_BBMA1,        // Wajib BBMA 1
    PRIMARY_BBMA2,        // Wajib BBMA 2
    PRIMARY_KGSUPDEM,     // Wajib KG SupDem
    PRIMARY_KGSUPDEM_FIBO,// Wajib KG SupDem Fibo
    PRIMARY_FVG1,         // Wajib FVG 1 (Built-in)
    PRIMARY_FVG2,         // Wajib FVG 2 (Built-in)
    PRIMARY_FVG3          // Wajib FVG 3 (Built-in)
};

// --- Sumber Data SMC / Market Profile ---
enum ENUM_DATA_SOURCE {
    SRC_AUTO,       // Otomatis (Indikator KG jika ada, jika tidak Built-in)
    SRC_INDICATOR,  // Indikator KG Saja
    SRC_BUILTIN     // Built-in EA Saja
};

// --- Sumber Dealing Range untuk Premium/Discount (ICT) ---
enum ENUM_PD_SOURCE {
    PD_SMC1,  // SMC 1 (Minor)
    PD_SMC2,  // SMC 2 (Medium)
    PD_SMC3   // SMC 3 (Major)
};

// --- Definisi Waktu Sesuai Standar Multiplier Kang Gun ---
enum ENUM_KG_TIMEFRAME {
    KG_M30,
    KG_1H,
    KG_2H,
    KG_4H,
    KG_8H,
    KG_1D,
    KG_1W,
    KG_1M,
    KG_4M,
    KG_1Y
};

// ====================================================================
// --- INPUT PARAMETER ---
// (Existing input names are unchanged so saved .set files keep loading.)
// ====================================================================
input string   Mode_Trading     = "====== MODE TRADING ======";
input ENUM_TRADING_MODE TradingMode = MODE_SEMI;      // Mode Trading EA
input bool     CloseOppositeTrend = true;             // Close posisi berlawanan saat tren berubah
input bool     CloseManualTrades  = true;             // Terapkan Reversal Close ke Order Manual
input bool     ManageManualTrades = true;             // Kelola SL/TP, BEP, Trailing untuk Order Manual

input string   Set_Hidden       = "====== HIDDEN PROTEKSI ======";
input bool     UseHiddenSLTP    = false;              // Sembunyikan SL, TP, Trailing dari broker

input string   Set_Display      = "====== PENGATURAN TAMPILAN ======";
input int      PanelXDistance   = 1550;    // Posisi Panel Sumbu X (Geser Kiri/Kanan)
input bool     CleanTradeLines  = true;    // Bersihkan Garis & Panah Histori Trade
input bool     ShowTrendDetails = true;    // Tampilkan Detail Status Alat Ukur Trend
input color    PanelTextColor   = clrBlack;      // Warna Teks Panel (dipakai jika Auto OFF)
input color    HighlightColor   = clrMediumBlue; // Warna Judul Panel (dipakai jika Auto OFF)
input bool     AutoPanelColors  = true;          // Warna Panel Otomatis Sesuai Background Chart
input bool     HideOneClickPanel = true;         // Sembunyikan Panel One Click Trading Bawaan MT4

input string   Main_Trend = "====== ALAT UKUR TREND UTAMA ======";
input bool     UseTrend_VAPOC   = true;    // Aktifkan Trend VA/POC
input bool     UseTrend_SMC1    = true;    // Aktifkan Trend SMC 1 (Minor)
input bool     UseTrend_SMC2    = true;    // Aktifkan Trend SMC 2 (Medium)
input bool     UseTrend_SMC3    = true;    // Aktifkan Trend SMC 3 (Major)
input bool     Use_SMC_Matrix   = true;    // [ON] Mode Matriks SMC (Satu Kesatuan) | [OFF] Berdiri Sendiri
input bool     Use_BBMA_Filter  = false;   // Filter BB Mode Matriks SMC (true = Aktif, false = Non Aktif)

input string   Optional_Trend = "====== ALAT UKUR TREND OPTIONAL ======";
input bool     UseTrend_VWAP1   = true;    // Aktifkan Trend VWAP 1 (Harian)
input bool     UseTrend_VWAP2   = true;    // Aktifkan Trend VWAP 2 (2-Harian)
input bool     UseTrend_BBMA1   = true;    // Aktifkan Trend BBMA 1 (Kecil)
input bool     UseTrend_BBMA2   = true;    // Aktifkan Trend BBMA 2 (Besar)
input bool     UseTrend_EMA     = true;    // Aktifkan Trend MA Crossover 1 (Kecil)
input bool     UseTrend_EMA2    = true;    // Aktifkan Trend MA Crossover 2 (Besar)

input string   Trend_Settings   = "====== PENGATURAN TREND & OBJEK ======";
input ENUM_MA_METHOD MA_Mode  = MODE_SMA; //Mode MA  (Kecil/Besar)
input ENUM_KG_TIMEFRAME EMA_Fast_Period = KG_8H;    // Acuan Waktu Fast MA 1 (Kecil)
input ENUM_KG_TIMEFRAME EMA_Slow_Period = KG_1D;    // Acuan Waktu Slow MA 1 (Kecil)
input ENUM_KG_TIMEFRAME EMA2_Fast_Period = KG_1D;   // Acuan Waktu Fast MA 2 (Besar)
input ENUM_KG_TIMEFRAME EMA2_Slow_Period = KG_1W;   // Acuan Waktu Slow MA 2 (Besar)
input ENUM_KG_TIMEFRAME BBMA1_Timeframe = KG_4H;    // Acuan Waktu BBMA 1 (Kecil)
input ENUM_KG_TIMEFRAME BBMA2_Timeframe = KG_1D;    // Acuan Waktu BBMA 2 (Besar)
input string   SMC1_Prefix      = "SMC_M5_";        // Prefix Indikator SMC 1 (Minor)
input string   SMC2_Prefix      = "SMC_H1_";        // Prefix Indikator SMC 2 (Medium)
input string   SMC3_Prefix      = "SMC_H4_";        // Prefix Indikator SMC 3 (Major)
input string   SMCScout_Prefix  = "SMC_Scout_";     // Prefix Indikator SMC OB Scout
input bool     Aggressive_POI_Entry = true;         // Izinkan SMC Vote Searah Mayor di Zona Discount/Premium
input string   KGFibo_Prefix    = "Fibo_1_";        // Keyword Nama Indikator KG Fibo
input bool     Use_VWAP1_BBSD2  = true;             // Aktifkan Logika BB SD2 (Khusus VWAP Harian)
input bool     UseAdvancedCalc  = true;             // Aktifkan Logika Sideways KGBBMA
input ENUM_TREND_LOGIC TrendLogicMode = TREND_COLOR_CHANGE;    // Mode Deteksi Tren VA/POC
input ENUM_TREND_VALIDITY TrendValidityMode = TREND_WEIGHTED;  // Syarat Validitas Tren
input bool     UseFallback      = true;                        // Abaikan Area Netral

input string   Set_Entry_Area   = "====== FILTER AREA ENTRY ======";
input ENUM_ENTRY_VALIDATION EntryValidationMode = ENTRY_MIN_2;    // Syarat Confluence Area
input ENUM_PRIMARY_AREA PrimaryArea = PRIMARY_OBSCOUT;            // Area Utama (Aktif Jika ENTRY_MIN_2)
input bool     Use_VA_Entry     = true;    // Gunakan Area VA (Micro) untuk Entry
input bool     Use_POC_Entry    = true;    // Gunakan Area POC untuk Entry
input bool     Use_SnD_Entry    = true;    // Gunakan Area SnD untuk Entry
input bool     Use_OB1_Entry    = true;    // Gunakan Area OB 1 (Minor) untuk Entry
input bool     Use_OB2_Entry    = true;    // Gunakan Area OB 2 (Medium) untuk Entry
input bool     Use_OB3_Entry    = true;    // Gunakan Area OB 3 (Major) untuk Entry
input bool     Use_OBScout_Entry= true;    // Gunakan Area OB Scout khusus untuk Entry
input bool     Use_FiboScout_Entry = true; // Gunakan Area Fibo SMC Scout untuk Entry
input bool     Use_Fibo1_Entry  = true;    // Gunakan Area Fibo SMC 1 (Minor) untuk Entry
input bool     Use_Fibo2_Entry  = true;    // Gunakan Area Fibo SMC 2 (Medium) untuk Entry
input bool     Use_Fibo3_Entry  = true;    // Gunakan Area Fibo SMC 3 (Major) untuk Entry
input bool     Use_KGFibo_Entry = true;    // Gunakan Area KG Fibo Dinamis untuk Entry
input bool     Use_VWAP1_Entry  = true;    // Gunakan Area VWAP 1 (Harian) untuk Entry
input bool     Use_VWAP2_Entry  = true;    // Gunakan Area VWAP 2 (2-Harian) untuk Entry
input bool     Use_BBMA1_Entry  = true;    // Gunakan Area BBMA 1 (Kecil) untuk Entry
input bool     Use_BBMA2_Entry  = true;    // Gunakan Area BBMA 2 (Besar) untuk Entry
input bool     Use_KGSupDem_Entry = true;      // Gunakan Area KG SupDem untuk Entry
input bool     Use_KGSupDemFibo_Entry = true;  // Gunakan Area Fibo KG SupDem untuk Entry
input bool     Use_FVG1_Entry   = true;    // Gunakan Area FVG 1 (Built-in) untuk Entry
input bool     Use_FVG2_Entry   = true;    // Gunakan Area FVG 2 (Built-in) untuk Entry
input bool     Use_FVG3_Entry   = true;    // Gunakan Area FVG 3 (Built-in) untuk Entry
input int      ZoneTolerancePips= 150;         // Batas Toleransi Jarak Garis (Fibo, VWAP, BBMA) (Pips, 100 = $1)

input string   Set_AO_Filter       = "====== KONFIRMASI AWESOME OSCILLATOR ======";
input bool     Use_AO_Filter       = true;     // Aktifkan Filter AO M5 (Langkah ke-5)
input int      AO_Fast_Period      = 4;        // Periode Fast AO
input int      AO_Slow_Period      = 24;       // Periode Slow AO
input bool     AO_UseClosedBar     = true;     // AO Pakai Candle Close (Anti Repaint) | false = Real-time

input string   Batas_Posisi     = "====== BATAS POSISI ======";
input int      MaxPosSearah     = 2;      // Maks. Posisi Searah (Averaging)
input int      MaxPosBerlawanan = 2;      // Maks. Posisi Berlawanan (Hedging)
input int      MaxDailyBuy      = 5;      // Maks. Entry BUY Per Hari (0 = Tanpa Batas)
input int      MaxDailySell     = 5;      // Maks. Entry SELL Per Hari (0 = Tanpa Batas)
input int      MagicNumber      = 888999; // Magic Number EA
input int      Slippage         = 30;     // Batasan Slippage (Pips, 100 = $1)

input string   Set_Averaging    = "====== PENGATURAN JANGKA ENTRY ======";
input int      StepDistancePips = 200;    // Jarak minimal antar entry searah (Pips)

input string   Section_Risk     = "====== MANAGEMEN RESIKO ======";
input double   RiskPercent      = 1.0;    // Persentase Risiko per trade (%)
input int      StopLossPips     = 1000;   // Default Stop Loss (Pips, 1000 = $10)
input int      TakeProfitPips   = 2000;   // Default Take Profit (Pips, 2000 = $20)
input double   FixedLotSize     = 0.0;    // Lot Tetap (0 = Pakai Persentase Risiko)
input double   MaxSpreadPips    = 50.0;   // Maks. Spread saat Entry (Pips, 50 = $0.50, 0 = Off)
input double   MaxDailyLossPct  = 3.0;    // Stop Entry Baru jika Rugi Harian >= % Balance (0 = Off)

input string   Break_Even_Point = "====== BREAK EVEN POINT ======";
input bool     UseSmartBEP      = false;  // Aktifkan Smart BEP
input double   BEPTriggerPct    = 30.0;   // Pemicu BEP (% dari TP)
input int      BEPExtraPips     = 100;    // Ekstra Pips saat BEP (Lock Profit)

input string   Trailing_Stop    = "====== TRAILING STOP ======";
input bool     UseTrailingStop  = false;  // Aktifkan Trailing Stop
input int      TrailingStartPips= 1500;   // Profit awal untuk mulai Trailing (Pips, < TP)
input int      TrailingDistance = 700;    // Jarak SL menguntit harga (Pips)
input int      TrailingStep     = 200;    // Lompatan perpindahan SL (Pips)

input string   Set_XAU_ICT      = "====== KHUSUS XAUUSD (SMC / ICT) ======";
input bool     RestrictToGold   = true;    // Hanya Jalan di Chart XAU / GOLD
input int      ServerOffsetFromNY = 7;     // Selisih Jam Server vs New York (Server GMT+2/+3 = 7)
input bool     UseKillzone      = true;    // Entry Otomatis/Semi Hanya di ICT Killzone
input bool     KZ_London        = true;    // London Killzone 02:00-05:00 NY
input bool     KZ_NewYorkAM     = true;    // New York AM Killzone 07:00-10:00 NY
input bool     KZ_LondonClose   = false;   // London Close Killzone 10:00-12:00 NY
input bool     KZ_NewYorkPM     = false;   // New York PM Killzone 13:30-16:00 NY
input int      FridayCutoffNY   = 12;      // Stop Entry Baru Jumat mulai Jam NY (0 = Off)
input bool     UsePremiumDiscount = true;  // ICT: Buy Hanya di Discount, Sell Hanya di Premium
input ENUM_PD_SOURCE PD_Source  = PD_SMC2; // Dealing Range Premium/Discount
input bool     ICT_OTEOnly      = false;   // Area SMC Fibo Hanya Level OTE (61.8 & 78.6)

input string   Set_Confirm      = "====== KONFIRMASI GABUNGAN (SKOR BERBOBOT) ======";
input double   MinConfirmPct    = 70.0;    // Skor Minimal (%) Mode Berbobot
input bool     SMC_BiasMandatory = true;   // Bias SMC Wajib Searah (ICT Top-Down)
input double   W_SMC            = 3.0;     // Bobot SMC (Struktur)
input double   W_VAPOC          = 2.0;     // Bobot Market Profile VA/POC (Value)
input double   W_VWAP           = 1.0;     // Bobot per VWAP (Volume)
input double   W_BBMA           = 1.0;     // Bobot per BBMA (Keluarga MA)
input double   W_MA             = 1.0;     // Bobot per MA Cross (Keluarga MA)

input string   Set_BuiltIn      = "====== INDIKATOR BUILT-IN (SMC & MARKET PROFILE) ======";
input ENUM_DATA_SOURCE SMC_Source = SRC_AUTO;      // Sumber Data SMC
input ENUM_TIMEFRAMES SMC1_TF   = PERIOD_M5;       // Timeframe SMC 1 (Minor) Built-in
input ENUM_TIMEFRAMES SMC2_TF   = PERIOD_H1;       // Timeframe SMC 2 (Medium) Built-in
input ENUM_TIMEFRAMES SMC3_TF   = PERIOD_H4;       // Timeframe SMC 3 (Major) Built-in
input int      SMC_SwingLen     = 3;       // Panjang Swing (Bar Kiri/Kanan)
input int      SMC_Lookback     = 300;     // Jumlah Bar Analisa SMC
input int      MinFVGPips       = 30;      // Ukuran Minimal FVG (Pips, 30 = $0.30)
input ENUM_DATA_SOURCE MP_Source = SRC_AUTO;       // Sumber Data Market Profile
input ENUM_TIMEFRAMES MP_Timeframe = PERIOD_M5;    // Timeframe Data Market Profile
input int      MP_LookbackHours = 24;      // Rentang Profil (Jam Terakhir)
input int      MP_BinPips       = 50;      // Ukuran Level Profil (Pips, 50 = $0.50)
input double   MP_ValueAreaPct  = 70.0;    // Value Area (%)
input bool     DrawBuiltIn      = true;    // Gambar Level Built-in di Chart

input string   Set_Performance  = "====== PERFORMA ======";
input int      AnalysisIntervalMs = 250;  // Interval Analisa Sinyal (ms, 0 = Setiap Tick)

input string   Zone_Colors      = "====== PENGATURAN WARNA ZONA ======";
input color    SupZoneColor     = clrBlue; // Warna Support (VA & POC)
input color    ResZoneColor     = clrRed;  // Warna Resistance (VA & POC)
input color    SnDSupColor      = C'0,32,0';
input color    SnDResColor      = C'48,0,0';
input color    OBSupColor       = C'0,32,0';
input color    OBResColor       = C'48,0,0';

input string   Note             = "====== CATATAN ======";
input string   Note2            = "Pastikan indikator pendukung ini diplot di chart:";
input string   Note3            = "1. KG Market Profile / Volume Profile (VA & POC)";
input string   Note4            = "2. KG Zigzag Line (Untuk SnD)";
input string   Note5            = "3. KG BOS CHOCH OrderBlock (Untuk OB, Trend & Fibo SMC)";
input string   Note6            = "4. KG Fibo Dinamis Button (Untuk Fibonacci)";
input string   Note7            = "5. KG SupDem Button (Untuk OB)";

// --- Trend tracking memory (VA/POC colour change mode) ---
string   g_TrackedNames[];
color    g_TrackedColors[];
datetime g_TrackedChangeTime[];

// --- Chart object name cache (one ObjectName() sweep per analysis pass) ---
string   g_Objs[];
bool     g_SMCHasObjects[4];   // KG indicator objects found per SMC prefix (SMC1..3, Scout)
bool     g_MPHasObjects = false;

// --- Built-in SMC state per tier (0 = SMC1, 1 = SMC2, 2 = SMC3) ---
struct SMCState {
    datetime barTime;
    int      trend;
    double   rangeHigh;
    double   rangeLow;
    double   obBullTop;
    double   obBullBot;
    datetime obBullTime;
    double   obBearTop;
    double   obBearBot;
    datetime obBearTime;
    double   fvgBullTop;
    double   fvgBullBot;
    datetime fvgBullTime;
    double   fvgBearTop;
    double   fvgBearBot;
    datetime fvgBearTime;
};
SMCState g_SMC[3];

// --- Built-in Market Profile state ---
datetime g_MPBarTime = 0;
double   g_MPPoc = 0, g_MPVah = 0, g_MPVal = 0, g_MPBin = 0;
int      g_ObjCount = 0;

// --- Cached daily statistics ---
int      g_DayBuy = 0;
int      g_DaySell = 0;
double   g_DayClosedPL = 0.0;

// --- Panel palette (chosen for contrast against the chart background) ---
bool     g_IsGold = false;
bool     g_LightChart = false;
bool     g_OneClickWasShown = false;   // restored on removal
color    g_ColText, g_ColHighlight, g_ColBuy, g_ColSell, g_ColNeutral, g_ColWarn, g_ColBarBG;

//--- Parameter Visual Tombol
const int baseXSize  = 120;
const int baseYSize  = 35;
const int pressXSize = 116;
const int pressYSize = 31;

struct EntryInfo {
    string Name;
    bool   IsBox;         // true = zone box (price must be inside), false = line (within tolerance)
    double DistancePips;  // 0 = IN ZONE, NO_ZONE = OUT ZONE / OFF
    int    Type;          // 1 = Buy Zone, -1 = Sell Zone, 0/2 = Netral
};

//+------------------------------------------------------------------+
//| INISIALISASI                                                     |
//+------------------------------------------------------------------+
int OnInit() {
    g_IsGold = IsGoldSymbol();
    if(RestrictToGold && !g_IsGold) {
        Alert("EA ini khusus XAUUSD. Pasang di chart XAU/GOLD, atau set RestrictToGold = false.");
        return(INIT_FAILED);
    }
    if(ServerOffsetFromNY < -12 || ServerOffsetFromNY > 14) {
        Print("ServerOffsetFromNY harus di antara -12 dan 14.");
        return(INIT_PARAMETERS_INCORRECT);
    }
    if(Use_AO_Filter && (AO_Fast_Period <= 0 || AO_Slow_Period <= AO_Fast_Period)) {
        Print("Parameter AO tidak valid: Fast harus > 0 dan lebih kecil dari Slow.");
        return(INIT_PARAMETERS_INCORRECT);
    }
    if(RiskPercent < 0 || FixedLotSize < 0 || MaxSpreadPips < 0 || MaxDailyLossPct < 0 ||
       StopLossPips < 0 || TakeProfitPips < 0) {
        Print("Parameter risiko tidak boleh bernilai negatif.");
        return(INIT_PARAMETERS_INCORRECT);
    }

    if(MinConfirmPct <= 0 || MinConfirmPct > 100 || W_SMC < 0 || W_VAPOC < 0 || W_VWAP < 0 || W_BBMA < 0 || W_MA < 0 ||
       SMC_SwingLen < 1 || SMC_SwingLen > 10 || SMC_Lookback < 50 || MP_BinPips < 1 || MP_LookbackHours < 1 ||
       MP_ValueAreaPct <= 0 || MP_ValueAreaPct > 100) {
        Print("Parameter konfirmasi / built-in tidak valid.");
        return(INIT_PARAMETERS_INCORRECT);
    }
    for(int t = 0; t < 3; t++) ResetSMCState(t);   // force recalculation after re-init
    g_MPBarTime = 0;

    ArrayResize(g_TrackedNames, 0);
    ArrayResize(g_TrackedColors, 0);
    ArrayResize(g_TrackedChangeTime, 0);

    if(HideOneClickPanel) {
        // Only record "shown" so a re-init (TF/parameter change) never overwrites it with false.
        if(ChartGetInteger(0, CHART_SHOW_ONE_CLICK)) g_OneClickWasShown = true;
        ChartSetInteger(0, CHART_SHOW_ONE_CLICK, false);
    }

    InitPanelColors();
    CreatePanel();
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
    ObjectsDeleteAll(0, "Btn_");
    ObjectsDeleteAll(0, "KGEA_");
    for(int i = 0; i < UI_LINES; i++) ObjectDelete(0, "UI_Line" + IntegerToString(i));
    ObjectDelete(0, "ProgBar_BG");
    ObjectDelete(0, "ProgBar_FG");
    // Give the MT4 One Click panel back only when the EA is really removed (not on TF/param change).
    if(HideOneClickPanel && g_OneClickWasShown && (reason == REASON_REMOVE || reason == REASON_CHARTCLOSE))
        ChartSetInteger(0, CHART_SHOW_ONE_CLICK, true);
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| HELPER DASAR                                                     |
//+------------------------------------------------------------------+
int GetKGPeriod(ENUM_KG_TIMEFRAME tf) {
    int targetMins = 0;
    switch(tf) {
        case KG_M30: targetMins = 30; break;
        case KG_1H:  targetMins = 60; break;
        case KG_2H:  targetMins = 120; break;
        case KG_4H:  targetMins = 240; break;
        case KG_8H:  targetMins = 480; break;
        case KG_1D:  targetMins = 1440; break;
        case KG_1W:  targetMins = 7200; break;     // 5 hari kerja x 24 jam
        case KG_1M:  targetMins = 28800; break;    // 20 hari kerja x 24 jam
        case KG_4M:  targetMins = 115200; break;
        case KG_1Y:  targetMins = 345600; break;
    }
    int finalPeriod = targetMins / Period();
    if(finalPeriod <= 0) finalPeriod = 1;
    return finalPeriod;
}

bool IsGoldSymbol() {
    string s = Symbol();
    StringToUpper(s);
    return (StringFind(s, "XAU") >= 0 || StringFind(s, "GOLD") >= 0);
}

// Gold: 1 pip = $0.01 on every broker (2- or 3-digit quotes). Others: classic pip.
double GetPipValue() {
    if(g_IsGold) return 0.01;
    if(Digits == 3 || Digits == 5) return Point * 10.0;
    return Point;
}

int SlippagePoints() {
    return (int)MathRound(Slippage * GetPipValue() / Point);
}

double ObjPrice(string name, int anchor) { return ObjectGetDouble(0, name, OBJPROP_PRICE, anchor); }
datetime ObjTime(string name, int anchor) { return (datetime)ObjectGetInteger(0, name, OBJPROP_TIME, anchor); }
color ObjColor(string name) { return (color)ObjectGetInteger(0, name, OBJPROP_COLOR); }

int ColorSide(color c, color supColor, color resColor) {
    if(c == supColor) return 1;
    if(c == resColor) return -1;
    return 0;
}

// Reads every chart object name once per analysis pass; all scanners iterate this cache.
void RefreshObjectCache() {
    g_ObjCount = ObjectsTotal(0, -1, -1);
    if(ArraySize(g_Objs) < g_ObjCount) ArrayResize(g_Objs, g_ObjCount, 256);
    for(int t = 0; t < 4; t++) g_SMCHasObjects[t] = false;
    g_MPHasObjects = false;
    for(int i = 0; i < g_ObjCount; i++) {
        string n = ObjectName(0, i, -1, -1);
        g_Objs[i] = n;
        for(int t = 0; t < 4; t++)
            if(!g_SMCHasObjects[t] && StringFind(n, SMCPrefix(t)) == 0) g_SMCHasObjects[t] = true;
        if(!g_MPHasObjects && (StringFind(n, "Micro_MP_LVN_Top_") >= 0 || StringFind(n, "VP_LineVAH_") >= 0 ||
                               StringFind(n, "KGVP_batas_atas_POC_") >= 0)) g_MPHasObjects = true;
    }
}

string SMCPrefix(int tier) {
    if(tier == 0) return SMC1_Prefix;
    if(tier == 1) return SMC2_Prefix;
    if(tier == 2) return SMC3_Prefix;
    return SMCScout_Prefix;
}

int TierOfPrefix(string prefix) {
    for(int t = 0; t < 4; t++) if(prefix == SMCPrefix(t)) return t;
    return -1;
}

// AUTO: KG indicator objects win when present, otherwise the built-in engine. Scout is indicator-only.
bool UseBuiltInSMC(int tier) {
    if(tier < 0 || tier > 2) return false;
    if(SMC_Source == SRC_BUILTIN) return true;
    if(SMC_Source == SRC_INDICATOR) return false;
    return !g_SMCHasObjects[tier];
}

bool UseBuiltInMP() {
    if(MP_Source == SRC_BUILTIN) return true;
    if(MP_Source == SRC_INDICATOR) return false;
    return !g_MPHasObjects;
}

bool IsObjectActive(string objName) {
    if(ObjectGetInteger(0, objName, OBJPROP_RAY_RIGHT)) return true;
    datetime endTime = (datetime)MathMax(ObjTime(objName, 0), ObjTime(objName, 1));
    return (endTime >= Time[0]);
}

// True when `num` appears in `s` without digits glued on either side
// (so "_50" or "BULL_50" match, but a timestamp like "1700050000" does not).
bool HasNumberToken(string s, string num) {
    int len = StringLen(num);
    int pos = StringFind(s, num);
    while(pos >= 0) {
        bool digitBefore = false, digitAfter = false;
        if(pos > 0) {
            ushort c = StringGetCharacter(s, pos - 1);
            digitBefore = (c >= '0' && c <= '9');
        }
        if(pos + len < StringLen(s)) {
            ushort c2 = StringGetCharacter(s, pos + len);
            digitAfter = (c2 >= '0' && c2 <= '9');
        }
        if(!digitBefore && !digitAfter) return true;
        pos = StringFind(s, num, pos + 1);
    }
    return false;
}

bool IsSMCFiboLevel(string name) {
    if(StringFind(name, "_OB_") >= 0 || StringFind(name, "_CH_") >= 0 || StringFind(name, "_BOS_") >= 0) return false;
    if(ICT_OTEOnly) return HasNumberToken(name, "61") || HasNumberToken(name, "78");   // ICT OTE band
    return HasNumberToken(name, "50") || HasNumberToken(name, "61") ||
           HasNumberToken(name, "78") || HasNumberToken(name, "100");
}

// Updates the nearest-zone result with one box. side: 1 = support, -1 = resistance, 0 = neutral.
void UpdateZone(double price, double p1, double p2, int side, double &minDist, int &status) {
    double top = MathMax(p1, p2);
    double bot = MathMin(p1, p2);
    double dist = NO_ZONE;
    if(side == 1)       dist = MathAbs(price - top) / GetPipValue();
    else if(side == -1) dist = MathAbs(price - bot) / GetPipValue();
    if(price <= top && price >= bot) dist = 0;
    if(dist < minDist) { minDist = dist; status = (side == 0) ? 2 : side; }
}

void SetArea(EntryInfo &a, string name, bool isBox, double dist, int type) {
    a.Name = name;
    a.IsBox = isBox;
    a.DistancePips = dist;
    a.Type = type;
}

bool IsInZone(const EntryInfo &a) {
    if(a.DistancePips >= NO_ZONE) return false;
    return a.IsBox ? (a.DistancePips == 0) : (a.DistancePips <= ZoneTolerancePips);
}

void AddVote(int &trendList[], int slot, int vote, double weight, double &total, double &bull, double &bear) {
    trendList[slot] = vote;
    total += weight;
    if(vote == 1) bull += weight;
    else if(vote == -1) bear += weight;
}

double GetFibo50Price(string prefix, int trendDirection) {
    int tier = TierOfPrefix(prefix);
    if(UseBuiltInSMC(tier)) return SMCEquilibrium(tier);
    string objName = "";
    if(trendDirection == 1) objName = prefix + "FIBO_EA_BULL_50";
    else if(trendDirection == -1) objName = prefix + "FIBO_EA_BEAR_50";
    if(objName != "" && ObjectFind(0, objName) >= 0) return ObjPrice(objName, 0);
    return 0.0;
}

// ICT killzones are defined in New York time; nyTime = server time - ServerOffsetFromNY.
bool InKillzone(datetime nyTime, string &name) {
    int m = TimeHour(nyTime) * 60 + TimeMinute(nyTime);
    if(KZ_London      && m >= 120 && m < 300) { name = "London KZ";       return true; }
    if(KZ_NewYorkAM   && m >= 420 && m < 600) { name = "NY AM KZ";        return true; }
    if(KZ_LondonClose && m >= 600 && m < 720) { name = "London Close KZ"; return true; }
    if(KZ_NewYorkPM   && m >= 810 && m < 960) { name = "NY PM KZ";        return true; }
    name = "Diluar Killzone";
    return false;
}

string PDPrefix() {
    if(PD_Source == PD_SMC1) return SMC1_Prefix;
    if(PD_Source == PD_SMC3) return SMC3_Prefix;
    return SMC2_Prefix;
}

// ICT premium/discount of the selected SMC dealing range (its Fibo 50% = equilibrium).
// Returns false only when price is on the wrong side; a missing Fibo never blocks.
bool PDAllows(int dir, double price, string &text) {
    double eq = GetFibo50Price(PDPrefix(), dir);
    if(eq <= 0) { text = "PD: n/a"; return true; }
    if(dir == 1) {
        if(price <= eq) { text = "Discount"; return true; }
        text = "Premium (tunggu Discount)"; return false;
    }
    if(price >= eq) { text = "Premium"; return true; }
    text = "Discount (tunggu Premium)"; return false;
}

bool IsAnalysisDue() {
    static uint lastRun = 0;
    static datetime lastBar = 0;
    if(IsTesting() || AnalysisIntervalMs <= 0) return true;
    uint now = GetTickCount();
    if(Time[0] != lastBar || now - lastRun >= (uint)AnalysisIntervalMs) {
        lastBar = Time[0];
        lastRun = now;
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| FUNGSI UTAMA (ONTICK)                                            |
//+------------------------------------------------------------------+
void OnTick() {
    // --- Housekeeping: once per server second is enough ---
    static datetime lastHousekeeping = 0;
    if(TimeCurrent() != lastHousekeeping) {
        lastHousekeeping = TimeCurrent();
        if(CleanTradeLines) CleanHistoryObjects();
        if(UseHiddenSLTP) CleanupVirtualSLTP();
    }

    // --- Position protection runs on every tick ---
    if(UseHiddenSLTP) CheckHiddenSLTP();
    ApplyDefaultProtection();
    SmartBEPLogic();
    TrailingStopLogic();

    // --- Signal analysis is throttled (heavy chart-object scanning) ---
    if(IsAnalysisDue()) RunAnalysis();
}

void RunAnalysis() {
    double price = Bid;
    double pip = GetPipValue();

    RefreshObjectCache();
    UpdateBuiltInEngines();
    if(UseTrend_VAPOC && TrendLogicMode == TREND_COLOR_CHANGE && !UseBuiltInMP()) TrackObjectColorChanges();

    int activeSMCCount = (UseTrend_SMC1 ? 1 : 0) + (UseTrend_SMC2 ? 1 : 0) + (UseTrend_SMC3 ? 1 : 0);
    bool smcMatrixActive = (Use_SMC_Matrix && activeSMCCount >= 2);

    // ====================================================================
    // TAHAP 0: NILAI INDIKATOR (dihitung sekali per analisa)
    // ====================================================================
    double vwap1 = 0, vwap2 = 0;
    double ma1 = 0, up1 = 0, dn1 = 0;
    double ma2 = 0, up2 = 0, dn2 = 0;
    int tVWAP1 = 0, tVWAP2 = 0, tBB1 = 0, tBB2 = 0;
    bool bbFilter = (smcMatrixActive && Use_BBMA_Filter);

    if(Use_VWAP1_Entry || UseTrend_VWAP1) tVWAP1 = GetDailyVWAPTrend(price, vwap1);
    if(Use_VWAP2_Entry || UseTrend_VWAP2) tVWAP2 = GetVWAP2DaysTrend(vwap2);
    if(Use_BBMA1_Entry || UseTrend_BBMA1 || bbFilter) tBB1 = GetKGBBMATrend(price, ma1, up1, dn1, BBMA1_Timeframe);
    if(Use_BBMA2_Entry || UseTrend_BBMA2 || bbFilter) tBB2 = GetKGBBMATrend(price, ma2, up2, dn2, BBMA2_Timeframe);

    // ====================================================================
    // TAHAP 1: PEMINDAIAN SELURUH AREA ENTRY (urutan = ENUM_PRIMARY_AREA - 1)
    // ====================================================================
    EntryInfo list[AREA_COUNT];
    double d;
    int t;

    d = NO_ZONE; t = 0; if(Use_VA_Entry)        t = GetValueAreaStatus(price, d);               SetArea(list[0],  "Value Area", true, d, t);
    d = NO_ZONE; t = 0; if(Use_POC_Entry)       t = GetPOCStatus(price, d);                     SetArea(list[1],  "POC", true, d, t);
    d = NO_ZONE; t = 0; if(Use_SnD_Entry)       t = GetSnDStatus(price, d);                     SetArea(list[2],  "SnD Zone", true, d, t);
    d = NO_ZONE; t = 0; if(Use_OB1_Entry)       t = GetOBStatus(price, d, SMC1_Prefix);         SetArea(list[3],  "Order Block 1", true, d, t);
    d = NO_ZONE; t = 0; if(Use_OB2_Entry)       t = GetOBStatus(price, d, SMC2_Prefix);         SetArea(list[4],  "Order Block 2", true, d, t);
    d = NO_ZONE; t = 0; if(Use_OB3_Entry)       t = GetOBStatus(price, d, SMC3_Prefix);         SetArea(list[5],  "Order Block 3 (Major)", true, d, t);
    d = NO_ZONE; t = 0; if(Use_OBScout_Entry)   t = GetOBStatus(price, d, SMCScout_Prefix);     SetArea(list[6],  "Order Block Scout", true, d, t);
    d = NO_ZONE; t = 0; if(Use_Fibo1_Entry)     t = GetSMCFiboStatus(price, d, SMC1_Prefix);    SetArea(list[7],  "SMC Fibo 1", false, d, t);
    d = NO_ZONE; t = 0; if(Use_Fibo2_Entry)     t = GetSMCFiboStatus(price, d, SMC2_Prefix);    SetArea(list[8],  "SMC Fibo 2", false, d, t);
    d = NO_ZONE; t = 0; if(Use_Fibo3_Entry)     t = GetSMCFiboStatus(price, d, SMC3_Prefix);    SetArea(list[9],  "SMC Fibo 3 (Major)", false, d, t);
    d = NO_ZONE; t = 0; if(Use_KGFibo_Entry)    t = GetKGFiboStatus(price, d);                  SetArea(list[10], "KG Fibo", false, d, t);
    d = NO_ZONE; t = 0; if(Use_FiboScout_Entry) t = GetSMCFiboStatus(price, d, SMCScout_Prefix);SetArea(list[11], "SMC Fibo Scout", false, d, t);

    d = NO_ZONE; t = 0;
    if(Use_VWAP1_Entry && vwap1 > 0) { d = MathAbs(price - vwap1) / pip; t = (price >= vwap1) ? 1 : -1; }
    SetArea(list[12], "VWAP 1", false, d, t);

    d = NO_ZONE; t = 0;
    if(Use_VWAP2_Entry && vwap2 > 0) { d = MathAbs(price - vwap2) / pip; t = (price >= vwap2) ? 1 : -1; }
    SetArea(list[13], "VWAP 2", false, d, t);

    d = NO_ZONE; t = 0; if(Use_BBMA1_Entry && ma1 > 0) NearestBandLine(price, ma1, up1, dn1, d, t);
    SetArea(list[14], "BB SD1 (1)", false, d, t);

    d = NO_ZONE; t = 0; if(Use_BBMA2_Entry && ma2 > 0) NearestBandLine(price, ma2, up2, dn2, d, t);
    SetArea(list[15], "BB SD1 (2)", false, d, t);

    d = NO_ZONE; t = 0; if(Use_KGSupDem_Entry)     t = GetKGSupDemStatus(price, d);     SetArea(list[16], "KG SupDem", true, d, t);
    d = NO_ZONE; t = 0; if(Use_KGSupDemFibo_Entry) t = GetKGSupDemFiboStatus(price, d); SetArea(list[17], "KG SupDem Fibo", false, d, t);
    d = NO_ZONE; t = 0; if(Use_FVG1_Entry) t = GetFVGStatus(price, d, 0); SetArea(list[18], "FVG 1 " + TFName(SMCTimeframe(0)), true, d, t);
    d = NO_ZONE; t = 0; if(Use_FVG2_Entry) t = GetFVGStatus(price, d, 1); SetArea(list[19], "FVG 2 " + TFName(SMCTimeframe(1)), true, d, t);
    d = NO_ZONE; t = 0; if(Use_FVG3_Entry) t = GetFVGStatus(price, d, 2); SetArea(list[20], "FVG 3 " + TFName(SMCTimeframe(2)), true, d, t);

    // ====================================================================
    // TAHAP 2: KALKULASI TREN & SMC MATRIX
    // ====================================================================
    // Weighted vote: structure (SMC) > value (Market Profile) > volume (VWAP) > MA family (BBMA, MA Cross).
    double totalTools = 0, bullScore = 0, bearScore = 0;
    int trendList[TREND_SLOTS];
    ArrayInitialize(trendList, -99);
    string smcFilterText = "SMC Matrix: OFF";
    int smcBias = 0;

    if(smcMatrixActive) {
        int sMin = UseTrend_SMC1 ? GetRealtimeSMCTrend(SMC1_Prefix) : 0;
        int sMid = UseTrend_SMC2 ? GetRealtimeSMCTrend(SMC2_Prefix) : 0;
        int sMaj = UseTrend_SMC3 ? GetRealtimeSMCTrend(SMC3_Prefix) : 0;
        smcBias = EvaluateSMCMatrix(price, sMin, sMid, sMaj, up1, dn1, up2, dn2, smcFilterText);
        AddVote(trendList, 1, smcBias, W_SMC, totalTools, bullScore, bearScore);
    } else {
        int s1 = 0, s2 = 0, s3 = 0;
        if(UseTrend_SMC1) { s1 = GetRealtimeSMCTrend(SMC1_Prefix); AddVote(trendList, 1, s1, W_SMC, totalTools, bullScore, bearScore); }
        if(UseTrend_SMC2) { s2 = GetRealtimeSMCTrend(SMC2_Prefix); AddVote(trendList, 2, s2, W_SMC, totalTools, bullScore, bearScore); }
        if(UseTrend_SMC3) { s3 = GetRealtimeSMCTrend(SMC3_Prefix); AddVote(trendList, 9, s3, W_SMC, totalTools, bullScore, bearScore); }
        // Bias = highest active timeframe (ICT top-down)
        smcBias = UseTrend_SMC3 ? s3 : (UseTrend_SMC2 ? s2 : s1);
    }

    if(UseTrend_BBMA1) AddVote(trendList, 5, tBB1, W_BBMA, totalTools, bullScore, bearScore);
    if(UseTrend_BBMA2) AddVote(trendList, 6, tBB2, W_BBMA, totalTools, bullScore, bearScore);
    if(UseTrend_VAPOC) AddVote(trendList, 0, GetRealtimeVAPOCTrendColor(price), W_VAPOC, totalTools, bullScore, bearScore);
    if(UseTrend_VWAP1) AddVote(trendList, 3, tVWAP1, W_VWAP, totalTools, bullScore, bearScore);
    if(UseTrend_VWAP2) AddVote(trendList, 4, tVWAP2, W_VWAP, totalTools, bullScore, bearScore);
    if(UseTrend_EMA)   AddVote(trendList, 7, GetEMACrossTrend(EMA_Fast_Period, EMA_Slow_Period), W_MA, totalTools, bullScore, bearScore);
    if(UseTrend_EMA2)  AddVote(trendList, 8, GetEMACrossTrend(EMA2_Fast_Period, EMA2_Slow_Period), W_MA, totalTools, bullScore, bearScore);

    // ====================================================================
    // TAHAP 3: PERSENTASE & TREN FINAL
    // ====================================================================
    double bullPercent = 0.0, bearPercent = 0.0;
    if(totalTools > 0) {
        bullPercent = (bullScore / totalTools) * 100.0;
        bearPercent = (bearScore / totalTools) * 100.0;
    }

    // Strict = 100% searah. Loose = strictly above 50%. Weighted = score >= MinConfirmPct.
    bool bullValid, bearValid;
    if(TrendValidityMode == TREND_STRICT)     { bullValid = (bullPercent >= 99.999); bearValid = (bearPercent >= 99.999); }
    else if(TrendValidityMode == TREND_LOOSE) { bullValid = (bullPercent > 50.0);    bearValid = (bearPercent > 50.0); }
    else                                      { bullValid = (bullPercent >= MinConfirmPct); bearValid = (bearPercent >= MinConfirmPct); }

    // ICT top-down: the SMC bias must agree with the score.
    bool smcInUse = (UseTrend_SMC1 || UseTrend_SMC2 || UseTrend_SMC3);
    bool biasBlocked = false;
    if(SMC_BiasMandatory && smcInUse) {
        if(bullValid && smcBias != 1)  { bullValid = false; biasBlocked = true; }
        if(bearValid && smcBias != -1) { bearValid = false; biasBlocked = true; }
    }

    int finalTrend = 0;
    string trendText = "";

    if(totalTools <= 0) {
        trendText = "SEMUA ALAT TREND OFF";
    } else if(bullValid) {
        finalTrend = 1;
        trendText = DoubleToStr(bullPercent, 0) + "% BUYERS";
    } else if(bearValid) {
        finalTrend = -1;
        trendText = DoubleToStr(bearPercent, 0) + "% SELLERS";
    } else {
        trendText = "NETRAL (" + DoubleToStr(MathMax(bullPercent, bearPercent), 0) + "%" + (biasBlocked ? ", BIAS SMC BEDA)" : ")");
    }

    if(CloseOppositeTrend && finalTrend != 0) CheckTrendReversalClose(finalTrend);

    // ====================================================================
    // TAHAP 4: VALIDASI CONFLUENCE AREA ENTRY
    // ====================================================================
    int primaryIdx = (int)PrimaryArea - 1;   // -1 = tanpa area utama
    int countBuy = 0, countSell = 0;
    bool primaryBuyFound = false, primarySellFound = false;

    for(int i = 0; i < AREA_COUNT; i++) {
        if(!IsInZone(list[i])) continue;
        if(list[i].Type == 1) {
            countBuy++;
            if(i == primaryIdx) primaryBuyFound = true;
        } else if(list[i].Type == -1) {
            countSell++;
            if(i == primaryIdx) primarySellFound = true;
        }
    }

    int reqAreas = (EntryValidationMode == ENTRY_MIN_2) ? 2 : 1;
    bool validAreaForBuy = (countBuy >= reqAreas);
    bool validAreaForSell = (countSell >= reqAreas);
    if(EntryValidationMode == ENTRY_MIN_2 && primaryIdx >= 0) {
        if(!primaryBuyFound) validAreaForBuy = false;
        if(!primarySellFound) validAreaForSell = false;
    }

    RefreshDailyStats();
    bool isBuyLimitReached = (MaxDailyBuy > 0 && g_DayBuy >= MaxDailyBuy);
    bool isSellLimitReached = (MaxDailySell > 0 && g_DaySell >= MaxDailySell);

    if(isBuyLimitReached && isSellLimitReached) trendText += " (LIMIT HARIAN MAX)";
    else if(isBuyLimitReached)                  trendText += " (LIMIT BUY MAX)";
    else if(isSellLimitReached)                 trendText += " (LIMIT SELL MAX)";

    // --- Proteksi akun: rugi harian & spread ---
    bool dailyLossHit = IsDailyLossHit();
    bool spreadTooHigh = (MaxSpreadPips > 0 && (Ask - Bid) / pip > MaxSpreadPips);
    if(dailyLossHit)  trendText += " (STOP RUGI HARIAN)";
    if(spreadTooHigh) trendText += " (SPREAD TINGGI)";

    datetime nyTime = TimeCurrent() - ServerOffsetFromNY * 3600;
    bool fridayStop = (FridayCutoffNY > 0 && TimeDayOfWeek(nyTime) == 5 && TimeHour(nyTime) >= FridayCutoffNY);
    if(fridayStop) trendText += " (STOP JUMAT)";
    bool tradeBlocked = (dailyLossHit || spreadTooHigh || fridayStop);

    bool finalSignalBuy  = (finalTrend == 1 && validAreaForBuy && !isBuyLimitReached);
    bool finalSignalSell = (finalTrend == -1 && validAreaForSell && !isSellLimitReached);

    // --- ICT strategy filters: shape the signal (MANUAL clicks stay free) ---
    string ictText = "";
    bool ictOk = true;
    if(UseKillzone) {
        string kzName = "";
        bool inKZ = InKillzone(nyTime, kzName);
        ictText = kzName;
        if(!inKZ) { finalSignalBuy = false; finalSignalSell = false; ictOk = false; }
    }
    if(UsePremiumDiscount && finalTrend != 0) {
        string pdText = "";
        bool pdOk = PDAllows(finalTrend, price, pdText);
        ictText += (ictText == "" ? "" : " | ") + pdText;
        if(!pdOk) { finalSignalBuy = false; finalSignalSell = false; ictOk = false; }
    }

    // ====================================================================
    // TAHAP 5: FILTER AWESOME OSCILLATOR
    // Closed-bar mode compares bar 1 vs bar 2 (no repaint); real-time mode bar 0 vs bar 1.
    // ====================================================================
    if(Use_AO_Filter && (finalSignalBuy || finalSignalSell)) {
        int shift = AO_UseClosedBar ? 1 : 0;
        double aoNow = GetCustomAO(shift);
        double aoPrev = GetCustomAO(shift + 1);
        if(finalSignalBuy && !(aoNow < 0 && aoNow > aoPrev)) finalSignalBuy = false;     // Sellers melemah
        if(finalSignalSell && !(aoNow > 0 && aoNow < aoPrev)) finalSignalSell = false;   // Buyers melemah
    }

    // ====================================================================
    // TAHAP 6: UI, ALERT & EKSEKUSI
    // ====================================================================
    SortByDistance(list);

    bool canBuyUI  = !tradeBlocked && !isBuyLimitReached  && (TradingMode == MODE_MANUAL || finalSignalBuy);
    bool canSellUI = !tradeBlocked && !isSellLimitReached && (TradingMode == MODE_MANUAL || finalSignalSell);
    UpdatePanel(bullPercent, bearPercent, trendText, smcFilterText, ictText, ictOk, SourceText(), list, canBuyUI, canSellUI, trendList, smcMatrixActive, finalTrend);

    static bool buyAlertLock = false;
    static bool sellAlertLock = false;
    if(finalSignalBuy) {
        if(!buyAlertLock && !IsTesting()) {
            Alert(Symbol(), ": SIGNAL BUY VALID! Trend Bullish & Area Confluence Terpenuhi!");
            PlaySound("alert.wav");
        }
        buyAlertLock = true;
    } else buyAlertLock = false;

    if(finalSignalSell) {
        if(!sellAlertLock && !IsTesting()) {
            Alert(Symbol(), ": SIGNAL SELL VALID! Trend Bearish & Area Confluence Terpenuhi!");
            PlaySound("alert.wav");
        }
        sellAlertLock = true;
    } else sellAlertLock = false;

    static datetime lastAttemptTime = 0;
    if(TradingMode == MODE_AUTO && !tradeBlocked && TimeCurrent() - lastAttemptTime >= 5) {
        if(finalSignalBuy && CanOpenBuy()) {
            OpenMarketOrder(OP_BUY);
            lastAttemptTime = TimeCurrent();
        } else if(finalSignalSell && CanOpenSell()) {
            OpenMarketOrder(OP_SELL);
            lastAttemptTime = TimeCurrent();
        }
    }
}

void SortByDistance(EntryInfo &list[]) {
    for(int i = 1; i < AREA_COUNT; i++) {
        EntryInfo key = list[i];
        int j = i - 1;
        while(j >= 0 && list[j].DistancePips > key.DistancePips) {
            list[j + 1] = list[j];
            j--;
        }
        list[j + 1] = key;
    }
}

// ====================================================================
// --- SMC MATRIX ---
// ====================================================================
// Higher timeframe (higherDir) disagrees with the lower one: decide using the
// higher leg's Fibo 50% (premium/discount) and the optional BB sideways filter.
int ResolveSMCConflict(int higherDir, string fiboPrefix, double bbUp, double bbDn, double price,
                       string pullName, string higherName, string &text) {
    double fibo50 = GetFibo50Price(fiboPrefix, higherDir);

    if(higherDir == 1) {
        bool sidewaysUp = (Use_BBMA_Filter && bbUp > 0 && price < bbUp);
        if(fibo50 > 0 && price > fibo50) {
            if(sidewaysUp) { text = "SMC: SELL (" + pullName + " Pullback in Prem)"; return -1; }
            text = "SMC: BUY (Momentum " + higherName + " Kuat)"; return 1;
        }
        if(Aggressive_POI_Entry) { text = "SMC: BUY (" + higherName + " UP in Disc)"; return 1; }
        text = "SMC: NETRAL (Wait " + pullName + " UP)"; return 0;
    }

    bool sidewaysDn = (Use_BBMA_Filter && bbDn > 0 && price > bbDn);
    if(fibo50 > 0 && price < fibo50) {
        if(sidewaysDn) { text = "SMC: BUY (" + pullName + " Pullback in Disc)"; return 1; }
        text = "SMC: SELL (Momentum " + higherName + " Kuat)"; return -1;
    }
    if(Aggressive_POI_Entry) { text = "SMC: SELL (" + higherName + " DN in Prem)"; return -1; }
    text = "SMC: NETRAL (Wait " + pullName + " DN)"; return 0;
}

int EvalSMCPair(int hi, int lo, string hiName, string loName, string fiboPrefix,
                double bbUp, double bbDn, double price, string syncLabel, string &text) {
    if(hi != 0 && hi == lo) {
        text = ((hi == 1) ? "SMC: BUY (2-Tier Sync: " : "SMC: SELL (2-Tier Sync: ") + syncLabel + ")";
        return hi;
    }
    if(hi != 0 && lo == -hi) return ResolveSMCConflict(hi, fiboPrefix, bbUp, bbDn, price, loName, hiName, text);
    return 0;
}

int EvaluateSMCMatrix(double price, int tMin, int tMid, int tMaj,
                      double up1, double dn1, double up2, double dn2, string &text) {
    text = "SMC: NETRAL";

    if(UseTrend_SMC1 && UseTrend_SMC2 && UseTrend_SMC3) {
        if(tMaj != 0 && tMaj == tMid && tMid == tMin) {
            text = (tMaj == 1) ? "SMC: BUY (3-Tier Sync)" : "SMC: SELL (3-Tier Sync)";
            return tMaj;
        }
        // Koreksi minor: Major & Medium searah, Minor berlawanan
        if(tMaj != 0 && tMaj == tMid && tMin == -tMid)
            return ResolveSMCConflict(tMid, SMC2_Prefix, up1, dn1, price, "Minor", "Medium", text);
        // Koreksi dalam: Medium berlawanan dengan Major
        if(tMaj != 0 && tMid == -tMaj)
            return ResolveSMCConflict(tMaj, SMC3_Prefix, up2, dn2, price, "Medium", "Major", text);
        return 0;
    }

    if(UseTrend_SMC1 && UseTrend_SMC2)
        return EvalSMCPair(tMid, tMin, "Medium", "Minor", SMC2_Prefix, up1, dn1, price, "Mid+Min", text);
    if(UseTrend_SMC2 && UseTrend_SMC3)
        return EvalSMCPair(tMaj, tMid, "Major", "Medium", SMC3_Prefix, up2, dn2, price, "Maj+Mid", text);
    return EvalSMCPair(tMaj, tMin, "Major", "Minor", SMC3_Prefix, up2, dn2, price, "Maj+Min", text);
}

// ====================================================================
// --- BUILT-IN SMC ENGINE (closed bars only, recalculated once per bar of its timeframe) ---
// Swing = fractal with SMC_SwingLen bars each side. A close beyond the last unbroken swing
// is a BOS/CHoCH and sets the trend, the dealing range (leg low/high) and the Order Block
// (last opposite candle of the leg). Fair value gaps are 3-candle imbalances.
// ====================================================================
int SMCTimeframe(int tier) {
    int tf = SMC1_TF;
    if(tier == 1) tf = SMC2_TF;
    else if(tier == 2) tf = SMC3_TF;
    return (tf == PERIOD_CURRENT) ? Period() : tf;
}

string TFName(int tf) {
    switch(tf) {
        case PERIOD_M1:  return "M1";
        case PERIOD_M5:  return "M5";
        case PERIOD_M15: return "M15";
        case PERIOD_M30: return "M30";
        case PERIOD_H1:  return "H1";
        case PERIOD_H4:  return "H4";
        case PERIOD_D1:  return "D1";
        case PERIOD_W1:  return "W1";
        case PERIOD_MN1: return "MN";
    }
    return IntegerToString(tf);
}

bool IsSwingHigh(int tf, int p, int k) {
    double h = iHigh(Symbol(), tf, p);
    for(int j = 1; j <= k; j++)
        if(iHigh(Symbol(), tf, p + j) >= h || iHigh(Symbol(), tf, p - j) > h) return false;
    return true;
}

bool IsSwingLow(int tf, int p, int k) {
    double l = iLow(Symbol(), tf, p);
    for(int j = 1; j <= k; j++)
        if(iLow(Symbol(), tf, p + j) <= l || iLow(Symbol(), tf, p - j) < l) return false;
    return true;
}

void CalcSMC(int tier) {
    int tf = SMCTimeframe(tier);
    datetime t0 = iTime(Symbol(), tf, 0);
    if(t0 == 0 || t0 == g_SMC[tier].barTime) return;

    int k = SMC_SwingLen;
    int bars = iBars(Symbol(), tf);
    int n = (int)MathMin(SMC_Lookback, bars - 2 * k - 3);
    if(n < 4 * k + 3) return;   // not enough history yet; retried next pass

    int trend = 0;
    double swingHigh = 0, swingLow = 0;
    int swingHighBar = -1, swingLowBar = -1;
    bool highLive = false, lowLive = false;
    double rangeHigh = 0, rangeLow = 0;
    double obBT = 0, obBB = 0, obST = 0, obSB = 0;
    datetime obBTime = 0, obSTime = 0;
    double fBT = 0, fBB = 0, fST = 0, fSB = 0;
    datetime fBTime = 0, fSTime = 0;
    double minGap = MinFVGPips * GetPipValue();

    for(int s = n; s >= 1; s--) {
        double hi = iHigh(Symbol(), tf, s);
        double lo = iLow(Symbol(), tf, s);
        double cl = iClose(Symbol(), tf, s);

        // 1. Swing at p = s + k is now confirmed (k newer bars exist)
        int p = s + k;
        if(IsSwingHigh(tf, p, k)) { swingHigh = iHigh(Symbol(), tf, p); swingHighBar = p; highLive = true; }
        if(IsSwingLow(tf, p, k))  { swingLow = iLow(Symbol(), tf, p);   swingLowBar = p;  lowLive = true; }

        // 2. Order Blocks die when closed through; FVGs die when fully filled
        if(obBT > 0 && cl < obBB) { obBT = 0; obBB = 0; obBTime = 0; }
        if(obST > 0 && cl > obST) { obST = 0; obSB = 0; obSTime = 0; }
        if(fBT > 0 && lo <= fBB)  { fBT = 0; fBB = 0; fBTime = 0; }
        if(fST > 0 && hi >= fST)  { fST = 0; fSB = 0; fSTime = 0; }

        // 3. Break of structure / change of character (candle close beyond the swing)
        if(highLive && cl > swingHigh) {
            highLive = false;
            trend = 1;
            int lim = (swingLowBar > s) ? swingLowBar : (int)MathMin(s + 20, bars - 1);
            rangeHigh = hi;
            rangeLow = lo;
            for(int j = s; j <= lim; j++) rangeLow = MathMin(rangeLow, iLow(Symbol(), tf, j));
            for(int m = s; m <= lim; m++) {
                if(iClose(Symbol(), tf, m) < iOpen(Symbol(), tf, m)) {   // last down candle of the leg
                    obBT = iHigh(Symbol(), tf, m); obBB = iLow(Symbol(), tf, m); obBTime = iTime(Symbol(), tf, m);
                    break;
                }
            }
        } else if(lowLive && cl < swingLow) {
            lowLive = false;
            trend = -1;
            int lim2 = (swingHighBar > s) ? swingHighBar : (int)MathMin(s + 20, bars - 1);
            rangeLow = lo;
            rangeHigh = hi;
            for(int j2 = s; j2 <= lim2; j2++) rangeHigh = MathMax(rangeHigh, iHigh(Symbol(), tf, j2));
            for(int m2 = s; m2 <= lim2; m2++) {
                if(iClose(Symbol(), tf, m2) > iOpen(Symbol(), tf, m2)) {  // last up candle of the leg
                    obST = iHigh(Symbol(), tf, m2); obSB = iLow(Symbol(), tf, m2); obSTime = iTime(Symbol(), tf, m2);
                    break;
                }
            }
        }

        // 4. Dealing range follows the trend extreme
        if(trend == 1 && hi > rangeHigh) rangeHigh = hi;
        if(trend == -1 && lo < rangeLow) rangeLow = lo;

        // 5. New fair value gaps (candles s+2, s+1, s)
        double h2 = iHigh(Symbol(), tf, s + 2);
        double l2 = iLow(Symbol(), tf, s + 2);
        if(lo - h2 >= minGap) { fBT = lo; fBB = h2; fBTime = iTime(Symbol(), tf, s + 2); }
        if(l2 - hi >= minGap) { fST = l2; fSB = hi; fSTime = iTime(Symbol(), tf, s + 2); }
    }

    g_SMC[tier].trend = trend;
    g_SMC[tier].rangeHigh = rangeHigh;
    g_SMC[tier].rangeLow = rangeLow;
    g_SMC[tier].obBullTop = obBT;  g_SMC[tier].obBullBot = obBB;  g_SMC[tier].obBullTime = obBTime;
    g_SMC[tier].obBearTop = obST;  g_SMC[tier].obBearBot = obSB;  g_SMC[tier].obBearTime = obSTime;
    g_SMC[tier].fvgBullTop = fBT;  g_SMC[tier].fvgBullBot = fBB;  g_SMC[tier].fvgBullTime = fBTime;
    g_SMC[tier].fvgBearTop = fST;  g_SMC[tier].fvgBearBot = fSB;  g_SMC[tier].fvgBearTime = fSTime;
    g_SMC[tier].barTime = t0;
}

void ResetSMCState(int tier) {
    g_SMC[tier].barTime = 0;
    g_SMC[tier].trend = 0;
    g_SMC[tier].rangeHigh = 0;   g_SMC[tier].rangeLow = 0;
    g_SMC[tier].obBullTop = 0;   g_SMC[tier].obBullBot = 0;   g_SMC[tier].obBullTime = 0;
    g_SMC[tier].obBearTop = 0;   g_SMC[tier].obBearBot = 0;   g_SMC[tier].obBearTime = 0;
    g_SMC[tier].fvgBullTop = 0;  g_SMC[tier].fvgBullBot = 0;  g_SMC[tier].fvgBullTime = 0;
    g_SMC[tier].fvgBearTop = 0;  g_SMC[tier].fvgBearBot = 0;  g_SMC[tier].fvgBearTime = 0;
}

double SMCEquilibrium(int tier) {
    if(tier < 0 || tier > 2) return 0.0;
    double hi = g_SMC[tier].rangeHigh, lo = g_SMC[tier].rangeLow;
    if(g_SMC[tier].trend == 0 || lo <= 0 || hi <= lo) return 0.0;
    return (hi + lo) / 2.0;
}

int GetFVGStatus(double price, double &outDist, int tier) {
    double minDist = NO_ZONE; int status = 0;
    if(g_SMC[tier].fvgBullTop > 0) UpdateZone(price, g_SMC[tier].fvgBullTop, g_SMC[tier].fvgBullBot, 1, minDist, status);
    if(g_SMC[tier].fvgBearTop > 0) UpdateZone(price, g_SMC[tier].fvgBearTop, g_SMC[tier].fvgBearBot, -1, minDist, status);
    outDist = minDist;
    return status;
}

// ====================================================================
// --- BUILT-IN MARKET PROFILE (tick-volume profile of the last MP_LookbackHours) ---
// ====================================================================
void CalcMarketProfile() {
    int tf = MP_Timeframe;
    if(tf == PERIOD_CURRENT) tf = Period();
    datetime t0 = iTime(Symbol(), tf, 0);
    if(t0 == 0 || t0 == g_MPBarTime) return;

    int nb = (int)MathMin(MP_LookbackHours * 60 / tf, iBars(Symbol(), tf) - 2);
    if(nb < 10) return;

    double hi = iHigh(Symbol(), tf, iHighest(Symbol(), tf, MODE_HIGH, nb, 1));
    double lo = iLow(Symbol(), tf, iLowest(Symbol(), tf, MODE_LOW, nb, 1));
    double bin = MP_BinPips * GetPipValue();
    if(hi <= lo || bin <= 0) return;
    if((hi - lo) / bin > 2000) bin = (hi - lo) / 2000.0;
    int nbins = (int)((hi - lo) / bin) + 1;
    if(nbins < 3) return;

    double vol[];
    ArrayResize(vol, nbins);
    ArrayInitialize(vol, 0.0);
    double total = 0;
    for(int s = 1; s <= nb; s++) {
        double v = (double)iVolume(Symbol(), tf, s);
        if(v <= 0) v = 1;
        int a = (int)MathMax(0, MathMin(nbins - 1, (iLow(Symbol(), tf, s) - lo) / bin));
        int b = (int)MathMax(0, MathMin(nbins - 1, (iHigh(Symbol(), tf, s) - lo) / bin));
        double share = v / (b - a + 1);
        for(int x = a; x <= b; x++) vol[x] += share;
        total += v;
    }

    int poc = ArrayMaximum(vol);
    int loI = poc, hiI = poc;
    double acc = vol[poc];
    double target = total * MP_ValueAreaPct / 100.0;
    while(acc < target) {
        double up = (hiI + 1 < nbins) ? vol[hiI + 1] : -1.0;
        double dn = (loI - 1 >= 0) ? vol[loI - 1] : -1.0;
        if(up < 0 && dn < 0) break;
        if(up >= dn) { hiI++; acc += up; }
        else         { loI--; acc += dn; }
    }

    g_MPBin = bin;
    g_MPPoc = lo + (poc + 0.5) * bin;
    g_MPVah = lo + (hiI + 1) * bin;
    g_MPVal = lo + loI * bin;
    g_MPBarTime = t0;
}

void UpdateBuiltInEngines() {
    for(int t = 0; t < 3; t++) {
        bool fvgUsed = (t == 0 && Use_FVG1_Entry) || (t == 1 && Use_FVG2_Entry) || (t == 2 && Use_FVG3_Entry);
        if(UseBuiltInSMC(t) || fvgUsed) CalcSMC(t);
    }
    if(UseBuiltInMP()) CalcMarketProfile();
    if(DrawBuiltIn) DrawBuiltInLevels();
}

// ====================================================================
// --- GAMBAR LEVEL BUILT-IN (prefix KGEA_, never matched by the KG scanners) ---
// ====================================================================
void DrawHLine(string name, double price, color c, int style, string tip) {
    if(price <= 0) { ObjectDelete(0, name); return; }
    if(ObjectFind(0, name) < 0) {
        ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
        ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, name, OBJPROP_BACK, true);
    }
    ObjectSetDouble(0, name, OBJPROP_PRICE, 0, price);
    ObjectSetInteger(0, name, OBJPROP_COLOR, c);
    ObjectSetInteger(0, name, OBJPROP_STYLE, style);
    ObjectSetString(0, name, OBJPROP_TOOLTIP, tip);
}

void DrawRect(string name, datetime t1, double p1, double p2, color c, string tip) {
    if(p1 <= 0 || p2 <= 0 || t1 == 0) { ObjectDelete(0, name); return; }
    datetime t2 = Time[0] + PeriodSeconds() * 10;
    if(ObjectFind(0, name) < 0) {
        ObjectCreate(0, name, OBJ_RECTANGLE, 0, t1, p1, t2, p2);
        ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, name, OBJPROP_BACK, true);
    }
    ObjectSetInteger(0, name, OBJPROP_TIME, 0, t1);
    ObjectSetInteger(0, name, OBJPROP_TIME, 1, t2);
    ObjectSetDouble(0, name, OBJPROP_PRICE, 0, p1);
    ObjectSetDouble(0, name, OBJPROP_PRICE, 1, p2);
    ObjectSetInteger(0, name, OBJPROP_COLOR, c);
    ObjectSetString(0, name, OBJPROP_TOOLTIP, tip);
}

void DrawBuiltInLevels() {
    bool mp = UseBuiltInMP();
    DrawHLine("KGEA_MP_POC", mp ? g_MPPoc : 0, clrDarkOrange, STYLE_SOLID, "Built-in POC");
    DrawHLine("KGEA_MP_VAH", mp ? g_MPVah : 0, clrSteelBlue, STYLE_DASH, "Built-in VAH");
    DrawHLine("KGEA_MP_VAL", mp ? g_MPVal : 0, clrSteelBlue, STYLE_DASH, "Built-in VAL");

    color obBull  = g_LightChart ? C'200,235,200' : C'0,60,0';
    color obBear  = g_LightChart ? C'245,205,205' : C'70,0,0';
    color fvgBull = g_LightChart ? C'205,220,250' : C'0,30,80';
    color fvgBear = g_LightChart ? C'250,225,195' : C'80,40,0';

    for(int t = 0; t < 3; t++) {
        string tag = "KGEA_S" + IntegerToString(t + 1) + "_";
        string tfn = TFName(SMCTimeframe(t));
        bool bi = UseBuiltInSMC(t);
        bool fvgUsed = (t == 0 && Use_FVG1_Entry) || (t == 1 && Use_FVG2_Entry) || (t == 2 && Use_FVG3_Entry);
        DrawHLine(tag + "EQ", bi ? SMCEquilibrium(t) : 0, clrGray, STYLE_DOT, "SMC " + tfn + " Equilibrium 50%");
        DrawRect(tag + "OBB", g_SMC[t].obBullTime, bi ? g_SMC[t].obBullTop : 0, g_SMC[t].obBullBot, obBull, "Bullish OB " + tfn);
        DrawRect(tag + "OBS", g_SMC[t].obBearTime, bi ? g_SMC[t].obBearTop : 0, g_SMC[t].obBearBot, obBear, "Bearish OB " + tfn);
        DrawRect(tag + "FVGB", g_SMC[t].fvgBullTime, fvgUsed ? g_SMC[t].fvgBullTop : 0, g_SMC[t].fvgBullBot, fvgBull, "Bullish FVG " + tfn);
        DrawRect(tag + "FVGS", g_SMC[t].fvgBearTime, fvgUsed ? g_SMC[t].fvgBearTop : 0, g_SMC[t].fvgBearBot, fvgBear, "Bearish FVG " + tfn);
    }
}

// Panel line: which source feeds each tool (KG = indicator objects, BI = built-in).
string SourceText() {
    string txt = "Sumber SMC ";
    for(int t = 0; t < 3; t++) txt += TFName(SMCTimeframe(t)) + ":" + (UseBuiltInSMC(t) ? "BI " : "KG ");
    return txt + "| MP:" + (UseBuiltInMP() ? "BI" : "KG");
}

// ====================================================================
// --- FUNGSI AREA & JARAK ---
// ====================================================================
// Pairs of horizontal lines (top + bottom); the top line colour decides the side.
void ScanLinePairZones(double price, string topKey, string botFrom, string botTo, double &minDist, int &status) {
    for(int i = 0; i < g_ObjCount; i++) {
        string top = g_Objs[i];
        if(StringFind(top, topKey) < 0) continue;
        if(!IsObjectActive(top)) continue;
        string bot = top;
        StringReplace(bot, botFrom, botTo);
        if(ObjectFind(0, bot) < 0) continue;
        int side = ColorSide(ObjColor(top), SupZoneColor, ResZoneColor);
        UpdateZone(price, ObjPrice(top, 0), ObjPrice(bot, 0), side, minDist, status);
    }
}

int GetValueAreaStatus(double price, double &outDist) {
    double minDist = NO_ZONE; int status = 0;
    if(UseBuiltInMP()) {
        // Built-in: buy at the bottom edge of value (VAL), sell at the top edge (VAH).
        if(g_MPVal > 0 && g_MPVah > g_MPVal) {
            double edge = MathMax((g_MPVah - g_MPVal) * 0.15, g_MPBin);
            UpdateZone(price, g_MPVal, g_MPVal + edge, 1, minDist, status);
            UpdateZone(price, g_MPVah - edge, g_MPVah, -1, minDist, status);
        }
        outDist = minDist;
        return status;
    }
    ScanLinePairZones(price, "Micro_MP_LVN_Top_", "_Top_", "_Bot_", minDist, status);
    ScanLinePairZones(price, "VP_LineVAH_", "LineVAH_", "LineVAL_", minDist, status);
    outDist = minDist;
    return status;
}

int GetPOCStatus(double price, double &outDist) {
    double minDist = NO_ZONE; int status = 0;
    if(UseBuiltInMP()) {
        if(g_MPPoc > 0) UpdateZone(price, g_MPPoc - g_MPBin / 2, g_MPPoc + g_MPBin / 2, (price >= g_MPPoc) ? 1 : -1, minDist, status);
        outDist = minDist;
        return status;
    }
    ScanLinePairZones(price, "KGVP_batas_atas_POC_", "batas_atas", "batas_bawah", minDist, status);
    outDist = minDist;
    return status;
}

int GetSnDStatus(double price, double &outDist) {
    double minDist = NO_ZONE; int status = 0;
    for(int i = 0; i < g_ObjCount; i++) {
        string n = g_Objs[i];
        if(StringFind(n, "MergedZone_") < 0 || !IsObjectActive(n)) continue;
        UpdateZone(price, ObjPrice(n, 0), ObjPrice(n, 1), ColorSide(ObjColor(n), SnDSupColor, SnDResColor), minDist, status);
    }
    outDist = minDist;
    return status;
}

int GetOBStatus(double price, double &outDist, string prefix) {
    double minDist = NO_ZONE; int status = 0;
    int tier = TierOfPrefix(prefix);
    if(UseBuiltInSMC(tier)) {
        if(g_SMC[tier].obBullTop > 0) UpdateZone(price, g_SMC[tier].obBullTop, g_SMC[tier].obBullBot, 1, minDist, status);
        if(g_SMC[tier].obBearTop > 0) UpdateZone(price, g_SMC[tier].obBearTop, g_SMC[tier].obBearBot, -1, minDist, status);
        outDist = minDist;
        return status;
    }
    for(int i = 0; i < g_ObjCount; i++) {
        string n = g_Objs[i];
        if(StringFind(n, prefix) != 0 || StringFind(n, "_OB_") <= 0 || !IsObjectActive(n)) continue;
        UpdateZone(price, ObjPrice(n, 0), ObjPrice(n, 1), ColorSide(ObjColor(n), OBSupColor, OBResColor), minDist, status);
    }
    outDist = minDist;
    return status;
}

int GetKGSupDemStatus(double price, double &outDist) {
    double minDist = NO_ZONE; int status = 0;
    for(int i = 0; i < g_ObjCount; i++) {
        string n = g_Objs[i];
        if(StringFind(n, "KG_SupDem") < 0) continue;
        int side = 0;
        if(StringFind(n, "_DemandZone_") >= 0) side = 1;
        else if(StringFind(n, "_SupplyZone_") >= 0) side = -1;
        if(side == 0 || !IsObjectActive(n)) continue;
        UpdateZone(price, ObjPrice(n, 0), ObjPrice(n, 1), side, minDist, status);
    }
    outDist = minDist;
    return status;
}

int GetSMCFiboStatus(double price, double &outDist, string prefix) {
    double closest = NO_ZONE; int type = 0;
    int tier = TierOfPrefix(prefix);
    if(UseBuiltInSMC(tier)) {
        int dir = g_SMC[tier].trend;
        double hi = g_SMC[tier].rangeHigh, lo = g_SMC[tier].rangeLow;
        if(dir != 0 && hi > lo && lo > 0) {
            double levels[3] = {0.5, 0.618, 0.786};
            for(int k = ICT_OTEOnly ? 1 : 0; k < 3; k++) {
                // Retracement of the current leg: from the high for a bull leg, from the low for a bear leg.
                double lvl = (dir == 1) ? hi - levels[k] * (hi - lo) : lo + levels[k] * (hi - lo);
                double dist = MathAbs(price - lvl) / GetPipValue();
                if(dist < closest) { closest = dist; type = dir; }
            }
        }
        outDist = closest;
        return type;
    }
    for(int i = 0; i < g_ObjCount; i++) {
        string n = g_Objs[i];
        // Only real Fibo level lines (50/61/78/100). OB, BOS and CHoCH objects of the
        // same prefix are excluded so their timestamps are never read as Fibo levels.
        if(StringFind(n, prefix) != 0 || !IsSMCFiboLevel(n)) continue;
        double p = ObjPrice(n, 0);
        if(p <= 0) continue;
        double dist = MathAbs(price - p) / GetPipValue();
        if(dist >= closest) continue;
        closest = dist;
        if(StringFind(n, "BULL") >= 0 || StringFind(n, "UP") >= 0)      type = 1;   // Fibo Bullish = Area BUY
        else if(StringFind(n, "BEAR") >= 0 || StringFind(n, "DN") >= 0) type = -1;  // Fibo Bearish = Area SELL
        else type = (price >= p) ? 1 : -1;
    }
    outDist = closest;
    return type;
}

int GetKGFiboStatus(double price, double &outDist) {
    double closest = NO_ZONE; int type = 0;
    for(int i = 0; i < g_ObjCount; i++) {
        string n = g_Objs[i];
        if(StringFind(n, KGFibo_Prefix) < 0) continue;
        if(StringFind(n, SMC1_Prefix) >= 0 || StringFind(n, SMC2_Prefix) >= 0 ||
           StringFind(n, SMC3_Prefix) >= 0 || StringFind(n, SMCScout_Prefix) >= 0) continue;
        double p = ObjPrice(n, 0);
        if(p <= 0) continue;
        double dist = MathAbs(price - p) / GetPipValue();
        if(dist < closest) { closest = dist; type = (price >= p) ? 1 : -1; }
    }
    outDist = closest;
    return type;
}

int GetKGSupDemFiboStatus(double price, double &outDist) {
    double closest = NO_ZONE; int type = 0;
    for(int i = 0; i < g_ObjCount; i++) {
        string n = g_Objs[i];
        if(StringFind(n, "KG_SupDem") < 0) continue;
        int side = 0;
        if(StringFind(n, "_50_DemFibo_") >= 0 || StringFind(n, "_61_DemFibo_") >= 0 || StringFind(n, "_78_DemFibo_") >= 0) side = 1;
        else if(StringFind(n, "_50_SupFibo_") >= 0 || StringFind(n, "_61_SupFibo_") >= 0 || StringFind(n, "_78_SupFibo_") >= 0) side = -1;
        if(side == 0) continue;
        double p = ObjPrice(n, 0);
        if(p <= 0) continue;
        double dist = MathAbs(price - p) / GetPipValue();
        if(dist < closest) { closest = dist; type = side; }
    }
    outDist = closest;   // NO_ZONE when nothing found (was 0.0 = false "in zone")
    return type;
}

// Nearest of BB upper / MA / BB lower; side = which side of that line the price is on.
void NearestBandLine(double price, double ma, double up, double dn, double &dist, int &type) {
    double pip = GetPipValue();
    dist = MathAbs(price - up) / pip;
    type = (price >= up) ? 1 : -1;
    double dMa = MathAbs(price - ma) / pip;
    if(dMa < dist) { dist = dMa; type = (price >= ma) ? 1 : -1; }
    double dDn = MathAbs(price - dn) / pip;
    if(dDn < dist) { dist = dDn; type = (price >= dn) ? 1 : -1; }
}

// ====================================================================
// --- FUNGSI ALAT UKUR TREN ---
// ====================================================================
int GetEMACrossTrend(ENUM_KG_TIMEFRAME fastTF, ENUM_KG_TIMEFRAME slowTF) {
    double fastMA = iMA(Symbol(), Period(), GetKGPeriod(fastTF), 0, MA_Mode, PRICE_MEDIAN, 0);
    double slowMA = iMA(Symbol(), Period(), GetKGPeriod(slowTF), 0, MA_Mode, PRICE_MEDIAN, 0);
    if(fastMA > slowMA) return 1;
    if(fastMA < slowMA) return -1;
    return 0;
}

int GetRealtimeSMCTrend(string prefix) {
    int tier = TierOfPrefix(prefix);
    if(UseBuiltInSMC(tier)) return g_SMC[tier].trend;
    datetime latestTime = 0;
    int detectedTrend = 0;
    for(int i = 0; i < g_ObjCount; i++) {
        string n = g_Objs[i];
        if(StringFind(n, prefix) != 0) continue;
        bool isUp = (StringFind(n, "_CH_UP_") >= 0 || StringFind(n, "_BOS_UP_") >= 0);
        bool isDn = (StringFind(n, "_CH_DN_") >= 0 || StringFind(n, "_BOS_DN_") >= 0);
        if(!isUp && !isDn) continue;
        datetime t = ObjTime(n, 1);
        if(t == 0) t = ObjTime(n, 0);
        if(t > latestTime) {
            latestTime = t;
            detectedTrend = isUp ? 1 : -1;
        }
    }
    return detectedTrend;
}

bool IsVAPOCTrendObject(string n) {
    return (StringFind(n, "Micro_MP_LVN_Top_") >= 0 || StringFind(n, "KGVP_batas_atas_POC_") >= 0 ||
            StringFind(n, "VP_LineVAH_") >= 0 || StringFind(n, "VP_LineVAL_") >= 0);
}

int GetRealtimeVAPOCTrendColor(double price) {
    // Built-in: outside value = breakout direction, inside value = side of the POC.
    if(UseBuiltInMP()) {
        if(g_MPPoc <= 0) return 0;
        if(price > g_MPVah) return 1;
        if(price < g_MPVal) return -1;
        return (price >= g_MPPoc) ? 1 : -1;
    }

    // 1. Prioritas: objek MASTER dari indikator
    string masterTop = "Micro_MP_LVN_Top_MASTER";
    if(ObjectFind(0, masterTop) >= 0) return ColorSide(ObjColor(masterTop), SupZoneColor, ResZoneColor);

    // 2. Fallback: pencarian manual
    int detectedTrend = 0;

    if(TrendLogicMode == TREND_TIME) {
        datetime latestTime = 0;
        double closestDist = DBL_MAX;
        for(int i = 0; i < g_ObjCount; i++) {
            string n = g_Objs[i];
            if(StringFind(n, "MASTER") >= 0 || !IsVAPOCTrendObject(n)) continue;
            color c = ObjColor(n);
            if(UseFallback && c != SupZoneColor && c != ResZoneColor) continue;

            // Timestamp from OBJPROP_TEXT when the indicator stores it, else anchor time.
            string textStamp = ObjectGetString(0, n, OBJPROP_TEXT);
            datetime t1 = (textStamp != "") ? (datetime)StringToInteger(textStamp) : ObjTime(n, 0);
            double dist = MathAbs(price - ObjPrice(n, 0));

            if(t1 > latestTime || (t1 == latestTime && dist < closestDist)) {
                latestTime = t1;
                closestDist = dist;
                detectedTrend = ColorSide(c, SupZoneColor, ResZoneColor);
            }
        }
    } else if(TrendLogicMode == TREND_DISTANCE) {
        double minDistance = DBL_MAX;
        for(int i = 0; i < g_ObjCount; i++) {
            string n = g_Objs[i];
            if(!IsVAPOCTrendObject(n)) continue;
            color c = ObjColor(n);
            if(UseFallback && c != SupZoneColor && c != ResZoneColor) continue;
            double dist = MathAbs(price - ObjPrice(n, 0));
            if(dist < minDistance) {
                minDistance = dist;
                detectedTrend = ColorSide(c, SupZoneColor, ResZoneColor);
            }
        }
    } else if(TrendLogicMode == TREND_COLOR_CHANGE) {
        datetime latestChangeTime = 0;
        double closestDist = DBL_MAX;
        bool foundAny = false;
        int arrSize = ArraySize(g_TrackedNames);
        for(int i = 0; i < arrSize; i++) {
            color c = g_TrackedColors[i];
            if(UseFallback && c != SupZoneColor && c != ResZoneColor) continue;
            double dist = MathAbs(price - ObjPrice(g_TrackedNames[i], 0));
            if(!foundAny || g_TrackedChangeTime[i] > latestChangeTime ||
               (g_TrackedChangeTime[i] == latestChangeTime && dist < closestDist)) {
                latestChangeTime = g_TrackedChangeTime[i];
                closestDist = dist;
                foundAny = true;
                detectedTrend = ColorSide(c, SupZoneColor, ResZoneColor);
            }
        }
    }
    return detectedTrend;
}

int GetDailyVWAPTrend(double price, double &outVWAP) {
    outVWAP = 0;
    int startBar = iBarShift(Symbol(), Period(), iTime(Symbol(), PERIOD_D1, 0));
    if(startBar < 0) return 0;

    double sumPV0 = 0, sumV0 = 0, sumPV1 = 0, sumV1 = 0;
    for(int i = startBar; i >= 0; i--) {
        double tp = (High[i] + Low[i] + Close[i]) / 3.0;
        double vol = (double)Volume[i];
        sumPV0 += tp * vol; sumV0 += vol;
        if(i > 0) { sumPV1 += tp * vol; sumV1 += vol; }
    }
    if(sumV0 == 0 || sumV1 == 0) return 0;

    double currentVWAP = sumPV0 / sumV0;
    double prevVWAP = sumPV1 / sumV1;
    outVWAP = currentVWAP;

    if(!Use_VWAP1_BBSD2) {
        if(currentVWAP > prevVWAP) return 1;
        if(currentVWAP < prevVWAP) return -1;
        return 0;
    }

    // --- Standar deviasi berbobot volume ---
    double sumVar = 0;
    for(int i = startBar; i >= 0; i--) {
        double tp = (High[i] + Low[i] + Close[i]) / 3.0;
        sumVar += (double)Volume[i] * MathPow(tp - currentVWAP, 2);
    }
    double sd = MathSqrt(sumVar / sumV0);
    double upperSD2 = currentVWAP + 2.0 * sd;
    double lowerSD2 = currentVWAP - 2.0 * sd;

    // 1. Kondisi ekstrem (di luar bands)
    if(price >= upperSD2) return -1;
    if(price <= lowerSD2) return 1;

    // 2. Di dalam bands: garis terdekat menentukan
    double distUp = MathAbs(price - upperSD2);
    double distVWAP = MathAbs(price - currentVWAP);
    double distDn = MathAbs(price - lowerSD2);
    double minDistance = distUp;
    int signal = -1;
    if(distVWAP < minDistance) { minDistance = distVWAP; signal = (price >= currentVWAP) ? 1 : -1; }
    if(distDn < minDistance) signal = 1;
    return signal;
}

int GetVWAP2DaysTrend(double &outVWAP) {
    outVWAP = 0;
    // Every bar from the start of yesterday up to now (each bar counted once).
    int startBar = iBarShift(Symbol(), Period(), iTime(Symbol(), PERIOD_D1, 1));
    if(startBar < 0) return 0;

    double sumPV0 = 0, sumV0 = 0, sumPV1 = 0, sumV1 = 0;
    for(int i = startBar; i >= 0; i--) {
        double tp = (High[i] + Low[i] + Close[i]) / 3.0;
        double vol = (double)Volume[i];
        sumPV0 += tp * vol; sumV0 += vol;
        if(i > 0) { sumPV1 += tp * vol; sumV1 += vol; }
    }
    if(sumV0 == 0 || sumV1 == 0) return 0;

    double currentVWAP = sumPV0 / sumV0;
    double prevVWAP = sumPV1 / sumV1;
    outVWAP = currentVWAP;
    if(currentVWAP > prevVWAP) return 1;
    if(currentVWAP < prevVWAP) return -1;
    return 0;
}

int GetKGBBMATrend(double price, double &ma, double &up, double &dn, ENUM_KG_TIMEFRAME tf) {
    int period = GetKGPeriod(tf);
    ma = iMA(Symbol(), Period(), period, 0, MODE_SMA, PRICE_CLOSE, 0);
    up = iBands(Symbol(), Period(), period, 1.0, 0, PRICE_CLOSE, MODE_UPPER, 0);
    dn = iBands(Symbol(), Period(), period, 1.0, 0, PRICE_CLOSE, MODE_LOWER, 0);

    // 1. Breakout
    if(price > up) return 1;
    if(price < dn) return -1;

    // 2. Di dalam bands (AdvancedCalc): garis terdekat menentukan
    if(UseAdvancedCalc) {
        double distUp = MathAbs(price - up);
        double distMA = MathAbs(price - ma);
        double distDn = MathAbs(price - dn);
        double minDistance = distUp;
        int signal = -1;
        if(distMA < minDistance) { minDistance = distMA; signal = (price >= ma) ? 1 : -1; }
        if(distDn < minDistance) signal = 1;
        return signal;
    }
    return 0;   // Basic mode: netral di dalam bands
}

// Awesome Oscillator: SMA(fast) - SMA(slow) of the median price on M5.
double GetCustomAO(int shift) {
    double fastMA = iMA(Symbol(), PERIOD_M5, AO_Fast_Period, 0, MODE_SMA, PRICE_MEDIAN, shift);
    double slowMA = iMA(Symbol(), PERIOD_M5, AO_Slow_Period, 0, MODE_SMA, PRICE_MEDIAN, shift);
    return fastMA - slowMA;
}

// ====================================================================
// --- STATISTIK HARIAN (cache, dihitung ulang hanya saat ada perubahan) ---
// ====================================================================
bool IsManagedOrder(bool includeManual) {
    if(OrderSymbol() != Symbol()) return false;
    if(OrderMagicNumber() == MagicNumber) return true;
    return (includeManual && OrderMagicNumber() == 0);
}

void RefreshDailyStats() {
    static datetime cachedDay = 0;
    static datetime lastFull = 0;
    static int cachedHist = -1;
    static int cachedOpen = -1;

    datetime day = iTime(Symbol(), PERIOD_D1, 0);
    int hist = OrdersHistoryTotal();
    int open = OrdersTotal();
    // Periodic full refresh also catches pending orders that got filled.
    if(day == cachedDay && hist == cachedHist && open == cachedOpen && TimeCurrent() - lastFull < 60) return;
    cachedDay = day; cachedHist = hist; cachedOpen = open; lastFull = TimeCurrent();

    g_DayBuy = 0; g_DaySell = 0; g_DayClosedPL = 0.0;

    for(int i = open - 1; i >= 0; i--) {
        if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES) || !IsManagedOrder(ManageManualTrades)) continue;
        if(OrderOpenTime() < day) continue;
        if(OrderType() == OP_BUY) g_DayBuy++;
        else if(OrderType() == OP_SELL) g_DaySell++;
    }

    for(int i = hist - 1; i >= 0; i--) {
        if(!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY) || !IsManagedOrder(ManageManualTrades)) continue;
        int type = OrderType();
        if(type != OP_BUY && type != OP_SELL) continue;
        if(OrderOpenTime() >= day) {
            if(type == OP_BUY) g_DayBuy++; else g_DaySell++;
        }
        if(OrderCloseTime() >= day) g_DayClosedPL += OrderProfit() + OrderSwap() + OrderCommission();
    }
}

bool IsDailyLossHit() {
    if(MaxDailyLossPct <= 0) return false;
    double floating = 0.0;
    for(int i = OrdersTotal() - 1; i >= 0; i--) {
        if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES) || !IsManagedOrder(ManageManualTrades)) continue;
        if(OrderType() == OP_BUY || OrderType() == OP_SELL)
            floating += OrderProfit() + OrderSwap() + OrderCommission();
    }
    double dayStartBalance = AccountBalance() - g_DayClosedPL;
    if(dayStartBalance <= 0) return false;
    return (g_DayClosedPL + floating) <= -dayStartBalance * MaxDailyLossPct / 100.0;
}

// ====================================================================
// --- HIDDEN SL/TP (Global Variables) ---
// ====================================================================
void SetVirtualSL(int ticket, double sl) { GlobalVariableSet("KG_SL_" + IntegerToString(ticket), sl); }
void SetVirtualTP(int ticket, double tp) { GlobalVariableSet("KG_TP_" + IntegerToString(ticket), tp); }
double GetVirtualSL(int ticket) { string n = "KG_SL_" + IntegerToString(ticket); return GlobalVariableCheck(n) ? GlobalVariableGet(n) : 0.0; }
double GetVirtualTP(int ticket) { string n = "KG_TP_" + IntegerToString(ticket); return GlobalVariableCheck(n) ? GlobalVariableGet(n) : 0.0; }
void DeleteVirtualSLTP(int ticket) {
    GlobalVariableDel("KG_SL_" + IntegerToString(ticket));
    GlobalVariableDel("KG_TP_" + IntegerToString(ticket));
}

void CleanupVirtualSLTP() {
    for(int i = GlobalVariablesTotal() - 1; i >= 0; i--) {
        string gvName = GlobalVariableName(i);
        if(StringFind(gvName, "KG_SL_") != 0 && StringFind(gvName, "KG_TP_") != 0) continue;
        int ticket = (int)StringToInteger(StringSubstr(gvName, 6));
        if(!OrderSelect(ticket, SELECT_BY_TICKET) || OrderCloseTime() > 0) GlobalVariableDel(gvName);
    }
}

void CheckHiddenSLTP() {
    for(int i = OrdersTotal() - 1; i >= 0; i--) {
        if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES) || !IsManagedOrder(ManageManualTrades)) continue;
        int type = OrderType();
        if(type != OP_BUY && type != OP_SELL) continue;
        int ticket = OrderTicket();
        double vSL = GetVirtualSL(ticket);
        double vTP = GetVirtualTP(ticket);
        if(vSL <= 0 && vTP <= 0) continue;

        bool hit = false;
        if(type == OP_BUY) hit = (vSL > 0 && Bid <= vSL) || (vTP > 0 && Bid >= vTP);
        else               hit = (vSL > 0 && Ask >= vSL) || (vTP > 0 && Ask <= vTP);
        if(hit) CloseOrder(ticket, "Hidden SL/TP");
    }
}

// ====================================================================
// --- EKSEKUSI & MODIFIKASI ORDER ---
// ====================================================================
// Prints a message, suppressing identical repeats within 60 seconds (avoids per-tick log spam).
void LogThrottled(string msg) {
    static datetime lastTime = 0;
    static string lastMsg = "";
    if(msg == lastMsg && TimeCurrent() - lastTime < 60) return;
    lastTime = TimeCurrent();
    lastMsg = msg;
    Print(msg);
}

double MinStopDistance() {
    double lvl = MathMax(MarketInfo(Symbol(), MODE_STOPLEVEL), MarketInfo(Symbol(), MODE_FREEZELEVEL));
    return (lvl + 1) * Point;
}

bool IsBuyType(int type) { return (type == OP_BUY || type == OP_BUYLIMIT || type == OP_BUYSTOP); }

// Broker-side validity of SL/TP (stop level / freeze level) for the selected order type.
bool ValidStops(int type, double openPrice, double sl, double tp) {
    double d = MinStopDistance();
    double ref = openPrice;
    if(type == OP_BUY) ref = Bid;
    else if(type == OP_SELL) ref = Ask;
    if(IsBuyType(type)) return (sl <= 0 || sl <= ref - d) && (tp <= 0 || tp >= ref + d);
    return (sl <= 0 || sl >= ref + d) && (tp <= 0 || tp <= ref - d);
}

bool ModifyStops(int ticket, double sl, double tp) {
    if(!OrderSelect(ticket, SELECT_BY_TICKET)) return false;
    sl = NormalizeDouble(sl, Digits);
    tp = NormalizeDouble(tp, Digits);
    if(MathAbs(sl - OrderStopLoss()) < Point / 2 && MathAbs(tp - OrderTakeProfit()) < Point / 2) return true;
    if(!ValidStops(OrderType(), OrderOpenPrice(), sl, tp)) {
        LogThrottled("SL/TP #" + IntegerToString(ticket) + " dilewati: terlalu dekat dengan harga (stop level). SL=" +
                     DoubleToStr(sl, Digits) + " TP=" + DoubleToStr(tp, Digits));
        return false;
    }
    if(!OrderModify(ticket, OrderOpenPrice(), sl, tp, OrderExpiration(), clrNONE)) {
        LogThrottled("OrderModify #" + IntegerToString(ticket) + " gagal, error " + IntegerToString(GetLastError()));
        return false;
    }
    return true;
}

bool CloseOrder(int ticket, string reason) {
    if(!OrderSelect(ticket, SELECT_BY_TICKET) || OrderCloseTime() > 0) return false;
    RefreshRates();
    double price = (OrderType() == OP_BUY) ? Bid : Ask;
    if(!OrderClose(ticket, OrderLots(), NormalizeDouble(price, Digits), SlippagePoints(), clrNONE)) {
        LogThrottled("Close #" + IntegerToString(ticket) + " (" + reason + ") gagal, error " + IntegerToString(GetLastError()));
        return false;
    }
    DeleteVirtualSLTP(ticket);
    return true;
}

int LotDigits(double step) {
    if(step <= 0) return 2;
    return (int)MathMax(0, MathCeil(-MathLog10(step) - 1e-9));
}

double CalcLotSize() {
    double minLot = MarketInfo(Symbol(), MODE_MINLOT);
    double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
    double step   = MarketInfo(Symbol(), MODE_LOTSTEP);
    if(step <= 0) step = 0.01;

    double lot;
    if(FixedLotSize > 0) {
        lot = FixedLotSize;
    } else if(StopLossPips <= 0) {
        lot = minLot;   // Risk % undefined without a stop loss
    } else {
        double tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
        double tickSize  = MarketInfo(Symbol(), MODE_TICKSIZE);
        if(tickValue <= 0 || tickSize <= 0) return 0.0;
        double lossPerLot = (StopLossPips * GetPipValue()) / tickSize * tickValue;
        if(lossPerLot <= 0) return 0.0;
        lot = AccountBalance() * (RiskPercent / 100.0) / lossPerLot;
    }

    // Round DOWN to the lot step so the actual risk never exceeds the setting.
    lot = MathFloor(lot / step + 1e-9) * step;
    if(lot < minLot) lot = minLot;
    if(lot > maxLot) lot = maxLot;
    return NormalizeDouble(lot, LotDigits(step));
}

bool OpenMarketOrder(int type) {
    if(!IsTradeAllowed()) { LogThrottled("Trading tidak diizinkan (AutoTrading OFF / context sibuk)."); return false; }
    RefreshRates();

    double lot = CalcLotSize();
    if(lot <= 0) { LogThrottled("Lot tidak valid, entry dibatalkan."); return false; }

    ResetLastError();
    if(AccountFreeMarginCheck(Symbol(), type, lot) <= 0 || GetLastError() == ERR_NOT_ENOUGH_MONEY) {
        LogThrottled("Margin tidak cukup untuk lot " + DoubleToStr(lot, 2) + ", entry dibatalkan.");
        return false;
    }

    double price = (type == OP_BUY) ? Ask : Bid;
    string comment = (type == OP_BUY) ? "MyEA Buy" : "MyEA Sell";
    int ticket = OrderSend(Symbol(), type, lot, NormalizeDouble(price, Digits), SlippagePoints(), 0, 0, comment, MagicNumber, 0, clrNONE);
    if(ticket < 0) {
        LogThrottled("OrderSend " + (type == OP_BUY ? "BUY" : "SELL") + " gagal, error " + IntegerToString(GetLastError()));
        return false;
    }
    if(!OrderSelect(ticket, SELECT_BY_TICKET)) return true;

    // SL/TP from the actual fill price (not the requested price).
    double pip = GetPipValue();
    double openPrice = OrderOpenPrice();
    int dir = (type == OP_BUY) ? 1 : -1;
    double sl = (StopLossPips > 0)   ? openPrice - dir * StopLossPips * pip   : 0;
    double tp = (TakeProfitPips > 0) ? openPrice + dir * TakeProfitPips * pip : 0;

    if(UseHiddenSLTP) {
        if(sl > 0) SetVirtualSL(ticket, sl);
        if(tp > 0) SetVirtualTP(ticket, tp);
    } else if(sl > 0 || tp > 0) {
        // Keep the initial protection outside the broker stop level so it is never rejected.
        RefreshRates();
        double d = MinStopDistance();
        if(type == OP_BUY) {
            if(sl > 0) sl = MathMin(sl, Bid - d);
            if(tp > 0) tp = MathMax(tp, Bid + d);
        } else {
            if(sl > 0) sl = MathMax(sl, Ask + d);
            if(tp > 0) tp = MathMin(tp, Ask - d);
        }
        ModifyStops(ticket, sl, tp);   // Retried by ApplyDefaultProtection() if it fails
    }
    return true;
}

// Gives default SL/TP to managed orders that have none (EA retry + manual orders).
void ApplyDefaultProtection() {
    if(StopLossPips <= 0 && TakeProfitPips <= 0) return;
    double pip = GetPipValue();
    for(int i = OrdersTotal() - 1; i >= 0; i--) {
        if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES) || !IsManagedOrder(ManageManualTrades)) continue;
        int ticket = OrderTicket();
        int type = OrderType();
        double openPrice = OrderOpenPrice();
        int dir = IsBuyType(type) ? 1 : -1;
        double sl = (StopLossPips > 0)   ? openPrice - dir * StopLossPips * pip   : 0;
        double tp = (TakeProfitPips > 0) ? openPrice + dir * TakeProfitPips * pip : 0;

        if(UseHiddenSLTP) {
            if(type != OP_BUY && type != OP_SELL) continue;
            if(GetVirtualSL(ticket) > 0 || GetVirtualTP(ticket) > 0) continue;
            if(sl > 0) SetVirtualSL(ticket, sl);
            if(tp > 0) SetVirtualTP(ticket, tp);
        } else {
            if(OrderStopLoss() != 0 || OrderTakeProfit() != 0) continue;
            ModifyStops(ticket, sl, tp);
        }
    }
}

void CheckTrendReversalClose(int currentTrend) {
    if(currentTrend == 0) return;
    for(int i = OrdersTotal() - 1; i >= 0; i--) {
        if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES) || !IsManagedOrder(CloseManualTrades)) continue;
        int type = OrderType();
        if((currentTrend == 1 && type == OP_SELL) || (currentTrend == -1 && type == OP_BUY))
            CloseOrder(OrderTicket(), "Reversal Trend");
    }
}

void SmartBEPLogic() {
    if(!UseSmartBEP) return;
    double pip = GetPipValue();
    double lockDist = BEPExtraPips * pip;
    double minDist = MinStopDistance();

    for(int i = OrdersTotal() - 1; i >= 0; i--) {
        if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES) || !IsManagedOrder(ManageManualTrades)) continue;
        int type = OrderType();
        if(type != OP_BUY && type != OP_SELL) continue;

        int ticket = OrderTicket();
        double openPrice = OrderOpenPrice();
        double brokerTP = OrderTakeProfit();
        double curSL = UseHiddenSLTP ? GetVirtualSL(ticket) : OrderStopLoss();
        double curTP = UseHiddenSLTP ? GetVirtualTP(ticket) : brokerTP;

        // Trigger relative to this order's real TP distance (falls back to the input).
        double tpDist = (curTP > 0) ? MathAbs(curTP - openPrice) : TakeProfitPips * pip;
        if(tpDist <= 0) continue;
        double trigger = tpDist * BEPTriggerPct / 100.0;

        if(type == OP_BUY) {
            if(Bid - openPrice < trigger) continue;
            double newSL = openPrice + lockDist;
            if(curSL != 0 && curSL >= newSL) continue;
            if(newSL > Bid - minDist) continue;   // Lock level not reachable yet
            if(UseHiddenSLTP) SetVirtualSL(ticket, newSL);
            else ModifyStops(ticket, newSL, brokerTP);
        } else {
            if(openPrice - Ask < trigger) continue;
            double newSL = openPrice - lockDist;
            if(curSL != 0 && curSL <= newSL) continue;
            if(newSL < Ask + minDist) continue;
            if(UseHiddenSLTP) SetVirtualSL(ticket, newSL);
            else ModifyStops(ticket, newSL, brokerTP);
        }
    }
}

void TrailingStopLogic() {
    if(!UseTrailingStop) return;
    double pip = GetPipValue();
    double startDist = TrailingStartPips * pip;
    double trailDist = MathMax(TrailingDistance * pip, MinStopDistance());
    double stepDist  = TrailingStep * pip;

    for(int i = OrdersTotal() - 1; i >= 0; i--) {
        if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES) || !IsManagedOrder(ManageManualTrades)) continue;
        int type = OrderType();
        if(type != OP_BUY && type != OP_SELL) continue;

        int ticket = OrderTicket();
        double openPrice = OrderOpenPrice();
        double brokerTP = OrderTakeProfit();
        double curSL = UseHiddenSLTP ? GetVirtualSL(ticket) : OrderStopLoss();

        if(type == OP_BUY) {
            if(Bid - openPrice < startDist) continue;
            double newSL = Bid - trailDist;
            if(curSL != 0 && newSL < curSL + stepDist) continue;
            if(UseHiddenSLTP) SetVirtualSL(ticket, newSL);
            else ModifyStops(ticket, newSL, brokerTP);
        } else {
            if(openPrice - Ask < startDist) continue;
            double newSL = Ask + trailDist;
            if(curSL != 0 && newSL > curSL - stepDist) continue;
            if(UseHiddenSLTP) SetVirtualSL(ticket, newSL);
            else ModifyStops(ticket, newSL, brokerTP);
        }
    }
}

bool CanOpenBuy() {
    int buys = 0, sells = 0;
    double lowestBuyPrice = DBL_MAX;
    for(int i = OrdersTotal() - 1; i >= 0; i--) {
        if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES) || !IsManagedOrder(false)) continue;
        if(OrderType() == OP_BUY) { buys++; lowestBuyPrice = MathMin(lowestBuyPrice, OrderOpenPrice()); }
        else if(OrderType() == OP_SELL) sells++;
    }
    if(sells > 0) return (buys < MaxPosBerlawanan);
    if(buys >= MaxPosSearah) return false;
    if(buys == 0) return true;
    return (Ask <= lowestBuyPrice - StepDistancePips * GetPipValue());
}

bool CanOpenSell() {
    int buys = 0, sells = 0;
    double highestSellPrice = 0.0;
    for(int i = OrdersTotal() - 1; i >= 0; i--) {
        if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES) || !IsManagedOrder(false)) continue;
        if(OrderType() == OP_BUY) buys++;
        else if(OrderType() == OP_SELL) { sells++; highestSellPrice = MathMax(highestSellPrice, OrderOpenPrice()); }
    }
    if(buys > 0) return (sells < MaxPosBerlawanan);
    if(sells >= MaxPosSearah) return false;
    if(sells == 0) return true;
    return (Bid >= highestSellPrice + StepDistancePips * GetPipValue());
}

// ====================================================================
// --- MAINTENANCE OBJEK ---
// ====================================================================
void TrackObjectColorChanges() {
    // Drop entries whose objects were deleted so stale colours never vote.
    int n = ArraySize(g_TrackedNames);
    int w = 0;
    for(int i = 0; i < n; i++) {
        if(ObjectFind(0, g_TrackedNames[i]) < 0) continue;
        if(w != i) {
            g_TrackedNames[w] = g_TrackedNames[i];
            g_TrackedColors[w] = g_TrackedColors[i];
            g_TrackedChangeTime[w] = g_TrackedChangeTime[i];
        }
        w++;
    }
    if(w != n) {
        ArrayResize(g_TrackedNames, w);
        ArrayResize(g_TrackedColors, w);
        ArrayResize(g_TrackedChangeTime, w);
    }

    for(int i = 0; i < g_ObjCount; i++) {
        string objName = g_Objs[i];
        if(!IsVAPOCTrendObject(objName)) continue;
        color currColor = ObjColor(objName);

        int idx = -1;
        int size = ArraySize(g_TrackedNames);
        for(int j = 0; j < size; j++) {
            if(g_TrackedNames[j] == objName) { idx = j; break; }
        }

        if(idx == -1) {
            ArrayResize(g_TrackedNames, size + 1, 64);
            ArrayResize(g_TrackedColors, size + 1, 64);
            ArrayResize(g_TrackedChangeTime, size + 1, 64);
            g_TrackedNames[size] = objName;
            g_TrackedColors[size] = currColor;
            g_TrackedChangeTime[size] = ObjTime(objName, 0);
        } else if(g_TrackedColors[idx] != currColor) {
            g_TrackedColors[idx] = currColor;
            g_TrackedChangeTime[idx] = TimeCurrent();
        }
    }
}

void CleanHistoryObjects() {
    for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--) {
        string objName = ObjectName(0, i, -1, -1);
        if(StringSubstr(objName, 0, 1) == "#") ObjectDelete(0, objName);
    }
}

//====================================================================
// FUNGSI UI PANEL LEADERBOARD
//====================================================================
// Picks readable colours: dark text on light charts, light text on dark charts.
void InitPanelColors() {
    int bg = (int)ChartGetInteger(0, CHART_COLOR_BACKGROUND);
    int r = bg & 0xFF, g = (bg >> 8) & 0xFF, b = (bg >> 16) & 0xFF;   // color = 0x00BBGGRR
    g_LightChart = (0.299 * r + 0.587 * g + 0.114 * b) > 128.0;

    g_ColText      = AutoPanelColors ? (g_LightChart ? clrBlack : clrWhite) : PanelTextColor;
    g_ColHighlight = AutoPanelColors ? (g_LightChart ? clrMediumBlue : clrYellow) : HighlightColor;
    g_ColBuy       = g_LightChart ? clrGreen : clrLimeGreen;
    g_ColSell      = g_LightChart ? clrCrimson : clrRed;
    g_ColNeutral   = g_LightChart ? clrDimGray : clrSilver;
    g_ColWarn      = g_LightChart ? clrChocolate : clrCoral;
    g_ColBarBG     = g_LightChart ? clrGainsboro : clrDarkSlateGray;
}

void CreatePanel() {
    int startY = 20;
    int startX = PanelXDistance;

    ObjectCreate(0, "ProgBar_BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "ProgBar_BG", OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, "ProgBar_BG", OBJPROP_XDISTANCE, startX);
    ObjectSetInteger(0, "ProgBar_BG", OBJPROP_YDISTANCE, startY + 2);
    ObjectSetInteger(0, "ProgBar_BG", OBJPROP_XSIZE, 120);
    ObjectSetInteger(0, "ProgBar_BG", OBJPROP_YSIZE, 20);
    ObjectSetInteger(0, "ProgBar_BG", OBJPROP_BGCOLOR, g_ColBarBG);
    ObjectSetInteger(0, "ProgBar_BG", OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, "ProgBar_BG", OBJPROP_COLOR, clrNONE);

    ObjectCreate(0, "ProgBar_FG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "ProgBar_FG", OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, "ProgBar_FG", OBJPROP_XDISTANCE, startX);
    ObjectSetInteger(0, "ProgBar_FG", OBJPROP_YDISTANCE, startY + 2);
    ObjectSetInteger(0, "ProgBar_FG", OBJPROP_XSIZE, 0);
    ObjectSetInteger(0, "ProgBar_FG", OBJPROP_YSIZE, 20);
    ObjectSetInteger(0, "ProgBar_FG", OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, "ProgBar_FG", OBJPROP_COLOR, clrNONE);

    for(int i = 0; i < UI_LINES; i++) {
        string name = "UI_Line" + IntegerToString(i);
        ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        if(i == 0) {
            ObjectSetInteger(0, name, OBJPROP_XDISTANCE, startX + 130);
            ObjectSetInteger(0, name, OBJPROP_YDISTANCE, startY + 5);
        } else {
            ObjectSetInteger(0, name, OBJPROP_XDISTANCE, startX);
            ObjectSetInteger(0, name, OBJPROP_YDISTANCE, startY + (i * 20));
        }
        ObjectSetInteger(0, name, OBJPROP_COLOR, g_ColText);
        ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
        ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
        ObjectSetString(0, name, OBJPROP_TEXT, " ");
    }

    CreateButton("Btn_Sell", startX, startY + (8 * 20) + 10, "SELL", clrCrimson);
    CreateButton("Btn_Buy", startX + baseXSize + 10, startY + (8 * 20) + 10, "BUY", clrDodgerBlue);
}

void CreateButton(string name, int x, int y, string text, color bg) {
    ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_XSIZE, baseXSize);
    ObjectSetInteger(0, name, OBJPROP_YSIZE, baseYSize);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
}

// Writes one panel line and returns the next line index (silently ignores overflow).
int SetLine(int line, string text, color c) {
    if(line >= UI_LINES) return line;
    string name = "UI_Line" + IntegerToString(line);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetInteger(0, name, OBJPROP_COLOR, c);
    return line + 1;
}

void UpdatePanel(double bullPct, double bearPct, string trendText, string smcText, string ictText, bool ictOk, string srcText, EntryInfo &list[],
                 bool canBuy, bool canSell, int &trendList[], bool smcActive, int finalTrend) {
    string separator = "========================================";
    double maxPct = MathMax(bullPct, bearPct);
    int currentWidth = (int)MathRound((maxPct / 100.0) * 120);

    color trendColor = g_ColNeutral;
    if(bullPct > bearPct) trendColor = g_ColBuy;
    else if(bearPct > bullPct) trendColor = g_ColSell;

    ObjectSetInteger(0, "ProgBar_BG", OBJPROP_BGCOLOR, g_ColBarBG);

    ObjectSetInteger(0, "ProgBar_FG", OBJPROP_XSIZE, currentWidth);
    ObjectSetInteger(0, "ProgBar_FG", OBJPROP_BGCOLOR, trendColor);

    SetLine(0, trendText, trendColor);
    int line = SetLine(1, separator, g_ColText);

    if(ShowTrendDetails) {
        line = SetLine(line, "[+] STATUS TREND:", g_ColHighlight);

        string tNames[TREND_SLOTS] = {"VA/POC", "SMC Matrix", "SMC 2 (Medium)", "VWAP 1 (Harian)", "VWAP 2 (2-Hari)",
                                      "BBMA 1 (Kecil)", "BBMA 2 (Besar)", "MA Cross 1 (Kecil)", "MA Cross 2 (Besar)", "SMC 3 (Major)"};
        int activeTrendCount = 0;

        for(int i = 0; i < TREND_SLOTS; i++) {
            if(trendList[i] == -99) continue;
            if((i == 2 || i == 9) && smcActive) continue;

            color tCol = g_ColNeutral;
            if(i == 1 && smcActive) {
                tCol = (trendList[1] == 1) ? g_ColBuy : ((trendList[1] == -1) ? g_ColSell : g_ColWarn);
                line = SetLine(line, "- " + smcText, tCol);
            } else {
                string tStr = "";
                if(trendList[i] == 1)       { tStr = "BUYERS";  tCol = g_ColBuy; }
                else if(trendList[i] == -1) { tStr = "SELLERS"; tCol = g_ColSell; }
                else                        { tStr = "NETRAL";  tCol = g_ColNeutral; }
                string displayName = (i == 1) ? "SMC 1 (Minor)" : tNames[i];
                line = SetLine(line, "- " + displayName + " : " + tStr, tCol);
            }
            activeTrendCount++;
        }

        if(activeTrendCount == 0) line = SetLine(line, "- Semua Alat OFF", g_ColNeutral);
        line = SetLine(line, separator, g_ColText);
    }

    if(ictText != "") line = SetLine(line, "[ICT] " + ictText, ictOk ? g_ColBuy : g_ColWarn);
    line = SetLine(line, "[SRC] " + srcText, g_ColNeutral);
    line = SetLine(line, separator, g_ColText);

    line = SetLine(line, ">> ACTIVE ENTRY AREAS:", g_ColHighlight);

    int activeCount = 0;
    if(finalTrend != 0) {
        for(int i = 0; i < AREA_COUNT; i++) {
            if(!IsInZone(list[i]) || list[i].Type != finalTrend) continue;
            string dir = (list[i].Type == 1) ? "(Support)" : "(Resistance)";
            line = SetLine(line, "- " + list[i].Name + " : In Zone " + dir, (list[i].Type == 1) ? g_ColBuy : g_ColSell);
            activeCount++;
        }
    }
    if(activeCount == 0) line = SetLine(line, "- No Entry Area", g_ColNeutral);
    line = SetLine(line, separator, g_ColText);

    for(int i = line; i < UI_LINES; i++) ObjectSetString(0, "UI_Line" + IntegerToString(i), OBJPROP_TEXT, " ");

    int btnY = 20 + (line * 20) + 10;
    ObjectSetInteger(0, "Btn_Sell", OBJPROP_YDISTANCE, btnY);
    ObjectSetInteger(0, "Btn_Buy", OBJPROP_YDISTANCE, btnY);
    ObjectSetInteger(0, "Btn_Buy", OBJPROP_BGCOLOR, canBuy ? clrDodgerBlue : clrGray);
    ObjectSetInteger(0, "Btn_Sell", OBJPROP_BGCOLOR, canSell ? clrCrimson : clrGray);
    ChartRedraw();
}

void PressButton(string name, int baseX, int type) {
    int currentY = (int)ObjectGetInteger(0, name, OBJPROP_YDISTANCE);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, baseX + 2);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, currentY + 2);
    ObjectSetInteger(0, name, OBJPROP_XSIZE, pressXSize);
    ObjectSetInteger(0, name, OBJPROP_YSIZE, pressYSize);
    ChartRedraw();
    Sleep(100);

    color btnColor = (color)ObjectGetInteger(0, name, OBJPROP_BGCOLOR);
    bool allowed = (type == OP_BUY) ? CanOpenBuy() : CanOpenSell();
    if(TradingMode == MODE_AUTO || !allowed || btnColor == clrGray) {
        PlaySound("timeout.wav");
    } else {
        PlaySound("ok.wav");
        OpenMarketOrder(type);
    }

    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, baseX);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, currentY);
    ObjectSetInteger(0, name, OBJPROP_XSIZE, baseXSize);
    ObjectSetInteger(0, name, OBJPROP_YSIZE, baseYSize);
    ObjectSetInteger(0, name, OBJPROP_STATE, false);
    ChartRedraw();
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
    if(id == CHARTEVENT_CHART_CHANGE) { InitPanelColors(); return; }   // e.g. background colour changed
    if(id != CHARTEVENT_OBJECT_CLICK) return;
    if(sparam == "Btn_Buy")  PressButton("Btn_Buy", PanelXDistance + baseXSize + 10, OP_BUY);
    if(sparam == "Btn_Sell") PressButton("Btn_Sell", PanelXDistance, OP_SELL);
}
//+------------------------------------------------------------------+
