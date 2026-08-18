///|
test "candidate plan summary explains reduction and origins" {
  let a = @core.Record::new("a1")
  a.set_field("name", @core.StringVal("Alice"))
  let b = @core.Record::new("b1")
  b.set_field("name", @core.StringVal("Alice"))
  let plan = plan_candidates([a], [b], [], options=PlannerOptions::new())
  let summary = plan_summary(plan, left_count=1, right_count=1)
  assert_true(summary.contains("raw=1"))
  assert_true(
    candidate_plan_to_markdown(plan, left_count=1, right_count=1).contains(
      "Reduction",
    ),
  )
}
