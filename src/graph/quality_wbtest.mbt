///|
test "cluster conflict detector ignores missing values and finds disagreements" {
  let first = @core.Record::new("r1", source="crm")
  first.set_field("name", @core.StringVal("Alice"))
  first.set_field("city", @core.StringVal("Beijing"))
  let second = @core.Record::new("r2", source="erp")
  second.set_field("name", @core.StringVal("Alice"))
  second.set_field("city", @core.StringVal("Shanghai"))
  let third = @core.Record::new("r3", source="import")
  third.set_field("name", @core.StringVal("Alice"))
  let report = detect_conflicts([first, second, third])
  assert_eq(report.checked_records, 3)
  assert_eq(report.conflicts.length(), 1)
  assert_eq(report.conflicts[0].field_name, "city")
  assert_eq(report.conflicts[0].distinct_value_count, 2)
}

///|
test "canonical evidence reports majority support and confidence" {
  let first = @core.Record::new("r1", source="crm")
  first.set_field("city", @core.StringVal("Beijing"))
  let second = @core.Record::new("r2", source="erp")
  second.set_field("city", @core.StringVal("Beijing"))
  let third = @core.Record::new("r3", source="import")
  third.set_field("city", @core.StringVal("Shanghai"))
  let merger = CanonicalMerger::new(strategy=MajorityVote)
  let canonical = merger.select_canonical([first, second, third])
  let evidence = canonical_evidence([first, second, third], canonical)
  assert_eq(evidence.length(), 1)
  assert_eq(evidence[0].selected_value, "Beijing")
  assert_eq(evidence[0].support_count, 2)
  assert_true(evidence[0].confidence > 0.6)
}

///|
test "all merge strategies are enumerable and singleton safe" {
  assert_eq(MergeStrategy::supported().length(), 4)
  let record = @core.Record::new("r1", timestamp=10L)
  record.set_field("name", @core.StringVal("Alice"))
  for strategy in MergeStrategy::supported() {
    let merger = CanonicalMerger::new(strategy~)
    assert_eq(merger.select_canonical([record]).id, "r1")
  }
}
