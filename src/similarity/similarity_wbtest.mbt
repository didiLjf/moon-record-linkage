// Similarity Module Tests

///|
test "levenshtein identical" {
  assert_eq(levenshtein_distance("abc", "abc"), 0)
  assert_eq(levenshtein_similarity("abc", "abc"), 1.0)
}

///|
test "levenshtein insertions" {
  assert_eq(levenshtein_distance("kitten", "sitting"), 3)
}

///|
test "levenshtein empty strings" {
  assert_eq(levenshtein_distance("", "abc"), 3)
  assert_eq(levenshtein_distance("abc", ""), 3)
  assert_eq(levenshtein_similarity("", ""), 1.0)
}

///|
test "damerau includes transpositions" {
  // "ab" -> "ba" is 1 transposition
  assert_eq(damerau_levenshtein_distance("ab", "ba"), 1)
  // Levenshtein counts it as 2
  assert_eq(levenshtein_distance("ab", "ba"), 2)
}

///|
test "hamming distance" {
  assert_eq(hamming_distance("karolin", "kathrin"), 3)
  assert_eq(hamming_distance("abc", "abc"), 0)
  assert_eq(hamming_distance("abc", "ab"), -1)
}

///|
test "hamming similarity" {
  assert_eq(hamming_similarity("abc", "abc"), 1.0)
  assert_eq(hamming_similarity("abc", "ab"), 0.0)
}

///|
test "jaro similarity" {
  let sim = jaro("MARTHA", "MARHTA")
  assert_true(sim > 0.94 && sim < 0.96)
}

///|
test "jaro_winkler similarity" {
  let sim = jaro_winkler("JOHNNYDEPP", "JOHNNYDEP")
  assert_true(sim > 0.95)
}

///|
test "jaro identical" {
  assert_eq(jaro("abc", "abc"), 1.0)
}

///|
test "jaro empty" {
  assert_eq(jaro("", ""), 1.0)
  assert_eq(jaro("abc", ""), 0.0)
}

///|
test "lcs length" {
  assert_eq(lcs_length("ABCBDAB", "BDCAB"), 4)
  assert_eq(lcs_length("", "abc"), 0)
  assert_eq(lcs_length("abc", "abc"), 3)
}

///|
test "lcs similarity" {
  assert_eq(lcs_similarity("abc", "abc"), 1.0)
  assert_true(lcs_similarity("ABCBDAB", "BDCAB") > 0.5)
}

///|
test "longest common substring" {
  assert_eq(longest_common_substring_length("abcdef", "bcdfgh"), 3)
}

///|
test "jaccard similarity tokens" {
  let a = ["hello", "world"]
  let b = ["hello", "moonbit"]
  let sim = jaccard_similarity(a, b)
  assert_true(sim > 0.3 && sim < 0.4)
}

///|
test "jaccard identical sets" {
  let a = ["foo", "bar", "baz"]
  let sim = jaccard_similarity(a, a)
  assert_eq(sim, 1.0)
}

///|
test "cosine similarity" {
  let a = ["hello", "world", "hello"]
  let b = ["hello", "foo"]
  let sim = cosine_similarity(a, b)
  assert_true(sim > 0.0 && sim <= 1.0)
}

///|
test "ngram jaccard" {
  let sim = ngram_jaccard("hello", "helo", n=2)
  assert_true(sim > 0.5)
  assert_eq(ngram_jaccard("abc", "abc", n=2), 1.0)
}

///|
test "overlap similarity" {
  let a = ["foo", "bar", "baz"]
  let b = ["foo", "bar"]
  let sim = overlap_similarity(a, b)
  assert_eq(sim, 1.0)
}

///|
test "numeric absolute similarity" {
  assert_eq(numeric_absolute_similarity(10.0, 10.0), 1.0)
  assert_eq(numeric_absolute_similarity(0.0, 2.0, max_diff=1.0), 0.0)
  assert_eq(numeric_absolute_similarity(0.0, 0.5, max_diff=1.0), 0.5)
}

///|
test "numeric relative similarity" {
  assert_eq(numeric_relative_similarity(100.0, 100.0), 1.0)
  assert_eq(numeric_relative_similarity(100.0, 200.0, max_pct=1.0), 0.5)
}

///|
test "date similarity same" {
  assert_eq(date_similarity("2024-01-01", "2024-01-01"), 1.0)
}

///|
test "date similarity far apart" {
  let sim = date_similarity("2020-01-01", "2021-01-01", max_days=365)
  assert_true(sim >= 0.0 && sim <= 0.01)
}

///|
test "date parse invalid" {
  let days = parse_date_to_days("not-a-date")
  assert_eq(days, -1)
}

///|
test "haversine distance" {
  // Beijing to Shanghai (~1087 km)
  let dist = haversine_distance_km(39.9, 116.4, 31.2, 121.5)
  assert_true(dist > 1000.0 && dist < 1200.0)
}

///|
test "geo similarity close" {
  // Same point
  let sim = geo_haversine_similarity(39.9, 116.4, 39.9, 116.4, max_km=10.0)
  assert_eq(sim, 1.0)
}

///|
test "geo similarity far" {
  let sim = geo_haversine_similarity(0.0, 0.0, 90.0, 0.0, max_km=100.0)
  assert_eq(sim, 0.0)
}
