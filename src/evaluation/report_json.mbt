///|
pub fn BenchmarkReport::render_json(self : BenchmarkReport) -> String {
  "{" +
  "\"entities\":" +
  self.entity_count.to_string() +
  "," +
  "\"left_records\":" +
  self.left_count.to_string() +
  "," +
  "\"right_records\":" +
  self.right_count.to_string() +
  "," +
  "\"gold_links\":" +
  self.gold_link_count.to_string() +
  "," +
  "\"candidate_pairs\":" +
  self.candidate_pair_count.to_string() +
  "," +
  "\"matches\":" +
  self.match_count.to_string() +
  "," +
  "\"precision\":" +
  self.precision.to_string() +
  "," +
  "\"recall\":" +
  self.recall.to_string() +
  "," +
  "\"f1\":" +
  self.f1.to_string() +
  "," +
  "\"reduction_ratio\":" +
  self.reduction_ratio.to_string() +
  "," +
  "\"elapsed_ticks\":" +
  self.elapsed_ticks.to_string() +
  "," +
  "\"repeats\":" +
  self.repeats.to_string() +
  "}"
}
