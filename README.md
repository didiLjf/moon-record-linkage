# Moon Record Linkage

[![MoonBit](https://img.shields.io/badge/MoonBit-stable-3678ff.svg)](https://www.moonbitlang.com/)
[![License](https://img.shields.io/badge/License-Apache--2.0-2ea44f.svg)](LICENSE)
[![CI](https://github.com/didiLjf/moon-record-linkage/actions/workflows/test.yml/badge.svg)](https://github.com/didiLjf/moon-record-linkage/actions/workflows/test.yml)

MoonBit 原生实体匹配、记录链接与去重引擎，适用于 CRM、ERP、账单和数据治理场景。本项目参加 **2026 年 8 月官方 MoonBit 黑客松**，提供从数据质量检查、候选生成、相似度评分到实体合并和结果导出的完整流程。

## Features

- **数据质量与血缘**：schema 推断、字段缺失/类型校验、重复 ID 检测、来源分布和字段血缘报告。
- **候选生成**：Standard Blocking、Sorted Neighborhood、Canopy、LSH 以及组合策略，支持候选去重、预算限制和统计分析。
- **相似度与模型**：编辑距离、Jaro-Winkler、N-gram、数值/地理相似度、Soundex、Metaphone、NYSIIS、MRA、规则模型和 Fellegi-Sunter/EM。
- **可解释决策**：输出字段贡献、加权分数、阈值判断、校准结果和 Match / PossibleMatch / NonMatch 状态。
- **实体图与合并**：DSU 聚类、冲突证据、canonical record 选择和多种合并策略。
- **生产流程能力**：批处理、分页、重试、增量状态、审计轨迹、结果分析和 JSON/CSV/Markdown 导出。
- **可复现评测**：确定性合成数据、真实工具链计时、场景套件、基准矩阵和聚合报告。

## Architecture

```text
src/core/          数据模型、配置、质量校验、schema、质量汇总、字段血缘
src/normalization/ 文本清洗、中文域规则、分词、记录规范化审计
src/phonetic/      Soundex、Metaphone、NYSIIS、MRA
src/similarity/    编辑距离、Jaro-Winkler、token、数值、地理相似度
src/blocking/      Blocking 算法、候选计划、统计和自适应策略
src/model/         规则、Fellegi-Sunter、混合/集成评分、解释和校准
src/graph/         DSU、实体图、冲突检测、证据和 canonical merge
src/pipeline/      批处理、分页、重试、增量状态、审计和结果分析
src/evaluation/    合成数据、评测指标、基准、场景套件和矩阵聚合
src/export/        质量、血缘、候选、评测和汇总报告导出
src/main/          CLI 演示与命令解析
cmd/main/          可执行入口
```

运行时数据流：

```text
records → quality checks → normalization → blocking
        → field comparison → scoring → graph clustering
        → canonical merge → metrics and export
```

## Requirements

- MoonBit stable toolchain
- Git（从源码构建时需要）

查看当前工具链：

```bash
moon version --all
```

## Quick start

在仓库根目录执行：

```bash
moon update
moon fmt --check
moon info
moon check --deny-warn --target all
moon test --deny-warn --target wasm-gc
```

Unix 环境还可以运行 native 测试和全目标构建：

```bash
moon test --deny-warn --target native
moon build --target all
```

Windows CI 使用 wasm-gc 作为可移植验证目标；当前 stable 工具链的 Windows native runtime 仍存在 `rand_s` 编译兼容性问题。

## CLI

运行内置质量概览：

```bash
moon run cmd/main -- quality
```

运行确定性基准：

```bash
moon run cmd/main -- benchmark --records 1000 --seed 20260818
```

基准程序覆盖合成数据生成、Blocking、评分和指标计算，并使用工具链时钟记录运行时间。输出中的候选数、precision、recall、F1、candidate reduction 和 elapsed ticks 均来自实际运行。

## Library usage

```moonbit
import {
  "didiLjf/moon-record-linkage/src/core" @core,
  "didiLjf/moon-record-linkage/src/pipeline" @pipeline,
}

let config = @core.LinkageConfig::new("customer-dedup")
config.add_blocking(@core.StandardBlocking(["city"]))
config.add_field_comparison("name", @core.JaroWinkler, weight=2.0)
config.add_field_comparison("phone", @core.ExactMatch, weight=1.0)
config.set_thresholds(0.80, 0.45)

let pipeline = @pipeline.BatchPipeline::new(config)
let result = pipeline.run_link(left_records, right_records)
```

质量门禁和报告可以独立使用：

```moonbit
let profile = @core.quality_summary(records)
let gate = profile.evaluate_gate(
  max_missing_rate=0.20,
  max_duplicate_rate=0.05,
)
```

## Benchmark

以下是 `1000` 个实体、seed `20260818` 的一次实际运行结果：

| Metric | Value |
| --- | ---: |
| entities / left / right | 1000 / 1000 / 1000 |
| gold links | 1000 |
| candidate pairs | 990 |
| predicted matches | 990 |
| precision / recall / F1 | 1.0 / 0.99 / 0.9949748743718593 |
| candidate reduction | 0.99901 |
| elapsed ticks | 23 |
| records per 1,000 ticks | 43478.260869565216 |

这是默认五城市、双路复合 Blocking 场景的压力基线：候选空间从 1,000,000 降至 990，并在 10% 确定性字段噪声下保持 0.99 recall。该数据用于复核候选规模和运行性能，不代表特定业务数据的精度承诺；实际项目仍应结合字段权重、组合/交集 Blocking 和 `calibrate_thresholds` 调整策略。`elapsed_ticks` 会随机器和运行环境变化。

如需重新生成统计：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/count_moonbit_lines.ps1
```

## Testing and CI

测试覆盖相似度、规范化、Blocking、模型、图聚类、流水线、评测和导出模块，并包含空数据、缺失字段、重复 ID、边界阈值、候选预算和重试等场景。

CI 配置位于 `.github/workflows/test.yml`：

- Ubuntu、macOS、Windows stable toolchain；
- `moon fmt --check`、`moon info`、`moon check --deny-warn`；
- wasm-gc 全平台验证，Unix 额外验证 native 和 all-target build；
- CLI smoke test；
- `.github/workflows/publish.yml` 提供手动 Mooncakes 发布入口。

## License

[Apache License 2.0](LICENSE)
