///|
/// A score contribution that can be shown to an operator.
pub struct FieldContribution {
  field_name : String
  raw_score : Double
  weight : Double
  weighted_score : Double
  missing : Bool
} derive(Debug, Eq)

///|
/// Full explanation of one pair decision.
pub struct ScoreExplanation {
  pair_id : String
  field_contributions : Array[FieldContribution]
  missing_fields : Array[String]
  composite_score : Double
  status : @core.MatchStatus
  decision_reason : String
} derive(Debug)

///|
/// A score and its gold label used for threshold calibration.
pub struct LabeledScore {
  score : Double
  actual_match : Bool
} derive(Debug, Eq)

///|
pub fn LabeledScore::new(score : Double, actual_match : Bool) -> LabeledScore {
  { score, actual_match }
}

///|
/// Confusion matrix for a thresholded collection of scores.
pub struct ConfusionMatrix {
  mut true_positives : Int
  mut false_positives : Int
  mut true_negatives : Int
  mut false_negatives : Int
} derive(Debug, Eq)

///|
pub fn ConfusionMatrix::from_scores(
  scores : Array[LabeledScore],
  threshold~ : Double,
) -> ConfusionMatrix {
  let result = {
    true_positives: 0,
    false_positives: 0,
    true_negatives: 0,
    false_negatives: 0,
  }
  for labeled in scores {
    let predicted = labeled.score >= threshold
    if predicted && labeled.actual_match {
      result.true_positives = result.true_positives + 1
    } else if predicted && !labeled.actual_match {
      result.false_positives = result.false_positives + 1
    } else if !predicted && labeled.actual_match {
      result.false_negatives = result.false_negatives + 1
    } else {
      result.true_negatives = result.true_negatives + 1
    }
  }
  result
}

///|
pub fn ConfusionMatrix::precision(self : ConfusionMatrix) -> Double {
  let denominator = self.true_positives + self.false_positives
  if denominator == 0 {
    0.0
  } else {
    self.true_positives.to_double() / denominator.to_double()
  }
}

///|
pub fn ConfusionMatrix::recall(self : ConfusionMatrix) -> Double {
  let denominator = self.true_positives + self.false_negatives
  if denominator == 0 {
    0.0
  } else {
    self.true_positives.to_double() / denominator.to_double()
  }
}

///|
pub fn ConfusionMatrix::f1(self : ConfusionMatrix) -> Double {
  let p = self.precision()
  let r = self.recall()
  if p + r == 0.0 {
    0.0
  } else {
    2.0 * p * r / (p + r)
  }
}

///|
pub struct ThresholdPoint {
  threshold : Double
  confusion : ConfusionMatrix
  precision : Double
  recall : Double
  f1 : Double
} derive(Debug, Eq)

///|
pub struct CalibrationReport {
  thresholds : Array[ThresholdPoint]
  best_f1_threshold : Double
  confusion_at_best : ConfusionMatrix
} derive(Debug)
