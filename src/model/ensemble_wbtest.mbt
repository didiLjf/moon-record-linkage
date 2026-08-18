///|
test "ensemble scorer combines model opinions and exposes disagreement" {
  let exact = @core.LinkageConfig::new("exact")
  exact.add_field_comparison("name", @core.ExactMatch)
  let fuzzy = @core.LinkageConfig::new("fuzzy")
  fuzzy.add_field_comparison("name", @core.JaroWinkler)
  let ensemble = EnsembleScorer::new()
  ensemble.add_model("exact", exact, weight=1.0)
  ensemble.add_model("fuzzy", fuzzy, weight=2.0)
  let left = @core.Record::new("a")
  left.set_field("name", @core.StringVal("Alice"))
  let right = @core.Record::new("b")
  right.set_field("name", @core.StringVal("Alic"))
  let decision = ensemble.decide(left, right)
  assert_eq(decision.component_scores.length(), 2)
  assert_true(decision.score > 0.0)
  assert_true(decision.disagreement >= 0.0)
}

///|
test "ensemble scorer rejects empty model sets and zero weights safely" {
  let empty = EnsembleScorer::new()
  let left = @core.Record::new("a")
  let right = @core.Record::new("b")
  assert_eq(empty.decide(left, right).score, 0.0)
  let config = @core.LinkageConfig::default()
  config.add_field_comparison("name", @core.ExactMatch)
  empty.add_model("zero", config, weight=0.0)
  assert_eq(empty.decide(left, right).score, 0.0)
}
