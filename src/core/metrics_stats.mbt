// Linkage Evaluation & Quality Metrics Statistics

///|
pub struct EvaluationMetrics {
  mut true_positives : Int
  mut false_positives : Int
  mut true_negatives : Int
  mut false_negatives : Int
  mut total_pairs_evaluated : Int
  total_possible_pairs : Int
} derive(Debug, Eq)

///|
pub fn EvaluationMetrics::new(
  total_possible_pairs? : Int = 0,
) -> EvaluationMetrics {
  {
    true_positives: 0,
    false_positives: 0,
    true_negatives: 0,
    false_negatives: 0,
    total_pairs_evaluated: 0,
    total_possible_pairs,
  }
}

///|
pub fn EvaluationMetrics::add_observation(
  self : EvaluationMetrics,
  predicted_match : Bool,
  actual_match : Bool,
) -> Unit {
  self.total_pairs_evaluated = self.total_pairs_evaluated + 1
  if predicted_match && actual_match {
    self.true_positives = self.true_positives + 1
  } else if predicted_match && !actual_match {
    self.false_positives = self.false_positives + 1
  } else if !predicted_match && actual_match {
    self.false_negatives = self.false_negatives + 1
  } else {
    self.true_negatives = self.true_negatives + 1
  }
}

///|
pub fn EvaluationMetrics::get_tp(self : EvaluationMetrics) -> Int {
  self.true_positives
}

///|
pub fn EvaluationMetrics::get_fp(self : EvaluationMetrics) -> Int {
  self.false_positives
}

///|
pub fn EvaluationMetrics::get_fn(self : EvaluationMetrics) -> Int {
  self.false_negatives
}

///|
pub fn EvaluationMetrics::get_tn(self : EvaluationMetrics) -> Int {
  self.true_negatives
}

///|
pub fn EvaluationMetrics::precision(self : EvaluationMetrics) -> Double {
  let tp = self.true_positives.to_double()
  let fp = self.false_positives.to_double()
  if tp + fp == 0.0 {
    0.0
  } else {
    tp / (tp + fp)
  }
}

///|
pub fn EvaluationMetrics::recall(self : EvaluationMetrics) -> Double {
  let tp = self.true_positives.to_double()
  let fn_val = self.false_negatives.to_double()
  if tp + fn_val == 0.0 {
    0.0
  } else {
    tp / (tp + fn_val)
  }
}

///|
pub fn EvaluationMetrics::f1_score(self : EvaluationMetrics) -> Double {
  let p = self.precision()
  let r = self.recall()
  if p + r == 0.0 {
    0.0
  } else {
    2.0 * p * r / (p + r)
  }
}

///|
pub fn EvaluationMetrics::accuracy(self : EvaluationMetrics) -> Double {
  let tp = self.true_positives.to_double()
  let tn = self.true_negatives.to_double()
  let total = self.total_pairs_evaluated.to_double()
  if total == 0.0 {
    0.0
  } else {
    (tp + tn) / total
  }
}

///|
pub fn EvaluationMetrics::reduction_ratio(self : EvaluationMetrics) -> Double {
  if self.total_possible_pairs == 0 {
    0.0
  } else {
    let evaluated = self.total_pairs_evaluated.to_double()
    let total_possible = self.total_possible_pairs.to_double()
    1.0 - evaluated / total_possible
  }
}

///|
pub fn EvaluationMetrics::pair_completeness(self : EvaluationMetrics) -> Double {
  let tp = self.true_positives.to_double()
  let fn_val = self.false_negatives.to_double()
  let total_true_matches = tp + fn_val
  if total_true_matches == 0.0 {
    0.0
  } else {
    tp / total_true_matches
  }
}

///|
fn int_to_pct_str(v : Double) -> String {
  let scaled = (v * 10000.0).to_int()
  let whole = scaled / 100
  let frac = scaled % 100
  if frac < 10 {
    whole.to_string() + ".0" + frac.to_string()
  } else {
    whole.to_string() + "." + frac.to_string()
  }
}

///|
pub fn EvaluationMetrics::summary_report(self : EvaluationMetrics) -> String {
  let p = self.precision()
  let r = self.recall()
  let f1 = self.f1_score()
  let rr = self.reduction_ratio()
  let sb = StringBuilder(size_hint=256)
  sb.write_string("Evaluation Summary:\n")
  sb.write_string(
    "  TP: " +
    self.true_positives.to_string() +
    " | FP: " +
    self.false_positives.to_string() +
    "\n",
  )
  sb.write_string(
    "  TN: " +
    self.true_negatives.to_string() +
    " | FN: " +
    self.false_negatives.to_string() +
    "\n",
  )
  sb.write_string("  Precision: " + int_to_pct_str(p) + "%\n")
  sb.write_string("  Recall:    " + int_to_pct_str(r) + "%\n")
  sb.write_string("  F1-Score:  " + int_to_pct_str(f1) + "%\n")
  sb.write_string("  Reduction Ratio: " + int_to_pct_str(rr) + "%")
  sb.to_string()
}
