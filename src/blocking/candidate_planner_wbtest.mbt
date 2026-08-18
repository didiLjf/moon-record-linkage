///|
fn candidate_record(id : String, name : String, city : String) -> @core.Record {
  let record = @core.Record::new(id)
  record.set_field("name", @core.StringVal(name))
  record.set_field("city", @core.StringVal(city))
  record
}

///|
test "candidate planner unions and deduplicates strategy outputs" {
  let a = [candidate_record("a1", "Alice", "Beijing")]
  let b = [candidate_record("b1", "Alice", "Beijing")]
  let plan = plan_candidates(
    a,
    b,
    [@core.StandardBlocking(["name"]), @core.StandardBlocking(["city"])],
    options=PlannerOptions::new(mode=Union),
  )
  assert_eq(plan.raw_pair_count, 2)
  assert_eq(plan.deduplicated_pair_count, 1)
  assert_eq(plan.pairs.length(), 1)
  assert_eq(plan.pairs[0].left_id, "a1")
  assert_eq(plan.pairs[0].origins.length(), 2)
}

///|
test "candidate planner intersection keeps only shared pairs" {
  let a = [
    candidate_record("a1", "Alice", "Beijing"),
    candidate_record("a2", "Alice", "Shanghai"),
  ]
  let b = [
    candidate_record("b1", "Alice", "Beijing"),
    candidate_record("b2", "Alice", "Shanghai"),
  ]
  let plan = plan_candidates(
    a,
    b,
    [@core.StandardBlocking(["name"]), @core.StandardBlocking(["city"])],
    options=PlannerOptions::new(mode=Intersection),
  )
  assert_eq(plan.pairs.length(), 2)
  assert_eq(plan.deduplicated_pair_count, 2)
}

///|
test "candidate planner handles empty strategies and budget deterministically" {
  let a = [candidate_record("a1", "Alice", "Beijing")]
  let b = [
    candidate_record("b1", "Alice", "Beijing"),
    candidate_record("b2", "Bob", "Shanghai"),
  ]
  let plan = plan_candidates(
    a,
    b,
    [],
    options=PlannerOptions::new(mode=Union, max_pairs=1),
  )
  assert_eq(plan.raw_pair_count, 2)
  assert_eq(plan.pairs.length(), 1)
  assert_true(plan.truncated)
  assert_eq(plan.reduction_ratio(1, 2), 0.5)
}

///|
test "candidate planner reports strategy and block statistics" {
  let records = [
    candidate_record("a1", "Alice", "Beijing"),
    candidate_record("a2", "Alice", "Beijing"),
    candidate_record("a3", "Bob", "Shanghai"),
  ]
  let stats = block_statistics(records, ["name"])
  assert_eq(stats.record_count, 3)
  assert_eq(stats.block_count, 2)
  assert_eq(stats.largest_block_size, 2)
  assert_true(stats.average_block_size > 1.0)
}
