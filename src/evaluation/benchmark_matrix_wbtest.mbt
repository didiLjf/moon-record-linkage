///|
test "benchmark matrix runs each requested size" {
  let matrix = run_benchmark_matrix([
    BenchmarkConfig::new(entity_count=0, seed=3),
    BenchmarkConfig::new(entity_count=4, seed=3),
  ])
  assert_eq(matrix.reports.length(), 2)
  assert_eq(matrix.total_entities, 4)
  assert_true(matrix.render_csv().contains("entity_count"))
  assert_true(matrix.render_json().contains("\"reports\""))
}
