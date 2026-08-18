///|
pub struct ScenarioSpec {
  name : String
  entities : Int
  seed : Int
  noise_level : Double
} derive(Debug, Eq)

///|
pub fn ScenarioSpec::new(
  name : String,
  entities? : Int = 100,
  seed? : Int = 1,
  noise_level? : Double = 0.1,
) -> ScenarioSpec {
  { name, entities: if entities < 0 { 0 } else { entities }, seed, noise_level }
}

///|
pub struct ScenarioResult {
  name : String
  report : BenchmarkReport
} derive(Debug)

///|
pub struct ScenarioSuiteReport {
  results : Array[ScenarioResult]
  total_entities : Int
  average_f1 : Double
  average_reduction_ratio : Double
  average_elapsed_ticks : Int
} derive(Debug)

///|
pub fn run_scenario_suite(
  scenarios : Array[ScenarioSpec],
) -> ScenarioSuiteReport {
  let results : Array[ScenarioResult] = []
  let mut total_entities = 0
  let mut total_f1 = 0.0
  let mut total_reduction = 0.0
  let mut total_elapsed = 0
  for scenario in scenarios {
    let report = run_benchmark(
      BenchmarkConfig::new(
        entity_count=scenario.entities,
        seed=scenario.seed,
        noise_level=scenario.noise_level,
        repeats=1,
      ),
    )
    results.push({ name: scenario.name, report })
    total_entities = total_entities + scenario.entities
    total_f1 = total_f1 + report.f1
    total_reduction = total_reduction + report.reduction_ratio
    total_elapsed = total_elapsed + report.elapsed_ticks
  }
  let count = scenarios.length()
  {
    results,
    total_entities,
    average_f1: if count == 0 {
      0.0
    } else {
      total_f1 / count.to_double()
    },
    average_reduction_ratio: if count == 0 {
      0.0
    } else {
      total_reduction / count.to_double()
    },
    average_elapsed_ticks: if count == 0 {
      0
    } else {
      total_elapsed / count
    },
  }
}

///|
pub fn ScenarioSuiteReport::render_text(self : ScenarioSuiteReport) -> String {
  let sb = StringBuilder(size_hint=512)
  for item in self.results {
    sb.write_string(
      "scenario=" +
      item.name +
      " entities=" +
      item.report.entity_count.to_string() +
      " candidates=" +
      item.report.candidate_pair_count.to_string() +
      " f1=" +
      item.report.f1.to_string() +
      " elapsed_ticks=" +
      item.report.elapsed_ticks.to_string() +
      "\n",
    )
  }
  sb.write_string("total_entities=" + self.total_entities.to_string() + "\n")
  sb.write_string("average_f1=" + self.average_f1.to_string() + "\n")
  sb.write_string(
    "average_reduction=" + self.average_reduction_ratio.to_string() + "\n",
  )
  sb.write_string(
    "average_elapsed_ticks=" + self.average_elapsed_ticks.to_string(),
  )
  sb.to_string()
}
