///|
test "calibration selects the best deterministic threshold" {
  let scores = [
    { score: 0.95, actual_match: true },
    { score: 0.82, actual_match: true },
    { score: 0.51, actual_match: false },
    { score: 0.20, actual_match: false },
  ]
  let report = match calibrate_thresholds(scores, step=0.1) {
    Ok(value) => value
    Err(_) => fail("calibration should succeed")
  }
  assert_true(report.best_f1_threshold >= 0.5)
  assert_true(report.best_f1_threshold <= 0.9)
  assert_true(report.confusion_at_best.f1() > 0.8)
  assert_true(report.thresholds.length() == 11)
}

///|
test "calibration rejects empty labels and invalid step" {
  let empty = calibrate_thresholds([], step=0.1)
  assert_true(empty is Err(@core.PipelineError(_)))
  let invalid = calibrate_thresholds(
    [{ score: 0.5, actual_match: true }],
    step=0.0,
  )
  assert_true(invalid is Err(@core.PipelineError(_)))
}

///|
test "confusion matrix handles threshold boundaries" {
  let scores = [
    { score: 0.5, actual_match: true },
    { score: 0.5, actual_match: false },
  ]
  let matrix = ConfusionMatrix::from_scores(scores, threshold=0.5)
  assert_eq(matrix.true_positives, 1)
  assert_eq(matrix.false_positives, 1)
  assert_eq(matrix.false_negatives, 0)
  assert_eq(matrix.precision(), 0.5)
}
