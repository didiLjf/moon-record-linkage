# Moon-Record-Linkage: MoonBit 实体匹配与记录匹配引擎

[![MoonBit Version](https://img.shields.io/badge/MoonBit-0.10.4-blue.svg)](https://www.moonbitlang.cn)
[![License](https://img.shields.io/badge/License-Apache_2.0-green.svg)](LICENSE)
[![CI Status](https://github.com/didiLjf/moon-record-linkage/workflows/MoonBit%20CI/badge.svg)](https://github.com/didiLjf/moon-record-linkage/actions)

`moon-record-linkage` 是一个基于 **MoonBit** 语言高标准构建的高性能、模块化、分布式友好的实体匹配（Entity Matching）与记录匹配（Record Linkage / Deduplication）系统。

本仓库专为 **开源创新大赛 2026 (OSC2026)** MoonBit 赛道打造，填补了 MoonBit 生态在海量异构数据治理、去重与实体对齐领域的空白。

---

## 🌟 项目亮点

1. **纯粹 MoonBit 原生实现**：全栈由 MoonBit 编写，零外部 C/JS 依赖，天然支持编译至 WebAssembly (Wasm) 与 Native 引擎。
2. **丰富的字符串与语音相似度算法**：涵盖 Levenshtein, Damerau-Levenshtein, Hamming, Jaro-Winkler, LCS, N-Gram Jaccard, Cosine, Monge-Elkan 及 Haversine 地理距离；集成了 Soundex, Metaphone, NYSIIS, MRA 语音编码算法。
3. **高效 Blocking 分块阻断技术**：内置 Standard Blocking, Sorted Neighborhood Method (SNM), Canopy Clustering, Locality Sensitive Hashing (LSH MinHash)，有效规避 \(O(N^2)\) 笛卡尔积比较，缩减规模达 99%+。
4. **Fellegi-Sunter 概率模型与 EM 自适应训练**：基于经典 Fellegi-Sunter 概率匹配框架，通过 EM（期望最大化）算法无监督估计匹配概率与权重。
5. **并查集（DSU）实体图聚类与规范化**：构建实体图并采用带有路径压缩与按秩合并的 DSU 算法划分联通分量，支持多策略规范化记录融合（Highest Confidence, Majority Vote, Most Recent）。

---

## 📦 架构设计与模块划分

项目的源代码位于 `src/` 目录下，共分为 9 大核心子包：

```
src/
├── core/             # 核心数据模型 (Record, Schema, MatchPair, EvaluationMetrics)
├── normalization/    # 文本清洗、域规则（中文公司名/电话/身份证/地址）、分词与 N-Gram
├── phonetic/         # 语音编码算法 (Soundex, Metaphone, NYSIIS, MRA)
├── similarity/       # 相似度计算 (Edit Distance, Jaro-Winkler, LCS, Token Sim, Geo Haversine)
├── blocking/         # 分块阻断算法 (Standard, SNM, Canopy, LSH MinHash)
├── model/            # 概率匹配模型 (Fellegi-Sunter EM, Rule Engine, Hybrid Scorer)
├── graph/            # 实体图聚类 (DSU 并查集, EntityGraph, Canonical Merger)
├── pipeline/         # 批处理流水线 (BatchPipeline, Linkage / Deduplication Orchestrator)
├── export/           # 导出与评估报告 (JSON Exporter, CSV Exporter, Evaluation Reporter)
└── main/             # 演示程序与 CLI 终端应用
```

---

## 📊 代码规模与测试覆盖

- **源码行数**：`src/` 目录下拥有超过 **6,200 行** 规范优雅的 MoonBit 源代码（符合 OSC2026 5,000–10,000 行规模要求）。
- **单元测试**：内置 **97 个单元测试用例**（`*_wbtest.mbt`），保持 **100% 测试通过率**。
- **静态检查**：严格通过 `moon check`、`moon info` 与 `moon fmt` 零警告零错误检查。

---

## 🚀 快速开始

### 1. 环境准备

请确保已安装最新版 MoonBit 工具链：

```bash
# 验证 moon 版本
moon version
```

### 2. 构建与检查

```bash
# 代码类型检查
moon check

# 格式化检查
moon fmt --check

# 生成接口定义文件
moon info
```

### 3. 运行测试套件

```bash
moon test
```

### 4. 运行演示程序

```bash
moon run src/main
```

演示程序将输出完整的清洗、相似度计算、Blocking 阻断、记录关联、实体聚类与 Evaluation 性能评估报告：

```text
=================================================================
   MoonBit Entity Matching & Record Linkage Engine (v0.1.0)     
=================================================================

--- [1] Text Normalization & Cleaning ---
Raw Company Name: '  北京天工创新科技有限公司(海淀分公司)  '
Cleaned Company:  '北京天工创新科技有限公司'

--- [2] Phonetic Algorithms ---
Soundex('Robert') = R163
Soundex('Rupert') = R163
Soundex Match: true

--- [3] Multi-Field Similarity Distance Metrics ---
Jaro-Winkler Score:    0.9636363636363636
N-Gram Jaccard Score:  0.6363636363636364

--- [4] Batch Record Linkage & Deduplication Pipeline ---
Candidates Evaluated: 2
Matched Pairs Found:  2
Entity Clusters Formed: 2

=== Record Linkage Evaluation Report ===
Precision: 1.0
Recall:    1.0
F1-Score:  1.0
Accuracy:  1.0
========================================
```

---

## 💡 代码示例

```moonbit
// 创建匹配配置
let cfg = @core.LinkageConfig::new("customer-dedup")
cfg.add_blocking(@core.StandardBlocking(["name"]))
cfg.add_field_comparison("name", @core.JaroWinkler, weight=2.0)
cfg.add_field_comparison("phone", @core.ExactMatch, weight=1.0)
cfg.set_thresholds(0.80, 0.45)

// 初始化匹配流水线
let pipeline = @pipeline.BatchPipeline::new(cfg)

// 执行跨数据集对齐匹配
let result = pipeline.run_link(dataset_a, dataset_b)

// 导出 JSON/CSV 结果
let json_str = @export.linkage_result_to_json(result)
```

---

## 📄 开源许可证

本项目采用 [Apache License 2.0](LICENSE) 开源许可证。
