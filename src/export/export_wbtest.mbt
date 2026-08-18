// Export Module Tests

///|
test "json export record" {
  let r = @core.Record::new("r1")
  r.set_field("name", @core.StringVal("Alice"))
  let json = record_to_json(r)
  assert_true(json.contains("\"id\":\"r1\""))
  assert_true(json.contains("\"name\":\"Alice\""))
}

///|
test "csv export escape field" {
  assert_eq(escape_csv_field("hello"), "hello")
  assert_eq(escape_csv_field("hello,world"), "\"hello,world\"")
  assert_eq(escape_csv_field("quote\"test"), "\"quote\"\"test\"")
}

///|
test "csv export match pairs" {
  let ra = @core.Record::new("a1")
  let rb = @core.Record::new("b1")
  let pair = @core.MatchPair::new(ra, rb, 0.95, @core.Match)
  let csv = match_pairs_to_csv([pair])
  assert_true(csv.contains("a1,b1,0.95,MATCH"))
}

///|
test "evaluation reporter format" {
  let metrics = @core.EvaluationMetrics::new()
  metrics.add_observation(true, true)
  metrics.add_observation(true, false)
  metrics.add_observation(false, true)
  metrics.add_observation(false, false)
  let report = format_metrics_report(metrics)
  assert_true(report.contains("Precision:"))
  assert_true(report.contains("F1-Score:"))
}

///|
test "quality reports export profiles, candidate plans and explanations" {
  let record = @core.Record::new("r1", source="crm")
  record.set_field("name", @core.StringVal("Alice"))
  let profile = @core.profile_dataset([record])
  assert_true(dataset_profile_to_json(profile).contains("\"record_count\":1"))
  assert_true(dataset_profile_to_csv(profile).has_prefix("field,total_count"))
  let plan = @blocking.plan_candidates(
    [record],
    [record],
    [],
    options=@blocking.PlannerOptions::new(),
  )
  assert_true(candidate_plan_to_json(plan).contains("candidate_pairs"))
  let config = @core.LinkageConfig::default()
  config.add_field_comparison("name", @core.ExactMatch)
  let explanation = @model.explain_pair(config, record, record)
  assert_true(score_explanation_to_text(explanation).contains("composite"))
  assert_true(
    score_explanation_to_json(explanation).contains("field_contributions"),
  )
}
