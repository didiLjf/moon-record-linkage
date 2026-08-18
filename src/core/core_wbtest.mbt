// Unit Tests for Core Module

///|
test "record creation and field retrieval" {
  let rec = Record::new("rec-001", source="crm_db", timestamp=1700000000L)
  rec.set_field("name", StringVal("Alice Smith"))
  rec.set_field("age", IntVal(30))
  rec.set_field("score", DoubleVal(95.5))
  rec.set_field("location", GeoVal(31.23, 121.47))
  assert_eq(rec.get_string("name"), "Alice Smith")
  assert_eq(rec.get_string("age"), "30")
  assert_eq(rec.get_double("score"), 95.5)
  let (lat, lon) = rec.get_geo("location")
  assert_eq(lat, 31.23)
  assert_eq(lon, 121.47)
}

///|
test "null field value" {
  let rec = Record::new("r0")
  let val = rec.get_field("nonexistent")
  assert_true(val.is_null())
}

///|
test "field value to_str conversions" {
  assert_eq(StringVal("hello").to_str(), "hello")
  assert_eq(IntVal(42).to_str(), "42")
  assert_eq(NullVal.to_str(), "")
  assert_eq(DateVal("2024-01-01").to_str(), "2024-01-01")
  assert_eq(GeoVal(1.0, 2.0).to_str(), "1,2")
}

///|
test "array field value to_str" {
  let arr = ["apple", "banana", "cherry"]
  let val = ArrayVal(arr)
  assert_eq(val.to_str(), "apple;banana;cherry")
  assert_true(!val.is_null())
  let empty = ArrayVal([])
  assert_true(empty.is_null())
}

///|
test "schema validation success" {
  let schema = Schema::new()
  schema.add_field("id", Text, required=true)
  schema.add_field("email", Text, required=true)
  schema.add_field("phone", Text, required=false)
  let valid_rec = Record::new("r1")
  valid_rec.set_field("id", StringVal("r1"))
  valid_rec.set_field("email", StringVal("test@example.com"))
  let res = schema.validate(valid_rec)
  assert_true(res is Ok(_))
}

///|
test "schema validation missing required field" {
  let schema = Schema::new()
  schema.add_field("id", Text, required=true)
  schema.add_field("email", Text, required=true)
  let invalid_rec = Record::new("r2")
  invalid_rec.set_field("id", StringVal("r2"))
  let res = schema.validate(invalid_rec)
  assert_true(res is Err(_))
}

///|
test "match pair construction" {
  let a = Record::new("a1", source="db_a")
  let b = Record::new("b1", source="db_b")
  let pair = MatchPair::new(a, b, 0.92, Match)
  pair.set_field_score("name", 0.95)
  pair.set_field_score("address", 0.88)
  assert_eq(pair.score, 0.92)
  assert_eq(pair.status, Match)
  assert_eq(pair.field_scores.get("name"), Some(0.95))
}

///|
test "entity cluster management" {
  let canonical = Record::new("c1")
  canonical.set_field("name", StringVal("Canonical Corp."))
  let cluster = EntityCluster::new("cluster-001", canonical, confidence=0.97)
  let r1 = Record::new("r1")
  let r2 = Record::new("r2")
  cluster.add_record(r1)
  cluster.add_record(r2)
  assert_eq(cluster.records.length(), 2)
  assert_eq(cluster.confidence, 0.97)
}

///|
test "evaluation metrics computation" {
  let metrics = EvaluationMetrics::new(total_possible_pairs=1000)
  metrics.add_observation(true, true)
  metrics.add_observation(true, true)
  metrics.add_observation(true, false)
  metrics.add_observation(false, true)
  metrics.add_observation(false, false)
  assert_eq(metrics.true_positives, 2)
  assert_eq(metrics.false_positives, 1)
  assert_eq(metrics.false_negatives, 1)
  assert_eq(metrics.true_negatives, 1)
  let p = metrics.precision()
  let r = metrics.recall()
  let f1 = metrics.f1_score()
  assert_true(p > 0.66 && p < 0.67)
  assert_true(r > 0.66 && r < 0.67)
  assert_true(f1 > 0.66 && f1 < 0.67)
}

///|
test "evaluation metrics reduction ratio" {
  let metrics = EvaluationMetrics::new(total_possible_pairs=100)
  for i = 0; i < 10; i = i + 1 {
    metrics.add_observation(true, true)
  }
  let rr = metrics.reduction_ratio()
  assert_eq(rr, 0.9)
}

///|
test "linkage config defaults" {
  let cfg = LinkageConfig::default()
  assert_eq(cfg.thresholds.match_threshold, 0.85)
  assert_eq(cfg.thresholds.non_match_threshold, 0.45)
  assert_eq(cfg.max_em_iterations, 50)
  assert_true(cfg.enable_em_training)
}

///|
test "linkage config add comparisons" {
  let cfg = LinkageConfig::default()
  cfg.add_field_comparison("name", JaroWinkler, weight=2.0)
  cfg.add_field_comparison("email", ExactMatch, weight=3.0)
  cfg.add_field_comparison("phone", PhoneticSoundex, weight=1.0)
  assert_eq(cfg.field_count(), 3)
  assert_eq(cfg.total_weight(), 6.0)
}
