///|
pub fn BenchmarkReport::render_csv(self : BenchmarkReport) -> String {
  "entities,left_records,right_records,gold_links,candidate_pairs,matches,precision,recall,f1,reduction_ratio,elapsed_ticks,repeats\n" +
  self.entity_count.to_string() +
  "," +
  self.left_count.to_string() +
  "," +
  self.right_count.to_string() +
  "," +
  self.gold_link_count.to_string() +
  "," +
  self.candidate_pair_count.to_string() +
  "," +
  self.match_count.to_string() +
  "," +
  self.precision.to_string() +
  "," +
  self.recall.to_string() +
  "," +
  self.f1.to_string() +
  "," +
  self.reduction_ratio.to_string() +
  "," +
  self.elapsed_ticks.to_string() +
  "," +
  self.repeats.to_string() +
  "\n"
}
