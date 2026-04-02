# TSFrames.jl Profile Analysis Results

Date: 2026-04-02  
Tool: Julia `Profile` module (flat format, sorted by count)  
Data: 1M rows OHLCV, 5 columns

---

## apply(Week, first) — 50 iterations, 1383 total samples

| Count | % | Location | Bottleneck |
|-------|---|----------|-----------|
| 1275 | 92% | `GenericMemory` (boot.jl:588) | Raw memory allocation (copy + fill) |
| 654 | 47% | `copy(df)` (dataframe.jl:805) | **DataFrame 全コピー at apply.jl:145** |
| 320 | 23% | `_growend!` / `array_new_memory` | fill+append! の動的配列拡張 |
| 307 | 22% | `apply.jl:140` | fill+append! ループ本体 |
| 187 | 14% | `groupby` | DataFrames groupby |
| 162 | 12% | `append!` | fill+append! のアペンド処理 |
| 141 | 10% | `fill` | 一時配列の生成 |
| 88 | 6% | `groupeddataframe.jl:250` | groupby 処理 |
| 76 | 5% | `_combine##4` | combine 処理 |

**主要ボトルネック:**
1. `copy(ts.coredata)` → 全サンプルの47%、最大のホットスポット
2. `fill+append!` ループ → 22-23%、143k回の動的配列拡張

---

## apply(Week, sum) — 20 iterations, 439 total samples

| Count | % | Location | Bottleneck |
|-------|---|----------|-----------|
| 400 | 91% | `GenericMemory` | メモリ割り当て |
| 222 | 51% | `_growend!` | fill+append! の配列拡張 |
| 216-217 | 49% | `_combine_process_agg` + `_combine##4` | combine 処理 |
| 209-210 | 48% | `groupreduce!` + `Reduce{sum}` | **sum の実計算** |
| 105 | 24% | `copy(df)` | DataFrame コピー |

**注目:** `sum` は全要素走査が必要なため `groupreduce!` が主コストになるが、  
`copy` と `_growend!` のオーバーヘッドがそれに匹敵するほど大きい。

---

## endpoints(Week) — 500 iterations, 436 total samples

| Count | % | Location | Bottleneck |
|-------|---|----------|-----------|
| 90 | 21% | `endpoints.jl:334` | ループ本体 |
| 68 | 16% | `sizehint!` + `_growend!` + `array_new_memory` | 結果ベクタの動的拡張 |
| 43 | 10% | `endpoints.jl:345` | ループ内の条件判定 |
| 41 | 9% | `range.jl: iterate` | 日付イテレーション |

**改善可能:** `push!(result, ep)` の代わりに事前確保 `Vector{Int}(undef, n_periods)` + index書き込みで `sizehint!` + `_growend!` を排除できる。ただし n_periods は事前にわからないため、まず `endpoints` を呼んでから alloc する必要あり（2-pass）か、上限推定値で確保する（例: n ÷ 7 + 1 for Week）。

---

## to_weekly() — 200 iterations, 1880 total samples

| Count | % | Location | Bottleneck |
|-------|---|----------|-----------|
| 673 | 36% | `GenericMemory` | メモリ割り当て |
| 570/559 | 30% | `getindex.jl:328,351` | 行インデックス選択 |
| 483 | 26% | `_threaded_getindex` + `getindex(Vector, Vector)` | スレッド化インデックス |
| 336 | 18% | `TSFrame` コンストラクタ + `sort` | **TSFrame 再構築時のソート** |
| 213+121 = 334 | 18% | `sort#417` + `sortperm` + `_sortperm` | **ソート処理（不要！）** |
| 223 | 12% | `copy` in constructor | コンストラクタ内コピー |

**重大発見:** `to_weekly()` の処理時間の **36%** がソートに費やされている。  
`endpoints()` が返すインデックスは**既にソート済み**なのに、  
`TSFrame` コンストラクタが毎回 `sort/sortperm` を実行している。  
`getindex(ts, Vector{Int})` → `TSFrame(df; issorted=true)` を渡せば解消可能。

---

## 改善優先度まとめ

| 優先度 | 対象 | 改善内容 | 期待効果 |
|--------|------|---------|---------|
| ★★★ | `to_weekly/monthly` | `TSFrame(df; issorted=true)` を渡す | ソート 36% を排除 |
| ★★★ | `apply()` | `copy(ts.coredata)` を避ける | 47% を排除（要設計変更） |
| ★★ | `apply()` | `fill+append!` → pre-alloc | 22-23% を削減（2.3x） |
| ★ | `endpoints()` | 結果ベクタの事前確保 | 16% を削減 |

---

## 注記
- `apply(Week, sum)` が `apply(Week, first)` より 3.4x 遅い主因: `groupreduce!` の実計算コスト（O(n)スキャン）
- `to_weekly` の `_threaded_getindex` はマルチスレッド処理で、1M行のコピーに時間がかかる
