///|
pub struct BenchmarkAggregate {
  run_count : Int
  total_entities : Int
  total_candidates : Int
  macro_f1 : Double
  min_f1 : Double
  max_f1 : Double
  average_reduction_ratio : Double
  total_elapsed_ticks : Int
} derive(Debug, Eq)

///|
/// Aggregate independent runs without weighting one run by its candidate count.
pub fn aggregate_benchmarks(
  reports : Array[BenchmarkReport],
) -> BenchmarkAggregate {
  if reports.is_empty() {
    return {
      run_count: 0,
      total_entities: 0,
      total_candidates: 0,
      macro_f1: 0.0,
      min_f1: 0.0,
      max_f1: 0.0,
      average_reduction_ratio: 0.0,
      total_elapsed_ticks: 0,
    }
  }
  let mut total_entities = 0
  let mut total_candidates = 0
  let mut total_f1 = 0.0
  let mut total_reduction = 0.0
  let mut total_elapsed = 0
  let mut min_f1 = reports[0].f1
  let mut max_f1 = reports[0].f1
  for report in reports {
    total_entities = total_entities + report.entity_count
    total_candidates = total_candidates + report.candidate_pair_count
    total_f1 = total_f1 + report.f1
    total_reduction = total_reduction + report.reduction_ratio
    total_elapsed = total_elapsed + report.elapsed_ticks
    if report.f1 < min_f1 {
      min_f1 = report.f1
    }
    if report.f1 > max_f1 {
      max_f1 = report.f1
    }
  }
  let count = reports.length()
  {
    run_count: count,
    total_entities,
    total_candidates,
    macro_f1: total_f1 / count.to_double(),
    min_f1,
    max_f1,
    average_reduction_ratio: total_reduction / count.to_double(),
    total_elapsed_ticks: total_elapsed,
  }
}

///|
pub fn BenchmarkAggregate::render_csv(self : BenchmarkAggregate) -> String {
  "run_count,total_entities,total_candidates,macro_f1,min_f1,max_f1,average_reduction_ratio,total_elapsed_ticks\n" +
  self.run_count.to_string() +
  "," +
  self.total_entities.to_string() +
  "," +
  self.total_candidates.to_string() +
  "," +
  self.macro_f1.to_string() +
  "," +
  self.min_f1.to_string() +
  "," +
  self.max_f1.to_string() +
  "," +
  self.average_reduction_ratio.to_string() +
  "," +
  self.total_elapsed_ticks.to_string() +
  "\n"
}

///|
pub fn BenchmarkAggregate::render_json(self : BenchmarkAggregate) -> String {
  "{\"run_count\":" +
  self.run_count.to_string() +
  ",\"total_entities\":" +
  self.total_entities.to_string() +
  ",\"total_candidates\":" +
  self.total_candidates.to_string() +
  ",\"macro_f1\":" +
  self.macro_f1.to_string() +
  ",\"min_f1\":" +
  self.min_f1.to_string() +
  ",\"max_f1\":" +
  self.max_f1.to_string() +
  ",\"average_reduction_ratio\":" +
  self.average_reduction_ratio.to_string() +
  ",\"total_elapsed_ticks\":" +
  self.total_elapsed_ticks.to_string() +
  "}"
}
