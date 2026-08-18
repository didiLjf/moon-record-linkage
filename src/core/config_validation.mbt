///|
fn validate_thresholds(thresholds : ModelThresholds) -> String? {
  if thresholds.match_threshold < 0.0 || thresholds.match_threshold > 1.0 {
    Some("match threshold must be in [0, 1]")
  } else if thresholds.non_match_threshold < 0.0 ||
    thresholds.non_match_threshold > 1.0 {
    Some("non-match threshold must be in [0, 1]")
  } else if thresholds.non_match_threshold > thresholds.match_threshold {
    Some("non-match threshold cannot exceed match threshold")
  } else {
    None
  }
}

///|
fn validate_blocking_strategy(strategy : BlockingStrategy) -> String? {
  match strategy {
    StandardBlocking(fields) =>
      if fields.is_empty() {
        Some("standard blocking requires a field")
      } else {
        None
      }
    SortedNeighborhood(field, window) =>
      if field.is_empty() {
        Some("sorted neighborhood requires a field")
      } else if window <= 0 {
        Some("sorted neighborhood window must be positive")
      } else {
        None
      }
    CanopyClustering(field, t1, t2) =>
      if field.is_empty() {
        Some("canopy requires a field")
      } else if t1 < 0.0 || t2 < t1 || t2 > 1.0 {
        Some("canopy thresholds must satisfy 0 <= t1 <= t2 <= 1")
      } else {
        None
      }
    LocalitySensitiveHashing(field, hashes, bands) =>
      if field.is_empty() {
        Some("LSH requires a field")
      } else if hashes <= 0 || bands <= 0 || hashes < bands {
        Some("LSH hashes and bands must be positive and hashes >= bands")
      } else {
        None
      }
    CompositeBlocking(children) =>
      if children.is_empty() {
        Some("composite blocking requires a child")
      } else {
        for child in children {
          match validate_blocking_strategy(child) {
            Some(message) => return Some(message)
            None => ()
          }
        }
        None
      }
  }
}

///|
/// Validate a linkage configuration before starting a potentially expensive run.
pub fn validate_config(
  config : LinkageConfig,
) -> Result[Unit, RecordLinkageError] {
  match validate_thresholds(config.thresholds) {
    Some(message) => return Err(PipelineError(message))
    None => ()
  }
  if config.field_comparisons.is_empty() {
    return Err(PipelineError("at least one field comparison is required"))
  }
  let seen_fields : Map[String, Bool] = Map([])
  for comparison in config.field_comparisons {
    if comparison.field_name.is_empty() {
      return Err(PipelineError("comparison field name cannot be empty"))
    }
    if comparison.weight < 0.0 {
      return Err(PipelineError("comparison weight cannot be negative"))
    }
    if seen_fields.contains(comparison.field_name) {
      return Err(
        PipelineError(
          "comparison field cannot be repeated: " + comparison.field_name,
        ),
      )
    }
    seen_fields.set(comparison.field_name, true)
  }
  for strategy in config.blocking_strategies {
    match validate_blocking_strategy(strategy) {
      Some(message) => return Err(PipelineError(message))
      None => ()
    }
  }
  if config.max_em_iterations <= 0 || config.em_convergence_delta <= 0.0 {
    return Err(
      PipelineError("EM iteration and convergence settings must be positive"),
    )
  }
  Ok(())
}
