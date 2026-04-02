# TSFrames.jl TODO

## Open Issues

### [ ] construction: from_matrix_and_dates / from_vector_and_dates が約2x 遅化

**発見経緯**: xKDR v0.2.2 vs fork v0.3.1 ベンチマーク比較  
**レポート**: `benchmark/results/report_v0.3.1_vs_v0.2.2.md`

| ベンチマーク | v0.3.1 | xKDR v0.2.2 | 劣化倍率 |
|---|---|---|---|
| large/from_matrix_and_dates | 1.93 ms | 910.38 us | **2.1x 遅い** |
| large/from_vector_and_dates | 1.43 ms | 655.83 us | **2.2x 遅い** |
| medium/from_matrix_and_dates | 21.58 us | 10.71 us | **2.0x 遅い** |
| medium/from_vector_and_dates | 16.12 us | 7.5 us | **2.2x 遅い** |
| small/from_matrix_and_dates | 1.25 us | 1.0 us | 1.2x 遅い |
| small/from_vector_and_dates | 791.0 ns | 625.0 ns | 1.3x 遅い |

**調査方針**:
- `src/TSFrame.jl` の matrix / vector コンストラクタを v0.2.2 と diff
- コミット `2da2340`（"optimize apply()"）前後で変化があるか確認
- DataFrames バージョン差異（v0.2.2: 1.7.0 / v0.3.1: 1.8.1）が影響している可能性も検討
