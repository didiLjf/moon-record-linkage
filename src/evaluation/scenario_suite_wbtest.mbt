///|
test "scenario suite aggregates real benchmark samples" {
  let suite = run_scenario_suite([
    ScenarioSpec::new("smoke", entities=10, seed=7, noise_level=0.0),
    ScenarioSpec::new("noisy", entities=10, seed=8, noise_level=0.5),
  ])
  assert_eq(suite.results.length(), 2)
  assert_eq(suite.total_entities, 20)
  assert_true(suite.average_elapsed_ticks >= 0)
  assert_true(suite.render_text().contains("scenario=smoke"))
}

///|
test "scenario suite handles empty scenario lists" {
  let suite = run_scenario_suite([])
  assert_true(suite.results.is_empty())
  assert_eq(suite.total_entities, 0)
  assert_eq(suite.average_f1, 0.0)
}
