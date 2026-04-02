# TSFrames.jl Benchmark Results — After Wave 1 Optimizations

Date: 2026-04-02  
Commit: 55e7c2b  
Changes: _build_groupindices pre-alloc + to_period issorted=true

---

## Comparison: Baseline vs After

| Operation           | Baseline   | After      | 改善率  | Allocs (Baseline) | Allocs (After) |
|---------------------|-----------|-----------|--------|-------------------|----------------|
| endpoints(Week)     | 0.42 ms   | 0.40 ms   | -5%    | 4                 | 4              |
| endpoints(Month)    | 0.93 ms   | 0.90 ms   | -3%    | 4                 | 4              |
| apply(Week,  first) | 7.57 ms   | **6.11 ms**   | **-19%** | 143,562         | **677** (-99.5%) |
| apply(Month, first) | 17.63 ms  | **10.46 ms**  | **-41%** | 33,559          | **677** (-98%)   |
| apply(Week,  sum)   | 26.02 ms  | **18.11 ms**  | **-30%** | 143,562         | **677** (-99.5%) |
| to_weekly()         | 1.62 ms   | **1.04 ms**   | **-36%** | 145             | **42** (-71%)    |
| to_monthly()        | 1.45 ms   | **1.24 ms**   | **-14%** | 145             | **42** (-71%)    |

---

## Remaining apply() Internals (1M rows, Week, first)

| Step              | Time    | %    | Notes                     |
|-------------------|---------|------|---------------------------|
| endpoints()       | 0.42 ms |  7%  | 最適済み                   |
| fill+append! (旧) | 1.71 ms |  —   | ※ 参考値（現在は未使用）    |
| pre-alloc (現在)  | 0.73 ms | 12%  | ✅ 改善済み                |
| copy(coredata)    | 0.71 ms | 12%  | ← 次の最適化対象 (P1)      |
| groupby()         | 1.92 ms | 31%  | DataFrames 内部            |
| combine()         | 2.08 ms | 34%  | DataFrames 内部            |

---

## Key Observations

1. **アロケーション数が劇的に削減**: 143,562 → 677 (99.5%削減)
   - pre-alloc で fill+append! の週ごとの一時配列生成がゼロに
2. **apply(Month) が最大改善**: -41%
   - 月次グループは数が少ない分、fill+append! の相対コストが大きかった
3. **to_weekly が -36%**: issorted=true でソートスキップが効果的
4. **copy(coredata) が次のボトルネック**: 0.71ms, 12%
   - groupby()/combine() (65%) と並んで改善余地あり
5. **apply(Week, sum)**: 26.02ms → 18.11ms (-30%)
   - sum 自体は O(n) なので combine() コストが支配的。copy 削減の効果も大きい

---

## Remaining Bottleneck (P1 対象)

```
copy(coredata):  0.71ms  12%  → P1 で排除目標
groupby():       1.92ms  31%  → copy排除 + 手動ループなら不要
combine():       2.08ms  34%  → copy排除 + 手動ループなら不要

P1 で排除できれば apply(Week,first) は理論上:
  6.11ms - (0.71+1.92+2.08)ms ≈ 1.4ms (77% 削減) ← 理論上限
  現実的には: 2-3ms 程度（@view スライス + 手動ループ）
```
