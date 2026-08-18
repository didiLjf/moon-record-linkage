///|
test "adaptive blocker recommends the most selective key" {
  let records : Array[@core.Record] = []
  for i = 0; i < 6; i = i + 1 {
    let record = @core.Record::new("r" + i.to_string())
    record.set_field("country", @core.StringVal("CN"))
    record.set_field("account", @core.StringVal(i.to_string() + "-account"))
    records.push(record)
  }
  let plan = recommend_blocking(records, ["country", "account"], mode=Balanced)
  assert_eq(plan.selected_field, "account")
  assert_true(plan.expected_candidate_count < 6)
  assert_true(plan.reason.contains("account"))
}

///|
test "adaptive blocker handles empty fields and mode policies" {
  let record = @core.Record::new("r1")
  let balanced = recommend_blocking([record], [], mode=Balanced)
  assert_eq(balanced.selected_field, "id")
  let conservative = recommend_blocking([record], ["id"], mode=Conservative)
  assert_eq(conservative.strategies.length(), 1)
  let aggressive = recommend_blocking([record], ["id"], mode=Aggressive)
  assert_true(aggressive.strategies.length() >= 1)
}
