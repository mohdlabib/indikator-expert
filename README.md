# KG Trading Anti Fomo M5 (MT4 Expert Advisor)

MetaTrader 4 Expert Advisor that combines trend votes (SMC BOS/CHoCH matrix, VA/POC,
VWAP, BBMA, MA cross) with entry-area confluence (VA, POC, SnD, Order Blocks, SMC/KG Fibo,
VWAP, BBMA, KG SupDem) and an Awesome Oscillator pullback confirmation.

File: `KG_Trading_Anti_Fomo_M5.mq4` (version 10.0).

## Requirements

The EA reads chart objects drawn by these indicators, so they must be on the same chart:

1. KG Market Profile / Volume Profile (VA & POC)
2. KG Zigzag Line (SnD)
3. KG BOS CHOCH OrderBlock (OB, SMC trend, SMC Fibo) — one instance per `SMC*_Prefix`
4. KG Fibo Dinamis Button (KG Fibo)
5. KG SupDem Button (SupDem zones and SupDem Fibo)

## Installation

1. Copy `KG_Trading_Anti_Fomo_M5.mq4` to `MQL4/Experts/` in the MT4 data folder.
2. Compile it in MetaEditor (F7) and confirm there are 0 errors.
3. Attach it to the chart that already has the indicators above, enable AutoTrading.
4. Existing `.set` files still load: no existing input was renamed or removed.

## Changes in 10.0

### Bug fixes

- **SMC Fibo false zones.** Fibo levels were detected with `StringFind(name, "50")` etc., so any
  object of the same prefix (Order Blocks, BOS/CHoCH lines) whose name contains a timestamp such
  as `1700050000` was treated as a Fibo level. Levels now require a standalone `50/61/78/100`
  token and OB/BOS/CHoCH objects are excluded. Expect fewer, cleaner Fibo-based entries.
- **KG Fibo** now ignores objects of all four SMC prefixes (previously only SMC 1 and 2).
- **KG SupDem Fibo** returned distance `0` (= "in zone") when no object existed; it now returns
  "no zone".
- **Loose trend validity** used `>= 50%`, so a 50/50 split resolved to BUY. It now requires
  strictly more than 50%, as the input description says.
- **2-day VWAP** double-counted the first bars of today; every bar is now counted once.
- **SMC Matrix BB filter** read BB values that were only calculated when BBMA entry/trend inputs
  were enabled; they are now calculated whenever the filter needs them.
- **VA/POC colour tracking** kept deleted objects forever, so stale colours still voted; deleted
  objects are now pruned.
- **SL/TP** are calculated from the actual fill price (not the requested price), normalized,
  and checked against the broker stop/freeze level. Initial SL/TP are clamped to the minimum
  distance instead of being rejected.
- **Smart BEP** triggered immediately when `TakeProfitPips = 0` (trigger distance 0). The trigger
  is now based on the order's real TP distance and is skipped when there is no TP.
- **Slippage** is converted to points consistently for every open/close (closes used raw pips).
- **Lot size** is rounded down to the lot step so the risk never exceeds `RiskPercent`; free
  margin is checked before sending the order.
- Panel lines no longer write past the 35 available labels.
- Panel was unreadable on light chart backgrounds (white/yellow/light-green text on white). Colours
  now follow the chart background and update when the background colour changes.

### Changed defaults

`PanelXDistance = 1550`, `PanelTextColor = clrBlack`, `HighlightColor = clrMediumBlue`,
`SMC1_Prefix = SMC_M5_`, `SMC2_Prefix = SMC_H1_`, `SMC3_Prefix = SMC_H4_` (matching the KG BOS
CHOCH OrderBlock instances used on the M5/H1/H4 setup). Values from a loaded `.set` file still
take precedence.

### Efficiency

- Signal analysis (chart object scanning) is throttled by `AnalysisIntervalMs` and always runs on
  a new bar; protection logic (hidden SL/TP, BEP, trailing) still runs on every tick.
- Chart object names are read once per analysis pass and shared by all scanners.
- VWAP and BBMA values are computed once per pass instead of up to twice.
- Daily entry counts are cached and only recomputed when orders or the day change.
- History-object cleanup and hidden-SL/TP global-variable cleanup run at most once per second.
- The duplicated SMC matrix branches (about 200 lines) were consolidated into helpers with
  identical decisions and panel texts.
- Repeated identical error messages are logged at most once per minute.

### New inputs (defaults in brackets)

| Input | Purpose |
| --- | --- |
| `AO_UseClosedBar` (`true`) | AO filter compares closed bars 1 vs 2 (no repaint). Set `false` for the previous real-time bar 0 vs 1 behaviour. |
| `FixedLotSize` (`0`) | Fixed lot; `0` keeps risk-based sizing. |
| `MaxSpreadPips` (`0` = off) | Blocks new entries while the spread is above this value. |
| `MaxDailyLossPct` (`0` = off) | Blocks new entries for the day once closed + floating P/L of managed orders reaches `-X%` of the day's starting balance. |
| `AutoPanelColors` (`true`) | Picks panel text/status colours from the chart background (dark text on light charts, light text on dark charts) so the dashboard stays readable. Set `false` to use `PanelTextColor` / `HighlightColor`. |
| `AnalysisIntervalMs` (`250`) | Minimum time between signal analyses; `0` = every tick. Strategy Tester always runs every tick. |

## Notes

- `RiskPercent` cannot go below the broker's minimum lot: when the calculated lot is smaller,
  the minimum lot is used, so the real risk can be higher than configured.
- With `UseHiddenSLTP = true` there is no stop loss on the broker side. If the terminal is
  offline, positions are unprotected.
- The EA has not been compiled or back-tested in this repository; compile it in MetaEditor and
  validate it in the Strategy Tester / on a demo account before using it live.
