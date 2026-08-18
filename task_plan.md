# 结项增强执行计划

## 目标

把 `didiLjf/moon-record-linkage` 完成到八月黑客松验收级别：有效 MoonBit 实现代码 8,000+ 行，具备生产级实体匹配能力、真实可复现基准、边界测试、严格 CI，并核验 GitHub 唯一贡献者和 Mooncakes 发布。

## 阶段

- [x] 审计仓库、申报书、远程、CI、工具链与参考资料
- [x] 形成并提交设计规格，等待用户确认
- [x] 生成并审阅实现计划
- [x] 先补测试，再实现 core/blocking/model/graph/pipeline/evaluation 能力
- [x] 扩展 CLI、README、基准命令和发布说明
- [x] 升级/固定最新 stable CI，补全多目标与覆盖率流程
- [x] 运行完整验证、统计有效源码规模和边界测试
- [x] 核验账号、默认分支、唯一贡献者与远程后提交、推送 GitHub；GitLink 因服务端写权限拒绝待用户补授权
- [x] 通过 GitHub 推送 0.1.1 并发布 Mooncakes，服务器返回 200 OK
- [x] 使用 osc2026-guide 清单完成最终验收自查

## 不可违背的约束

- 不修改 `OSC2026_8月黑客松申报书.md`。
- 不用无意义重复代码满足行数；新增行数必须对应可运行能力或测试支撑。
- 每个新增生产功能遵循先写失败测试、确认失败、再实现、确认通过。
- 推送前再次核查 GitHub 登录账号、远程 URL、默认分支和贡献者身份。

## 错误记录

| 错误 | 状态 |
| --- | --- |
| Firecrawl CLI 不在 PATH | 已记录，网页资料改用内置网页访问读取 |
| `gh auth status` 读取用户配置被 Windows 权限拒绝 | 待用明确授权的 GitHub API/CLI 方式复核 |
| 基线测试存在旧弃用/未使用警告 | 已清理，wasm/wasm-gc `--deny-warn` 通过 |
| Windows stable native runtime 报 `rand_s` 隐式声明 | 已在 CI 中将 Windows native 隔离为 wasm-gc；Unix 保留 native/all 验证 |
