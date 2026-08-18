///|
test "result analysis counts statuses and confidence buckets" {
  let a = @core.Record::new("a")
  let b = @core.Record::new("b")
  let c = @core.Record::new("c")
  let d = @core.Record::new("d")
  let pairs = [
    @core.MatchPair::new(a, b, 0.95, @core.Match),
    @core.MatchPair::new(a, c, 0.70, @core.PossibleMatch),
    @core.MatchPair::new(a, d, 0.20, @core.NonMatch),
  ]
  let analysis = analyze_match_pairs(pairs, high_confidence_threshold=0.9)
  assert_eq(analysis.total_pairs, 3)
  assert_eq(analysis.matches, 1)
  assert_eq(analysis.possible_matches, 1)
  assert_eq(analysis.non_matches, 1)
  assert_eq(analysis.high_confidence_count, 1)
  assert_true(analysis.average_score > 0.61 && analysis.average_score < 0.63)
  assert_true(result_analysis_to_json(analysis).contains("\"matches\":1"))
}
