///|
test "explainable scorer exposes every field contribution" {
  let config = @core.LinkageConfig::new("explain")
  config.add_field_comparison("name", @core.JaroWinkler, weight=2.0)
  config.add_field_comparison("city", @core.ExactMatch, weight=1.0)
  config.set_thresholds(0.8, 0.4)
  let left = @core.Record::new("a")
  left.set_field("name", @core.StringVal("Alice"))
  left.set_field("city", @core.StringVal("Beijing"))
  let right = @core.Record::new("b")
  right.set_field("name", @core.StringVal("Alic"))
  right.set_field("city", @core.StringVal("Shanghai"))
  let explanation = explain_pair(config, left, right)
  assert_eq(explanation.field_contributions.length(), 2)
  assert_eq(explanation.field_contributions[0].field_name, "name")
  assert_true(explanation.composite_score >= 0.0)
  assert_true(explanation.composite_score <= 1.0)
  assert_eq(explanation.status, @core.PossibleMatch)
}

///|
test "explainable scorer records missing fields and zero-weight behavior" {
  let config = @core.LinkageConfig::new("missing")
  config.add_field_comparison(
    "name",
    @core.ExactMatch,
    weight=0.0,
    penalty=-0.2,
  )
  let left = @core.Record::new("a")
  let right = @core.Record::new("b")
  let explanation = explain_pair(config, left, right)
  assert_eq(explanation.missing_fields, ["name"])
  assert_eq(explanation.composite_score, 0.0)
  assert_eq(explanation.status, @core.NonMatch)
}
