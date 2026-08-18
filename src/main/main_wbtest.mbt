// End-to-End Main Demo Test

///|
test "run full entity matching demo" {
  run_demo()
}

///|
test "benchmark and quality demos return evidence text" {
  let benchmark = run_benchmark_demo(12, 17)
  assert_true(benchmark.has_prefix("benchmark=record-linkage"))
  let quality = run_quality_demo()
  assert_true(quality.contains("records="))
}

///|
test "cli argument parser honors records and seed" {
  let args = ["program", "benchmark", "--records", "25", "--seed", "9"]
  let options = parse_cli_options(args)
  assert_eq(options.mode, "benchmark")
  assert_eq(options.records, 25)
  assert_eq(options.seed, 9)
}
