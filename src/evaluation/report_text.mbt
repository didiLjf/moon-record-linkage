///|
pub fn BenchmarkReport::render_text(self : BenchmarkReport) -> String {
  let sb = StringBuilder(size_hint=320)
  sb.write_string("benchmark=record-linkage\n")
  sb.write_string("entities=" + self.entity_count.to_string() + "\n")
  sb.write_string("left_records=" + self.left_count.to_string() + "\n")
  sb.write_string("right_records=" + self.right_count.to_string() + "\n")
  sb.write_string("gold_links=" + self.gold_link_count.to_string() + "\n")
  sb.write_string(
    "candidate_pairs=" + self.candidate_pair_count.to_string() + "\n",
  )
  sb.write_string("matches=" + self.match_count.to_string() + "\n")
  sb.write_string("precision=" + self.precision.to_string() + "\n")
  sb.write_string("recall=" + self.recall.to_string() + "\n")
  sb.write_string("f1=" + self.f1.to_string() + "\n")
  sb.write_string(
    "candidate_reduction=" + self.reduction_ratio.to_string() + "\n",
  )
  sb.write_string("elapsed_ticks=" + self.elapsed_ticks.to_string() + "\n")
  sb.write_string("repeats=" + self.repeats.to_string() + "\n")
  sb.write_string(
    "records_per_1000_ticks=" + self.throughput_per_tick().to_string(),
  )
  sb.to_string()
}
