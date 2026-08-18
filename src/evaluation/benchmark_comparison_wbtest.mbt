///|
test "benchmark comparison computes metric deltas" {
  let baseline = run_benchmark(
    BenchmarkConfig::new(entity_count=10, seed=2, repeats=1, noise_level=0.0),
  )
  let noisy = run_benchmark(
    BenchmarkConfig::new(entity_count=10, seed=2, repeats=1, noise_level=0.5),
  )
  let comparison = compare_benchmarks("baseline", baseline, "noisy", noisy)
  assert_eq(comparison.left_name, "baseline")
  assert_eq(comparison.right_name, "noisy")
  assert_true(comparison.f1_delta <= 1.0)
  assert_true(comparison.render_text().contains("baseline"))
}
