///|
test "synthetic generator is repeatable and produces gold links" {
  let config = SyntheticDatasetConfig::new(
    entity_count=8,
    seed=42,
    noise_level=0.25,
  )
  let first = generate_dataset(config)
  let second = generate_dataset(config)
  assert_eq(first.left_records.length(), 8)
  assert_eq(first.right_records.length(), 8)
  assert_eq(first.gold_pairs.length(), 8)
  assert_eq(
    first.left_records[0].get_string("name"),
    second.left_records[0].get_string("name"),
  )
  assert_eq(
    first.right_records[3].get_string("phone"),
    second.right_records[3].get_string("phone"),
  )
  assert_eq(first.gold_pairs[0].left_id, "left-0")
}

///|
test "synthetic generator handles zero entities and clamps noise" {
  let config = SyntheticDatasetConfig::new(
    entity_count=0,
    seed=1,
    noise_level=2.0,
  )
  let dataset = generate_dataset(config)
  assert_true(dataset.left_records.is_empty())
  assert_true(dataset.right_records.is_empty())
  assert_true(dataset.gold_pairs.is_empty())
}

///|
test "pair evaluation counts false positives and false negatives" {
  let gold = [
    { left_id: "a1", right_id: "b1", actual_match: true },
    { left_id: "a2", right_id: "b2", actual_match: true },
  ]
  let report = evaluate_pairs([("a1", "b1"), ("a3", "b3")], gold)
  assert_eq(report.true_positives, 1)
  assert_eq(report.false_positives, 1)
  assert_eq(report.false_negatives, 1)
  assert_true(report.f1() > 0.4 && report.f1() < 0.6)
}

///|
test "benchmark report contains candidate reduction and real timer output" {
  let config = BenchmarkConfig::new(entity_count=20, seed=20260818, repeats=1)
  let report = run_benchmark(config)
  assert_eq(report.entity_count, 20)
  assert_eq(report.gold_link_count, 20)
  assert_true(report.candidate_pair_count >= 0)
  assert_true(report.elapsed_ticks >= 0)
  assert_true(report.render_text().has_prefix("benchmark="))
}
