///|
/// Evaluate a score set over a fixed threshold grid and choose the best F1.
pub fn calibrate_thresholds(
  scores : Array[LabeledScore],
  step? : Double = 0.05,
) -> Result[CalibrationReport, @core.RecordLinkageError] {
  if scores.is_empty() {
    return Err(@core.PipelineError("cannot calibrate an empty score set"))
  }
  if step <= 0.0 || step > 1.0 {
    return Err(@core.PipelineError("calibration step must be in (0, 1]"))
  }
  let steps = (1.0 / step).to_int()
  let points : Array[ThresholdPoint] = []
  let mut best_threshold = 0.0
  let mut best_f1 = -1.0
  let mut best_matrix = ConfusionMatrix::from_scores(scores, threshold=0.0)
  for index = 0; index <= steps; index = index + 1 {
    let threshold = index.to_double() * step
    let bounded_threshold = if threshold > 1.0 { 1.0 } else { threshold }
    let confusion = ConfusionMatrix::from_scores(
      scores,
      threshold=bounded_threshold,
    )
    let precision = confusion.precision()
    let recall = confusion.recall()
    let f1 = confusion.f1()
    points.push({
      threshold: bounded_threshold,
      confusion,
      precision,
      recall,
      f1,
    })
    if f1 > best_f1 {
      best_f1 = f1
      best_threshold = bounded_threshold
      best_matrix = confusion
    }
  }
  Ok({
    thresholds: points,
    best_f1_threshold: best_threshold,
    confusion_at_best: best_matrix,
  })
}
