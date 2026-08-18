///|
pub struct AcceptanceBundle {
  profile : @core.DatasetProfile
  benchmark : @evaluation.BenchmarkReport
  test_count : Int
  production_lines : Int
} derive(Debug)

///|
pub fn AcceptanceBundle::new(
  profile : @core.DatasetProfile,
  benchmark : @evaluation.BenchmarkReport,
  test_count : Int,
  production_lines : Int,
) -> AcceptanceBundle {
  { profile, benchmark, test_count, production_lines }
}

///|
pub fn AcceptanceBundle::render_markdown(self : AcceptanceBundle) -> String {
  "# 结项验收证据\n\n" +
  "## 源码规模\n\n" +
  "- 源码规模（非空实现行）：" +
  self.production_lines.to_string() +
  "\n" +
  "- 自动化测试数量：" +
  self.test_count.to_string() +
  "\n" +
  "- 数据集记录数：" +
  self.profile.record_count.to_string() +
  "\n\n" +
  "## 基准\n\n" +
  "- 候选对：" +
  self.benchmark.candidate_pair_count.to_string() +
  "\n" +
  "- Precision：" +
  self.benchmark.precision.to_string() +
  "\n" +
  "- Recall：" +
  self.benchmark.recall.to_string() +
  "\n" +
  "- F1：" +
  self.benchmark.f1.to_string() +
  "\n" +
  "- 候选缩减率：" +
  self.benchmark.reduction_ratio.to_string() +
  "\n" +
  "- 实测计时刻度：" +
  self.benchmark.elapsed_ticks.to_string() +
  "\n"
}

///|
pub fn AcceptanceBundle::render_json(self : AcceptanceBundle) -> String {
  "{\"production_lines\":" +
  self.production_lines.to_string() +
  ",\"test_count\":" +
  self.test_count.to_string() +
  ",\"record_count\":" +
  self.profile.record_count.to_string() +
  ",\"candidate_pairs\":" +
  self.benchmark.candidate_pair_count.to_string() +
  ",\"precision\":" +
  self.benchmark.precision.to_string() +
  ",\"recall\":" +
  self.benchmark.recall.to_string() +
  ",\"f1\":" +
  self.benchmark.f1.to_string() +
  ",\"reduction_ratio\":" +
  self.benchmark.reduction_ratio.to_string() +
  ",\"elapsed_ticks\":" +
  self.benchmark.elapsed_ticks.to_string() +
  "}"
}
