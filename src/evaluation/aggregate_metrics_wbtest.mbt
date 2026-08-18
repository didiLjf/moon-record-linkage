///|
test "benchmark aggregation reports macro and extrema metrics" {
  let first = run_benchmark(
    BenchmarkConfig::new(entity_count=4, seed=1, repeats=1),
  )
  let second = run_benchmark(
    BenchmarkConfig::new(entity_count=6, seed=2, repeats=1, noise_level=0.5),
  )
  let aggregate = aggregate_benchmarks([first, second])
  assert_eq(aggregate.run_count, 2)
  assert_eq(aggregate.total_entities, 10)
  assert_true(aggregate.min_f1 <= aggregate.macro_f1)
  assert_true(aggregate.max_f1 >= aggregate.macro_f1)
  assert_true(aggregate.render_csv().has_prefix("run_count"))
}

///|
test "benchmark aggregation is empty-safe" {
  let aggregate = aggregate_benchmarks([])
  assert_eq(aggregate.run_count, 0)
  assert_eq(aggregate.macro_f1, 0.0)
  assert_true(aggregate.render_json().contains("\"run_count\":0"))
}
