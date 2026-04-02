# TSFrames.jl Baseline Benchmark Results

Date: 2026-04-02  
Julia version: 1.12  
Hardware: Darwin 25.3.0 (Apple Silicon)  
BenchmarkTools: v1.7.0, seconds=10, samples=100

---

## Summary Table

| Operation              | 100k rows | 1M rows   | Allocs (1M)      |
|------------------------|-----------|-----------|-----------------|
| endpoints(Week)        | 0.04 ms   | 0.42 ms   | 4 allocs         |
| endpoints(Month)       | 0.09 ms   | 0.93 ms   | 4 allocs         |
| apply(Week, first)     | 0.85 ms   | 7.57 ms   | **143,562 allocs** |
| apply(Month, first)    | —         | 17.63 ms  | **33,559 allocs**  |
| apply(Week, sum)       | —         | 26.02 ms  | **143,562 allocs** |
| to_weekly              | 0.17 ms   | 1.62 ms   | 145 allocs       |
| to_monthly             | —         | 1.45 ms   | 145 allocs       |

---

## apply() Internals Breakdown (1M rows, Week(1))

| Step              | Time      | % of total | Notes                          |
|-------------------|-----------|------------|--------------------------------|
| endpoints()       | 0.43 ms   | 6%         | 速い、4 allocations のみ        |
| fill+append! loop | **1.75 ms** | **24%**  | 143k+ allocations → 要改善      |
| copy(coredata)    | 0.74 ms   | 10%        | DataFrame 全コピー              |
| groupby()         | 1.96 ms   | 27%        | DataFrames 内部処理             |
| combine()         | **2.20 ms** | **30%**  | DataFrames 内部処理、最大ボトルネック |
| **合計**          | **7.08 ms** | 100%     | 実測 7.57ms と整合              |

---

## Alternative: Pre-allocated groupindices

| 手法              | 時間      | 削減率   |
|-------------------|-----------|---------|
| fill+append! (現行) | 1.75 ms | ベース  |
| pre-alloc + view  | **0.75 ms** | **57% 削減 (2.3x 高速)** |

---

## Bottleneck Analysis

### 1位: combine() — 2.20ms (30%)
DataFrames.jl の内部処理。現状のアーキテクチャを維持する限り変更困難。
ただし、per-column aggregation を追加しても同じ1パスなので増加しない。

### 2位: groupby() — 1.96ms (27%)
DataFrames.jl の内部処理。temp 列を使う現在の設計に起因。

### 3位: fill+append! loop — 1.75ms (24%)
**修正可能**: pre-alloc + `.=` で 0.75ms まで削減 (2.3x speedup)。
現行: `append!(groupindices, fill(ep[i], ...))` → 週ごとに一時配列生成 (143k allocs)
改善: `groupindices[j:ep[i]] .= ep[i]` → 事前確保、ゼロ追加アロケーション

### 4位: copy(coredata) — 0.74ms (10%)
DataFrame 全コピー。temp 列追加のために必要。
回避するには DataFrames の groupby を temp 列なしで行う別アーキテクチャが必要。

---

## Scaling Behavior

| 倍率        | endpoints | apply(Week,first) |
|-------------|-----------|-------------------|
| 100k → 1M   | 10x データ | 10x データ         |
| 実測比       | ~10x      | ~9x               |

→ ほぼ線形スケーリング (O(n))。良好。

---

## Key Observations

1. **`endpoints()` は既に最適**: 0.42ms/1M rows、4 allocations のみ。手を入れる必要なし。
2. **`to_weekly()` は高速**: 1.62ms/1M rows — aggregation なしのため当然。
3. **`apply()` の主要コストは DataFrames オーバーヘッド** (groupby + combine = 57%)。
4. **fill+append! loop が最大の改善機会**: 24% を 10% 未満に削減できる。
5. **apply(sum) が apply(first) より 3.4x 遅い** (26ms vs 7.6ms)。
   `sum` は全要素走査が必要なため当然だが、DataFrames の combine overhead も大きい。
6. **143,562 allocations** は週次集約 (1M行÷7日≒143K週) に相当。fill() が週ごとに1配列生成している証拠。

---

## Recommendations (pre-implementation)

1. `_build_groupindices(ep, nrows)` を抽出して pre-alloc 実装に変更 → fill+append! の 2.3x 改善
2. `copy(coredata)` を避けるアーキテクチャ（低優先度、DataFrames API の制約あり）
3. OHLCV 特化の手動ループ実装（@view スライス）で groupby/combine をバイパスできれば理論上 3-4x 高速化可能だが、保守性とのトレードオフ
