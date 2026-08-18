///|
fn clamp_score(score : Double) -> Double {
  if score < 0.0 {
    0.0
  } else if score > 1.0 {
    1.0
  } else {
    score
  }
}

///|
fn string_similarity(
  a : String,
  b : String,
  metric : @core.MetricType,
) -> Double {
  match metric {
    @core.ExactMatch => if a == b { 1.0 } else { 0.0 }
    @core.Levenshtein => @similarity.levenshtein_similarity(a, b)
    @core.DamerauLevenshtein => @similarity.damerau_levenshtein_similarity(a, b)
    @core.JaroWinkler => @similarity.jaro_winkler(a, b)
    @core.JaccardNgram(n) => @similarity.ngram_jaccard(a, b, n~)
    @core.Cosine => @similarity.cosine_similarity([a], [b])
    @core.SoftTFIDF(_) => @similarity.jaro_winkler(a, b)
    @core.PhoneticSoundex =>
      if @phonetic.soundex_match(a, b) {
        1.0
      } else {
        0.0
      }
    @core.PhoneticMetaphone =>
      if @phonetic.metaphone_match(a, b) {
        1.0
      } else {
        0.0
      }
    _ => @similarity.jaro_winkler(a, b)
  }
}

///|
/// Compare two field values using the configured metric, including typed values.
pub fn compare_field_values(
  left : @core.FieldValue,
  right : @core.FieldValue,
  metric : @core.MetricType,
) -> Double {
  let result = match (left, right, metric) {
    (@core.DoubleVal(a), @core.DoubleVal(b), @core.NumericAbsolute(max_diff)) =>
      @similarity.numeric_absolute_similarity(a, b, max_diff~)
    (@core.IntVal(a), @core.IntVal(b), @core.NumericAbsolute(max_diff)) =>
      @similarity.numeric_absolute_similarity(
        a.to_double(),
        b.to_double(),
        max_diff~,
      )
    (@core.DoubleVal(a), @core.DoubleVal(b), @core.NumericRelative(max_pct)) =>
      @similarity.numeric_relative_similarity(a, b, max_pct~)
    (
      @core.GeoVal(a_lat, a_lon),
      @core.GeoVal(b_lat, b_lon),
      @core.GeoHaversine(max_km),
    ) =>
      @similarity.geo_haversine_similarity(a_lat, a_lon, b_lat, b_lon, max_km~)
    (value_a, value_b, _) =>
      string_similarity(value_a.to_str(), value_b.to_str(), metric)
  }
  clamp_score(result)
}
