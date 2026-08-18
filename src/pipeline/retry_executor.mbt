///|
/// Describe an isolated failed record attempt for a caller-provided retry loop.
pub struct FailureRecord {
  record_id : String
  attempt : Int
  code : String
  retryable : Bool
  message : String
} derive(Debug, Eq)

///|
pub fn FailureRecord::new(
  record_id : String,
  attempt : Int,
  code : String,
  retryable : Bool,
  message : String,
) -> FailureRecord {
  { record_id, attempt, code, retryable, message }
}

///|
pub fn retry_summary(
  policy : RetryPolicy,
  failures : Array[FailureRecord],
) -> (Int, Int) {
  let mut retryable_count = 0
  let mut exhausted_count = 0
  for failure in failures {
    if failure.retryable &&
      policy.should_retry(attempt=failure.attempt, retryable=true) {
      retryable_count = retryable_count + 1
    } else {
      exhausted_count = exhausted_count + 1
    }
  }
  (retryable_count, exhausted_count)
}
