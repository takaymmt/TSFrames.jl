# TSFrames.jl TODO

## Closed Issues

### [x] construction: from_matrix_and_dates / from_vector_and_dates が約2x 遅化

**解決済み (v0.3.2)**

**根本原因**: コミット `2f7b343` のバグ修正で `copy(coredata)` → `coredata[perm, :]` に変更したが、
ソート済みデータでも常に `permute!` が走りコストが2倍になっていた。

**修正内容** (`src/TSFrame.jl`):
1. `coredata[perm, :]` → `copy(coredata)` + `permute!(cd, perm)` に変更（案A）
2. `elseif Base.issorted(index)` fast path を追加 — ソート済みの場合は `sortperm+permute!` をスキップ

**ベンチ結果** (`benchmark/results/report_v0.3.2_vs_v0.2.2.md`):
| ベンチマーク | v0.2.2 | v0.3.1 | v0.3.2 |
|---|---|---|---|
| large/from_matrix_and_dates | 910 us | 1.93 ms (2.1x slow) | 889 us (~1.0x) ✅ |
| large/from_vector_and_dates | 656 us | 1.43 ms (2.2x slow) | 639 us (~1.0x) ✅ |
| medium/from_matrix_and_dates | 10.7 us | 21.6 us (2.0x slow) | 10.5 us (~1.0x) ✅ |
| medium/from_vector_and_dates | 7.5 us | 16.1 us (2.2x slow) | 7.4 us (~1.0x) ✅ |

---

## Open Issues

### [ ] resample.jl / apply.jl コードレビュー（P1）

前バージョン（Wave 1+2）で実装した resample.jl, apply.jl の品質確認。
- 型バリアパターンの正確性
- エラーハンドリングの適切さ
- ドキュメントコメントの充実

### [ ] テスト改善 — エッジケース網羅（P1）

`test/resample.jl` への追加（現状42テスト）:
- 空 TSFrame
- 1行のみ
- 型多様性（Float32, Int 等）
- 全 NaN / missing 列

### [ ] resample() をベンチスイートに追加（P1）

`benchmark/suites/bench_resample_vs_to_period.jl` が存在するが、
`benchmarks.jl` の `SUITE` への登録が条件付き（バージョン互換ガード）になっているか確認・整備。

### [ ] apply() への型バリア適用（P2・任意）

resample() で適用した型バリアパターン (`_build_index_out` 等) を apply() にも適用。
理論上 3x 改善の可能性。

### [ ] gap-aware resampling / fill_gaps=true（P3・任意）

resample() に `fill_gaps=true` オプションを追加。
欠損期間を NaN/missing で埋める。

### [ ] VWAP 対応検討（P4・任意）

出来高加重平均価格の計算サポート。要件定義から。
