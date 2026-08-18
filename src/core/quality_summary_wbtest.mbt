///|
test "quality summary reports empty and duplicate-heavy datasets" {
  let first = Record::new("same", source="crm")
  first.set_field("name", StringVal("Alice"))
  let second = Record::new("same", source="billing")
  second.set_field("name", StringVal(""))
  let third = Record::new("other", source="billing")
  let summary = quality_summary([first, second, third])
  assert_eq(summary.record_count, 3)
  assert_eq(summary.distinct_id_count, 2)
  assert_eq(summary.duplicate_id_count, 1)
  assert_eq(summary.source_count, 2)
  assert_true(summary.missing_field_rate > 0.0)
  assert_true(summary.to_text().contains("records=3"))
  assert_true(summary.to_json().contains("\"duplicate_id_count\":1"))
  assert_true(summary.to_markdown().contains("| sources | 2 |"))
  assert_true(summary.source_distribution_csv().contains("billing,2"))
  assert_eq(summary.risk_level(), "high")
  assert_true(
    summary.is_acceptable(max_missing_rate=0.5, max_duplicate_rate=0.5),
  )
  let gate = summary.evaluate_gate(
    max_missing_rate=0.5,
    max_duplicate_rate=0.05,
  )
  assert_true(!gate.accepted)
  assert_eq(gate.failures.length(), 1)
  assert_true(summary.to_csv().contains("metric,value"))
  assert_true(
    summary.source_distribution_markdown().contains("| billing | 2 |"),
  )
  assert_eq(gate.failure_count(), 1)
  assert_true(gate.to_json().contains("\"accepted\":false"))
  assert_true(summary.quality_score() < 1.0)
  assert_true(gate.to_text().contains("accepted=false"))
}

///|
test "quality summary handles no records" {
  let summary = quality_summary([])
  assert_eq(summary.record_count, 0)
  assert_eq(summary.distinct_id_count, 0)
  assert_eq(summary.duplicate_id_count, 0)
  assert_eq(summary.source_count, 0)
  assert_eq(summary.missing_field_rate, 0.0)
  assert_true(!summary.has_data())
  assert_eq(summary.record_density(), 0.0)
}
