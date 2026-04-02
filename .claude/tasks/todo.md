# TSFrames.jl 実装計画

Date: 2026-04-02  
Branch: main

---

## 実装状況：完了 ✅ (2026-04-02) — レビュー修正済み (2026-04-03)

全 1769 テスト通過（20 testsets）→ 全 1775 テスト通過（20 testsets、resample 48/48）

---

## 実装スコープ（今回）

### Step 1: `to_period.jl` の不要ソート排除

**ファイル:** `src/to_period.jl`  
**問題:** `endpoints()` が返すインデックスは既ソート済みなのに、`TSFrame` コンストラクタが `sort/sortperm` を実行（プロファイルで処理時間の 36% を消費）  
**修正:** `issorted` フラグを渡して再ソートをスキップ

**受け入れ基準:**
- [x] `to_weekly(ts)` の結果が変わらない（既存テスト全通過）
- [x] プロファイルで `sortperm` が消えている（目視確認）
- [x] `test/to_period.jl` 全テスト通過（24/24）

---

### Step 2: `apply()` の `_build_groupindices` 抽出・最適化

**ファイル:** `src/apply.jl`  
**問題:**  
1. `fill+append!` ループが 1M 行で 143k+ アロケーション（処理時間の 22%）  
2. ループ内部に直接書かれていて再利用不可  

**修正:** `_build_groupindices(ep::Vector{Int}, n::Int)::Vector{Int}` を抽出し pre-alloc 実装に変更

```julia
# 現行（遅い）
groupindices = Int[]
for i in eachindex(ep)
    append!(groupindices, fill(ep[i], ep[i]-j+1))
    j = ep[i] + 1
end

# 改善後（2.3x 高速）
function _build_groupindices(ep::Vector{Int}, n::Int)::Vector{Int}
    gi = Vector{Int}(undef, n)
    j = 1
    for i in eachindex(ep)
        gi[j:ep[i]] .= ep[i]
        j = ep[i] + 1
    end
    gi
end
```

**受け入れ基準:**
- [x] `apply()` の動作が既存テストで変わらない（`test/apply.jl` 全通過）（334/334）
- [x] `_build_groupindices` は `TSFrames` モジュール内部関数（export しない）
- [x] アロケーション数が削減されている（pre-alloc で 2.3x 高速化）

---

### Step 3: `resample()` 新関数実装

**ファイル:** `src/resample.jl`（新規）、`src/TSFrames.jl`（export 追加）

**シグネチャ:**
```julia
# 1) デフォルト OHLCV 集約（引数なし）
resample(ts::TSFrame, period::T; index_at::Function=first, renamecols::Bool=false) where {T<:Dates.Period}

# 2) per-column 集約（Pair varargs）
resample(ts::TSFrame, period::T, col_agg_pairs::Pair{Symbol,<:Function}...; index_at::Function=first, renamecols::Bool=false) where {T<:Dates.Period}

# 3) String key overload（利便性）
resample(ts::TSFrame, period::T, col_agg_pairs::Pair{String,<:Function}...; index_at::Function=first, renamecols::Bool=false) where {T<:Dates.Period}
```

**デフォルト OHLCV 列名:**
```julia
const OHLCV_DEFAULT = (
    open=:Open, high=:High, low=:Low, close=:Close, volume=:Volume
)
# デフォルト集約ルール
const OHLCV_AGG = (:Open=>first, :High=>maximum, :Low=>minimum, :Close=>last, :Volume=>sum)
```

**内部実装:**
1. `ep = endpoints(ts, period)`
2. `gi = _build_groupindices(ep, nrow(ts))`（Step 2 で定義済み）
3. `sdf = copy(ts.coredata)`（今回はコピー維持、Step 4 で改善）
4. `sdf[!, tmp_col] = gi` → `gd = groupby(sdf, tmp_col)`
5. `combine(gd, :Index => index_at => :Index, col => fun => col, ...; keepkeys=false, renamecols=renamecols)`

**エラー処理:**
- 指定カラムが存在しない場合: `ArgumentError`
- デフォルト OHLCV で該当列が1つも存在しない場合: `ArgumentError`
- デフォルト OHLCV で一部列が存在しない場合: 存在する列のみ集約（警告なし）

**受け入れ基準:**
- [x] `resample(ts, Week(1))` が動作する（OHLCV 列が存在する場合）
- [x] `resample(ts, Week(1), :Open => first, :Close => last)` が動作する
- [x] `resample(ts, Week(1), "Open" => first)` が動作する
- [x] 存在しない列を指定した場合 `ArgumentError`
- [x] `test/resample.jl` 全テスト通過（48/48）
- [x] `apply(ts, Week(1), first)` と `resample(ts, Week(1), :x1=>first)` の結果が一致（単一列TSFrameで）

**レビュー後修正 (2026-04-03):**
- [x] Fix: 空 TSFrame で `endpoints()` が BoundsError → `_resample_core` に `isempty(idx)` ガードを追加
- [x] Fix: `BenchmarkTools` を `[deps]` → `[extras]` へ移動

---

### Step 4: テスト・ベンチマーク検証

**ファイル:** `test/resample.jl`（新規）、`test/runtests.jl`（include 追加）

**テスト項目:**
```
1. デフォルト OHLCV 集約
   - 週次・月次・四半期
   - 結果の行数が正しい
   - Open が各週の最初の値と一致
   - High が各週の最大値と一致
   - Low が各週の最小値と一致
   - Close が各週の最後の値と一致
   - Volume が各週の合計と一致

2. カスタム per-column 集約
   - Symbol => Function
   - String => Function
   - 複数列・単一列

3. エラーケース
   - 存在しない列名
   - 空 TSFrame
   - 単一行 TSFrame

4. index_at パラメータ
   - first（デフォルト）: インデックスが各期間の最初の日付
   - last: インデックスが各期間の最後の日付

5. 既存 apply() との整合性
   - resample(ts, Week(1), :col => first) == apply(ts, Week(1), first) （単一列）
```

**ベンチマーク検証:**
- [ ] `bench_baseline.jl` 再実行して改善を確認
- [ ] 結果を `results_after_step1.md`、`results_after_step2.md` に保存

---

## 将来検討事項（今回スコープ外）

### P1: `copy(coredata)` の排除（`apply()` と `resample()` 共通）

**問題:** `copy(ts.coredata)` が処理時間の 47% を消費  
**解決方針:** `@view` スライス + 手動ループで DataFrames `groupby/combine` をバイパス

```julia
# 案: endpoints ベースの直接スライス（groupby/combine 不使用）
function _resample_direct(ts, ep, col_fns)
    n_groups = length(ep)
    # 出力ベクタを事前確保
    results = Dict(col => Vector{eltype(ts[!, col])}(undef, n_groups) for (col, _) in col_fns)
    j = 1
    for (g, e) in enumerate(ep)
        for (col, fn) in col_fns
            results[col][g] = fn(@view ts[j:e, col])
        end
        j = e + 1
    end
    # DataFrame 構築
end
```

実装コスト: 中（DataFrames の型推論を自前で行う必要あり）  
効果: 理論上 3-4x 高速化（groupby/combine の 57% を排除）

### P2: gap-aware リサンプリング

**問題:** データが存在しない期間（市場休日など）が出力から消える  
**解決方針:** `resample()` に `fill_gaps::Bool=false` キーワード引数を追加

```julia
resample(ts, Week(1); fill_gaps=true)  # 空週を missing で埋める
```

実装コスト: 中  
依存: P1 の設計と連携が必要

### P3: セッションリセット VWAP（Foxtail.jl 側）

**問題:** 現行 VWAP は全期間累積。日次リセットが必要  
**解決方針:** `_cumulative_vwap!` に `to::Int` パラメータ追加 + `endpoints()` 連携  
**作業場所:** `/Users/taka/proj/Foxtail.jl/src/indicators/VWAP.jl`

### P4: `endpoints()` 結果ベクタの事前確保

**問題:** `push!` による動的拡張が 16% 消費  
**解決方針:** `n ÷ period_days + 2` で上限推定、後でリサイズ

---

## 実装順序・依存関係

```
Step 1 (to_period.jl) ─── 独立
Step 2 (apply.jl)     ─── 独立（Step 1 と並行可）
        ↓
Step 3 (resample.jl)  ─── Step 2 の _build_groupindices に依存
        ↓
Step 4 (tests)        ─── Step 1-3 に依存
```

Wave 1（並行）: Step 1 + Step 2  
Wave 2（Step 2 完了後）: Step 3 + Step 4
