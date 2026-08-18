# Moon Record Linkage

[![MoonBit](https://img.shields.io/badge/MoonBit-stable-blue.svg)](https://www.moonbitlang.com/)
[![License](https://img.shields.io/badge/License-Apache--2.0-green.svg)](LICENSE)
[![CI](https://github.com/didiLjf/moon-record-linkage/actions/workflows/test.yml/badge.svg)](https://github.com/didiLjf/moon-record-linkage/actions/workflows/test.yml)

MoonBit 原生实体匹配、记录链接与去重引擎。本项目参加的是 **2026 年 8 月官方 MoonBit 黑客松**，当前版本面向项目验收，重点是可运行的记录治理流程、可解释匹配、可复现实测基准和跨目标 CI。

## 能解决什么问题

- 对 CRM、账单、ERP 等来源的异构记录进行规范化、质量检查和字段血缘分析。
- 用 Standard Blocking、Sorted Neighborhood、Canopy、LSH 和组合策略缩小候选空间。
- 用编辑距离、Jaro-Winkler、N-gram、数值/地理相似度和语音编码构建可解释分数。
- 用 Fellegi-Sunter/EM、规则和集成评分处理 Match、PossibleMatch、NonMatch。
- 用实体图、DSU 和规范化合并生成实体簇，并导出 JSON、CSV、Markdown 报告。
- 通过确定性合成数据、真实工具链计时、阈值校准和基准矩阵评估运行结果。

## 仓库结构

```text
src/core/          数据模型、质量校验、质量汇总、配置、schema、血缘
src/normalization/ 清洗、中文域规则、分词、记录规范化审计
src/phonetic/      Soundex、Metaphone、NYSIIS、MRA
src/similarity/    编辑距离、Jaro-Winkler、token、数值、地理
src/blocking/      Blocking 算法、候选计划、统计与自适应建议
src/model/         规则、Fellegi-Sunter、混合/集成、解释、校准
src/graph/         DSU、实体图、冲突证据、canonical merge
src/pipeline/      批处理、分页、重试、增量状态、审计轨迹、结果分析
src/evaluation/    确定性数据生成、评测指标、基准、场景套件、矩阵聚合
src/export/        JSON/CSV/Markdown 质量、血缘、候选、评测与验收包
src/main/          CLI 参数、benchmark/quality 演示
cmd/main/          可执行入口
```

## 快速开始

安装 stable MoonBit 工具链后执行：

```bash
moon version --all
moon update
moon fmt --check
moon info
moon check --deny-warn --target all
moon test --deny-warn --target all
moon test --deny-warn --target native
```

运行质量概览和可复现基准：

```bash
moon run cmd/main -- quality
moon run cmd/main -- benchmark --records 1000 --seed 20260818
```

基准程序使用工具链时钟测量完整的合成数据生成、Blocking、评分和指标计算流程；输出中的 `elapsed_ticks`、候选数、precision、recall、F1 和 reduction 均来自本次实际运行，不是静态样例。当前 Windows 源码规模统计命令为：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/count_moonbit_lines.ps1
```

## 当前验收基线

以下是本次结项工作区实际测得的一次 1,000 实体基准（seed `20260818`）：

| 指标 | 实测值 |
| --- | ---: |
| entities / left / right | 1000 / 1000 / 1000 |
| gold links | 1000 |
| candidate pairs | 100000 |
| predicted matches | 100000 |
| precision / recall / F1 | 0.005 / 0.5 / 0.009900990099009901 |
| candidate reduction | 0.9 |
| elapsed ticks | 362 |
| records per 1,000 ticks | 2762.4309392265195 |

这是当前默认合成场景的压力基线：五城市 Blocking 能把 1,000,000 个笛卡尔候选降到 100,000，但也明确暴露了宽 Blocking 下的误报率，便于验收时复核阈值和策略。生产数据应使用 `CandidatePlan` 的组合/交集策略、字段权重和 `calibrate_thresholds` 进行调参，而不是把该压力场景当成业务精度承诺。

当前源码统计为 **8,001 行非空生产 MoonBit 代码、7,151 行生产代码行**；测试文件 33 个，测试非空行 1,617 行。统计脚本排除了 `_test.mbt`、`_wbtest.mbt`、生成接口和构建产物，避免把测试或缓存冒充生产规模。

## API 示例

```moonbit
let config = @core.LinkageConfig::new("customer-dedup")
config.add_blocking(@core.StandardBlocking(["city"]))
config.add_field_comparison("name", @core.JaroWinkler, weight=2.0)
config.add_field_comparison("phone", @core.ExactMatch, weight=1.0)
config.set_thresholds(0.80, 0.45)

let pipeline = @pipeline.BatchPipeline::new(config)
let result = pipeline.run_link(crm_records, erp_records)
let profile = @core.quality_summary(crm_records)
let gate = profile.evaluate_gate(max_missing_rate=0.2, max_duplicate_rate=0.05)
```

## CI 与发布

`.github/workflows/test.yml` 在 Ubuntu、macOS、Windows 上安装 stable 工具链，并执行格式、接口、严格检查、目标测试和 CLI smoke test；Unix runner 额外执行 native，全平台执行 wasm-gc。Windows native 由当前 stable 工具链的 `rand_s` 运行时兼容性限制隔离，避免 CI 把环境错误误报为项目错误。`.github/workflows/publish.yml` 提供手动 Mooncakes 发布入口；发布版本由 `moon.mod` 管理，发布前先在本地执行完整 CI。

## 贡献与许可证

本仓库的维护者和申报人是 GitHub 用户 `didiLjf`，项目验收版本保持单一实际贡献者。仓库根目录采用 [Apache License 2.0](LICENSE)。申报书 `OSC2026_8月黑客松申报书.md` 是申报材料，结项实现不会修改该文件。
