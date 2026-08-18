# 结项审计发现

## 本地仓库

- 当前分支：`main`；工作树基线干净。
- 远程：`origin` 指向 `https://github.com/didiLjf/moon-record-linkage.git`；`gitlink` 指向 `https://www.gitlink.org.cn/DidiLs/moon-record-linkage.git`。
- 提交历史已有从初始化到算法、流水线、导出、CI 和 Mooncakes 命名调整的多次有意义提交。
- 根目录有 Apache-2.0 `LICENSE`、README、MoonBit 模块配置和 `.github/workflows/test.yml`。
- 申报书声称 6,205 行，但当前对 `.mbt` 文件的逐文件统计需要重新计算，结项统计必须区分实现代码与测试代码。

## 当前质量问题

- `moon test` 基线通过 97 个测试，但存在弃用 API、未使用包和未使用构造器警告。
- 现有 CI 只有单平台、未覆盖 `--target all`、严格警告、native、覆盖率和 info 生成差异检查。
- `moon.mod` 的 `repository` 为空，描述和关键词为空，README 中版本徽章与当前工具链不一致。
- GitHub CLI 在当前沙箱中读取 `%APPDATA%\\GitHub CLI\\config.yml` 被拒绝，推送前必须用可验证方式重新核对账号。

## 外部资料

- `Milky2018/osc2026-guide` 的 `SKILL.md` 要求八月黑客松验收重点检查 MoonBit 项目有效性、CI、Mooncakes 发布、README、运行示例、许可证、提交历史、默认分支、唯一贡献者和有效源码规模。
- MoonBit 社区 `check.yml` 模板提供三平台矩阵、`moon update`、`moon check --target all`、`moon test --target all`、格式化和 `moon info` 差异检查。
- MoonBit 社区 `publish.yml` 模板要求手动触发、先检查测试，再通过 secret 临时写入 Mooncakes 凭据后 `moon publish`。
- 当前官方搜索结果显示 MoonBit 0.10.4 已发布；自查指南要求环境低于 0.10.7 时建议升级，因此最终以安装脚本实际输出为准，不手填版本号。
