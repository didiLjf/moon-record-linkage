# Moon-Record-Linkage 结项增强设计

## 目标

将现有 MoonBit 实体匹配引擎从算法集合提升为可复现、可解释、可评估的生产级批量实体解析库，满足八月黑客松验收对实际应用价值、CI、测试、基准和 Mooncakes 发布的要求。申报书 `OSC2026_8月黑客松申报书.md` 只作为需求依据，不修改其内容。

验收目标：

- `src/` 中的有效 MoonBit 实现代码达到 8,000 行以上；测试代码单独统计，不以测试堆行数替代实现规模。
- 覆盖跨源匹配、单源去重、阻断、评分、聚类、规范化、质量诊断、阈值评估和基准报告等可运行能力。
- 提供确定性基准数据，报告候选缩减率、准确率、召回率、F1、吞吐和延迟，不伪造运行结果。
- 通过 `moon check --deny-warn`、`moon test --deny-warn`、`moon fmt --check`、`moon info` 和至少 `wasm-gc` / `native` 目标测试。
- GitHub 默认分支、唯一贡献者、许可证、README、提交历史和 Mooncakes 模块命名保持一致。

## 方案选择

### 方案 A：只补充算法文件

增加更多相似度算法和阻断变体，能快速提高规模，但会重复已有能力，难以证明端到端应用价值。放弃。

### 方案 B：围绕已有 Pipeline 增加生产能力（采用）

保留现有九层架构，在 `core`、`blocking`、`model`、`graph`、`pipeline`、`export` 之上增加配置校验、多策略候选合并、增量处理、质量分析、阈值调优、可解释审计和确定性基准包。新能力通过现有公开类型连接，避免破坏已有 API。

### 方案 C：引入外部数据/数据库适配器

会带来真实 I/O、依赖和跨目标复杂度，当前项目没有稳定的外部数据协议，不适合作为结项核心。保留纯 MoonBit、零外部运行时依赖。

## 模块设计

### 1. Core contract and quality model

扩展 `src/core`：

- 字段级缺失、类型、范围和格式校验；
- 数据集摘要、字段分布、缺失率和重复率；
- 匹配决策、候选统计、审计轨迹和错误分级；
- 稳定的配置验证结果，拒绝空字段、负权重、非法阈值和不一致的字段类型。

所有校验均返回 `Result` 或结构化诊断，不用异常或静默默认值隐藏输入错误。

### 2. Multi-strategy blocking and candidate planning

扩展 `src/blocking`：

- 多个阻断策略的 union / intersection / fallback 融合；
- 候选对规范化、去重、排序和来源统计；
- 分块大小分布、候选缩减率和过度阻断风险指标；
- 可配置的空值策略与最大候选上限。

`BatchPipeline` 使用候选计划而不是只取第一个阻断器，保持候选集可解释。

### 3. Explainable scoring and calibration

扩展 `src/model`：

- 字段分数、权重贡献、缺失字段影响和最终阈值的解释对象；
- exact / fuzzy / numeric / date / geographic / phonetic 等比较器统一适配；
- 基于标注对的阈值扫描、混淆矩阵和最佳 F1 阈值选择；
- 分数校准报告，明确区分匹配、可能匹配和非匹配。

评分函数保持确定性；阈值调优只消费输入标注，不修改原始记录。

### 4. Incremental and operational pipeline

扩展 `src/pipeline`：

- 批次、窗口和分页执行模型；
- 增量 upsert、已处理 ID 集、重复批次检测和冲突报告；
- 运行摘要（处理数、候选数、匹配数、跳过数、错误数、耗时）；
- 失败记录隔离和可重试的无副作用处理接口。

实现使用内存接口和显式状态，不引入文件或网络依赖，因此在 wasm、native 和测试环境中一致。

### 5. Entity quality and canonicalization

扩展 `src/graph` 与 `src/core`：

- 组件级一致性检查，发现同一实体内互相冲突的字段；
- majority / highest-confidence / most-recent 三种规范记录策略的真实执行；
- 字段级来源、投票数、置信度和冲突数；
- 聚类规模、孤立点和异常组件统计。

### 6. Evaluation and benchmark package

新增 `src/evaluation`：

- 确定性合成客户数据生成器，控制实体数、重复率、噪声级别和随机种子；
- gold pair 生成、预测结果评估和候选缩减评估；
- benchmark runner，记录总耗时、每千条耗时、候选数、吞吐和峰值结构计数；
- 文本、CSV 和 JSON 报告输出；
- 小规模 smoke benchmark 与中等规模验收 benchmark，避免提交不可复现的手填数字。

基准报告只在 CLI 运行时产生，README 记录实际运行命令和一次实测输出；不把运行生成物提交为源码。

### 7. Documentation and CLI

更新 `README.md` 与 `README.mbt.md`：

- 明确八月黑客松定位，不再把项目描述为 OSC 开源大赛提交；
- 给出从安装、检查、测试、运行演示到基准的完整命令；
- 给出实际 API、规模统计方法、测试数量和目标支持说明；
- 说明唯一维护者、Apache-2.0、无第三方复制代码和数据来源；
- CLI 增加 benchmark / quality / calibration 示例入口，确保示例可运行。

不修改申报书中的任何文字。

### 8. CI and release

调整 `.github/workflows/test.yml`：

- Ubuntu、macOS、Windows 矩阵；
- 使用官方安装脚本安装最新 stable，并打印 `moon version --all`；
- `moon update`、`moon fmt --check`、`moon info` 后检查工作树无生成差异；
- `moon check --deny-warn --target all`、`moon test --deny-warn --target all`；
- native 目标测试、覆盖率摘要和 CLI smoke run；
- 最小权限和 checkout 凭据隔离。

新增手动触发的 Mooncakes 发布工作流：先执行检查和测试，再使用仓库 secret 写入临时凭据并运行 `moon publish`，不把凭据写入仓库。

## 错误处理和兼容性

- 保持已有构造器和公开函数签名兼容；新能力优先增加新类型和新函数。
- 对空数据、重复 ID、缺少字段、非法阈值、负权重、非有限分数、窗口为零和超大候选集提供确定性结果。
- 所有公开统计定义写入文档和测试；候选缩减率在分母为零时返回明确的零样本状态。
- 不依赖网络、系统时间或不可控随机源；基准随机数由显式 seed 驱动。

## 测试策略

采用测试先行：每组新 API 先写失败的白盒测试，再实现最小行为，再重构。

- 单元测试：每个新模块覆盖正常、空、边界、错误和重复输入；
- 性质式边界：相似度范围、对称性、阈值单调性、候选无重复、聚类闭包；
- 集成测试：跨源匹配、去重、增量批次、质量报告、导出和 CLI；
- 基准断言：固定 seed 下记录数、gold pair 数和指标可复现；
- 目标测试：`wasm-gc` 与 `native` 至少各执行一次完整测试。

## 验收证据

最终交付前重新执行并保存命令输出：

```text
moon version --all
moon fmt --check
moon info
moon check --deny-warn --target all
moon test --deny-warn --target all
moon test --target native
moon run src/main
moon run cmd/main -- benchmark --records 1000 --seed 20260818
```

同时核对：有效 MoonBit 实现行数、测试数量、工作树、默认分支、GitHub 当前账号、GitHub/GitLink 远程和 Mooncakes 查询结果。只有命令实际返回成功后，才在 README 和交付报告中写入结果。
