// Linkage Pipeline Configuration Models

///|
pub(all) enum BlockingStrategy {
  StandardBlocking(Array[String])
  SortedNeighborhood(String, Int)
  CanopyClustering(String, Double, Double)
  LocalitySensitiveHashing(String, Int, Int)
  CompositeBlocking(Array[BlockingStrategy])
} derive(Debug, Eq)

///|
pub(all) enum MetricType {
  ExactMatch
  Levenshtein
  DamerauLevenshtein
  JaroWinkler
  JaccardNgram(Int)
  Cosine
  SoftTFIDF(Double)
  NumericAbsolute(Double)
  NumericRelative(Double)
  GeoHaversine(Double)
  PhoneticSoundex
  PhoneticMetaphone
} derive(Debug, Eq)

///|
pub struct FieldComparisonConfig {
  field_name : String
  metric : MetricType
  weight : Double
  missing_value_penalty : Double
} derive(Debug, Eq)

///|
pub struct ModelThresholds {
  match_threshold : Double
  non_match_threshold : Double
} derive(Debug, Eq)

///|
pub struct LinkageConfig {
  blocking_strategies : Array[BlockingStrategy]
  field_comparisons : Array[FieldComparisonConfig]
  mut thresholds : ModelThresholds
  enable_em_training : Bool
  max_em_iterations : Int
  em_convergence_delta : Double
} derive(Debug, Eq)

///|
pub fn LinkageConfig::default() -> LinkageConfig {
  {
    blocking_strategies: [],
    field_comparisons: [],
    thresholds: { match_threshold: 0.85, non_match_threshold: 0.45 },
    enable_em_training: true,
    max_em_iterations: 50,
    em_convergence_delta: 0.0001,
  }
}

///|
pub fn LinkageConfig::new(_name : String) -> LinkageConfig {
  LinkageConfig::default()
}

///|
pub fn LinkageConfig::add_blocking(
  self : LinkageConfig,
  strategy : BlockingStrategy,
) -> Unit {
  self.blocking_strategies.push(strategy)
}

///|
pub fn LinkageConfig::add_field_comparison(
  self : LinkageConfig,
  field_name : String,
  metric : MetricType,
  weight? : Double = 1.0,
  penalty? : Double = 0.0,
) -> Unit {
  self.field_comparisons.push({
    field_name,
    metric,
    weight,
    missing_value_penalty: penalty,
  })
}

///|
pub fn LinkageConfig::set_thresholds(
  self : LinkageConfig,
  match_threshold : Double,
  non_match_threshold : Double,
) -> Unit {
  self.thresholds = { match_threshold, non_match_threshold }
}

///|
pub fn LinkageConfig::field_count(self : LinkageConfig) -> Int {
  self.field_comparisons.length()
}

///|
pub fn LinkageConfig::total_weight(self : LinkageConfig) -> Double {
  let mut total = 0.0
  for fc in self.field_comparisons {
    total = total + fc.weight
  }
  total
}
