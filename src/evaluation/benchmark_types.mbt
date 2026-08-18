///|
pub struct BenchmarkConfig {
  entity_count : Int
  seed : Int
  repeats : Int
  noise_level : Double
} derive(Debug, Eq)

///|
pub fn BenchmarkConfig::new(
  entity_count? : Int = 100,
  seed? : Int = 1,
  repeats? : Int = 1,
  noise_level? : Double = 0.1,
) -> BenchmarkConfig {
  {
    entity_count: if entity_count < 0 {
      0
    } else {
      entity_count
    },
    seed,
    repeats: if repeats < 1 {
      1
    } else {
      repeats
    },
    noise_level,
  }
}

///|
pub struct BenchmarkReport {
  entity_count : Int
  left_count : Int
  right_count : Int
  gold_link_count : Int
  candidate_pair_count : Int
  match_count : Int
  precision : Double
  recall : Double
  f1 : Double
  reduction_ratio : Double
  elapsed_ticks : Int
  repeats : Int
} derive(Debug, Eq)

///|
pub fn BenchmarkReport::throughput_per_tick(self : BenchmarkReport) -> Double {
  if self.elapsed_ticks <= 0 {
    0.0
  } else {
    self.left_count.to_double() * 1000.0 / self.elapsed_ticks.to_double()
  }
}
