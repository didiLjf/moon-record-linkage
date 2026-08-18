///|
test "batch windows are bounded and deterministic" {
  let records : Array[@core.Record] = []
  for i = 0; i < 5; i = i + 1 {
    records.push(@core.Record::new("r" + i.to_string()))
  }
  let first = slice_page(records, PageRequest::new(offset=0, limit=2))
  let second = slice_page(records, PageRequest::new(offset=2, limit=2))
  let tail = slice_page(records, PageRequest::new(offset=4, limit=3))
  assert_eq(first.items.length(), 2)
  assert_eq(second.items[0].id, "r2")
  assert_eq(tail.items.length(), 1)
  assert_true(tail.has_more == false)
}

///|
test "incremental state upsert and batch replay are idempotent" {
  let state = IncrementalState::new()
  let first = @core.Record::new("r1", source="crm")
  first.set_field("name", @core.StringVal("Alice"))
  let replacement = @core.Record::new("r1", source="erp")
  replacement.set_field("name", @core.StringVal("Alicia"))
  assert_true(state.upsert(first))
  assert_true(!state.upsert(replacement))
  assert_eq(state.record_count(), 1)
  assert_eq(state.get("r1").unwrap().source, "erp")
  assert_true(state.accept_batch("batch-1"))
  assert_true(!state.accept_batch("batch-1"))
  assert_eq(state.batch_count(), 1)
}

///|
test "retry policy bounds attempts and classifies failures" {
  let policy = RetryPolicy::new(max_attempts=3)
  assert_eq(policy.allowed_attempts(), 3)
  assert_true(policy.should_retry(attempt=1, retryable=true))
  assert_true(policy.should_retry(attempt=2, retryable=true))
  assert_true(!policy.should_retry(attempt=3, retryable=true))
  assert_true(!policy.should_retry(attempt=1, retryable=false))
}

///|
test "run summary merges counts without time assumptions" {
  let summary = RunSummary::new("batch-1")
  summary.add_page(processed=10, candidates=30, matches=4, failures=1)
  summary.add_page(processed=5, candidates=8, matches=2, failures=0)
  summary.set_elapsed_millis(125)
  assert_eq(summary.processed_records, 15)
  assert_eq(summary.candidate_pairs, 38)
  assert_eq(summary.matches, 6)
  assert_eq(summary.failures, 1)
  assert_eq(summary.throughput_per_second(), 120.0)
}
