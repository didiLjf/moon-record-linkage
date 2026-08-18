///|
pub struct BenchmarkComparison {
  left_name : String
  right_name : String
  candidate_delta : Int
  f1_delta : Double
  reduction_delta : Double
  elapsed_delta : Int
  throughput_ratio : Double
} derive(Debug, Eq)

///|
pub fn compare_benchmarks(
  left_name : String,
  left : BenchmarkReport,
  right_name : String,
  right : BenchmarkReport,
) -> BenchmarkComparison {
  let throughput_ratio = if left.throughput_per_tick() == 0.0 {
    0.0
  } else {
    right.throughput_per_tick() / left.throughput_per_tick()
  }
  {
    left_name,
    right_name,
    candidate_delta: right.candidate_pair_count - left.candidate_pair_count,
    f1_delta: right.f1 - left.f1,
    reduction_delta: right.reduction_ratio - left.reduction_ratio,
    elapsed_delta: right.elapsed_ticks - left.elapsed_ticks,
    throughput_ratio,
  }
}

///|
pub fn BenchmarkComparison::render_text(self : BenchmarkComparison) -> String {
  "comparison=" +
  self.left_name +
  "->" +
  self.right_name +
  " candidate_delta=" +
  self.candidate_delta.to_string() +
  " f1_delta=" +
  self.f1_delta.to_string() +
  " reduction_delta=" +
  self.reduction_delta.to_string() +
  " elapsed_delta=" +
  self.elapsed_delta.to_string() +
  " throughput_ratio=" +
  self.throughput_ratio.to_string()
}
