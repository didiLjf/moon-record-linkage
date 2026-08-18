///|
test "acceptance bundle renders reproducible evidence" {
  let record = @core.Record::new("r1")
  record.set_field("name", @core.StringVal("Alice"))
  let profile = @core.profile_dataset([record])
  let benchmark = @evaluation.run_benchmark(
    @evaluation.BenchmarkConfig::new(entity_count=2, seed=4, repeats=1),
  )
  let bundle = AcceptanceBundle::new(profile, benchmark, 140, 0)
  assert_true(bundle.render_markdown().contains("源码规模"))
  assert_true(bundle.render_json().contains("production_lines"))
}
