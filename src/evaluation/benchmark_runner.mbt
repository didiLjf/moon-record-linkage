///|
fn benchmark_config() -> @core.LinkageConfig {
  let config = @core.LinkageConfig::new("evaluation-benchmark")
  config.add_blocking(@core.StandardBlocking(["city"]))
  config.add_field_comparison("name", @core.JaroWinkler, weight=2.0)
  config.add_field_comparison("phone", @core.JaroWinkler, weight=1.0)
  config.set_thresholds(0.75, 0.45)
  config
}

///|
/// Run a real pipeline measurement using the toolchain monotonic timer.
pub fn run_benchmark(config : BenchmarkConfig) -> BenchmarkReport {
  let dataset_config = SyntheticDatasetConfig::new(
    entity_count=config.entity_count,
    seed=config.seed,
    noise_level=config.noise_level,
  )
  let dataset = generate_dataset(dataset_config)
  let mut candidate_count = 0
  let mut match_count = 0
  let mut evaluation = PairEvaluationReport::from_zero()
  let mut elapsed_ticks = 0
  for _ in 0..<config.repeats {
    let pipeline = @pipeline.BatchPipeline::new(benchmark_config())
    let started = @env.now()
    let result = pipeline.run_link(dataset.left_records, dataset.right_records)
    let ended = @env.now()
    let elapsed = if ended >= started { (ended - started).to_int() } else { 0 }
    elapsed_ticks = elapsed_ticks + elapsed
    candidate_count = result.candidate_pair_count
    match_count = result.match_pairs.length()
    let predicted : Array[(String, String)] = []
    for pair in result.match_pairs {
      predicted.push((pair.record_a.id, pair.record_b.id))
    }
    evaluation = evaluate_pairs(predicted, dataset.gold_pairs)
  }
  let total_possible = dataset.left_records.length() *
    dataset.right_records.length()
  {
    entity_count: config.entity_count,
    left_count: dataset.left_records.length(),
    right_count: dataset.right_records.length(),
    gold_link_count: dataset.gold_pairs.length(),
    candidate_pair_count: candidate_count,
    match_count,
    precision: evaluation.precision(),
    recall: evaluation.recall(),
    f1: evaluation.f1(),
    reduction_ratio: candidate_reduction_ratio(total_possible, candidate_count),
    elapsed_ticks,
    repeats: config.repeats,
  }
}
