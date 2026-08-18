///|
pub struct SyntheticDatasetConfig {
  entity_count : Int
  seed : Int
  noise_level : Double
  duplicate_rate : Double
} derive(Debug, Eq)

///|
pub fn SyntheticDatasetConfig::new(
  entity_count? : Int = 100,
  seed? : Int = 1,
  noise_level? : Double = 0.1,
  duplicate_rate? : Double = 1.0,
) -> SyntheticDatasetConfig {
  {
    entity_count: if entity_count < 0 {
      0
    } else {
      entity_count
    },
    seed,
    noise_level: if noise_level < 0.0 {
      0.0
    } else if noise_level > 1.0 {
      1.0
    } else {
      noise_level
    },
    duplicate_rate: if duplicate_rate < 0.0 {
      0.0
    } else if duplicate_rate > 1.0 {
      1.0
    } else {
      duplicate_rate
    },
  }
}

///|
pub struct GoldPair {
  left_id : String
  right_id : String
  actual_match : Bool
} derive(Debug, Eq)

///|
pub fn GoldPair::new(
  left_id : String,
  right_id : String,
  actual_match : Bool,
) -> GoldPair {
  { left_id, right_id, actual_match }
}

///|
pub struct SyntheticDataset {
  left_records : Array[@core.Record]
  right_records : Array[@core.Record]
  gold_pairs : Array[GoldPair]
  entity_count : Int
} derive(Debug)

///|
pub struct PairEvaluationReport {
  true_positives : Int
  false_positives : Int
  false_negatives : Int
  candidate_count : Int
  gold_count : Int
} derive(Debug, Eq)

///|
pub fn PairEvaluationReport::from_zero() -> PairEvaluationReport {
  {
    true_positives: 0,
    false_positives: 0,
    false_negatives: 0,
    candidate_count: 0,
    gold_count: 0,
  }
}

///|
pub fn PairEvaluationReport::precision(self : PairEvaluationReport) -> Double {
  let denominator = self.true_positives + self.false_positives
  if denominator == 0 {
    0.0
  } else {
    self.true_positives.to_double() / denominator.to_double()
  }
}

///|
pub fn PairEvaluationReport::recall(self : PairEvaluationReport) -> Double {
  if self.gold_count == 0 {
    0.0
  } else {
    self.true_positives.to_double() / self.gold_count.to_double()
  }
}

///|
pub fn PairEvaluationReport::f1(self : PairEvaluationReport) -> Double {
  let p = self.precision()
  let r = self.recall()
  if p + r == 0.0 {
    0.0
  } else {
    2.0 * p * r / (p + r)
  }
}

///|
pub fn candidate_reduction_ratio(
  total_possible : Int,
  candidate_count : Int,
) -> Double {
  if total_possible <= 0 {
    0.0
  } else {
    1.0 - candidate_count.to_double() / total_possible.to_double()
  }
}
