// Evaluation Reporter: formats linkage evaluation metrics into text reports.

///|
/// Format EvaluationMetrics into a human-readable text report.
pub fn format_metrics_report(metrics : @core.EvaluationMetrics) -> String {
  let sb = StringBuilder(size_hint=512)
  sb.write_string("=== Record Linkage Evaluation Report ===\n")
  sb.write_string("True Positives (TP):  ")
  sb.write_string(metrics.get_tp().to_string())
  sb.write_string("\nFalse Positives (FP): ")
  sb.write_string(metrics.get_fp().to_string())
  sb.write_string("\nFalse Negatives (FN): ")
  sb.write_string(metrics.get_fn().to_string())
  sb.write_string("\nTrue Negatives (TN):  ")
  sb.write_string(metrics.get_tn().to_string())
  sb.write_string("\n----------------------------------------\n")
  sb.write_string("Precision: ")
  sb.write_string(metrics.precision().to_string())
  sb.write_string("\nRecall:    ")
  sb.write_string(metrics.recall().to_string())
  sb.write_string("\nF1-Score:  ")
  sb.write_string(metrics.f1_score().to_string())
  sb.write_string("\nAccuracy:  ")
  sb.write_string(metrics.accuracy().to_string())
  sb.write_string("\n========================================\n")
  sb.to_string()
}

///|
/// Format blocking efficiency metrics report.
pub fn format_blocking_report(
  candidate_pairs : Int,
  total_pairs : Int,
) -> String {
  let sb = StringBuilder(size_hint=256)
  let reduction = if total_pairs > 0 {
    1.0 - candidate_pairs.to_double() / total_pairs.to_double()
  } else {
    0.0
  }
  sb.write_string("=== Blocking Efficiency Report ===\n")
  sb.write_string("Total Cartesian Pairs: ")
  sb.write_string(total_pairs.to_string())
  sb.write_string("\nCandidate Pairs:       ")
  sb.write_string(candidate_pairs.to_string())
  sb.write_string("\nReduction Ratio:       ")
  sb.write_string((reduction * 100.0).to_string())
  sb.write_string("%\n==================================\n")
  sb.to_string()
}
