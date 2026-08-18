///|
/// A bounded page request for deterministic in-memory batch processing.
pub struct PageRequest {
  offset : Int
  limit : Int
} derive(Debug, Eq)

///|
pub fn PageRequest::new(offset? : Int = 0, limit? : Int = 100) -> PageRequest {
  {
    offset: if offset < 0 {
      0
    } else {
      offset
    },
    limit: if limit < 0 {
      0
    } else {
      limit
    },
  }
}

///|
pub struct PageResult {
  items : Array[@core.Record]
  offset : Int
  next_offset : Int
  has_more : Bool
} derive(Debug)

///|
pub struct RetryPolicy {
  max_attempts : Int
} derive(Debug, Eq)

///|
pub fn RetryPolicy::new(max_attempts? : Int = 1) -> RetryPolicy {
  { max_attempts: if max_attempts < 1 { 1 } else { max_attempts } }
}

///|
pub fn RetryPolicy::allowed_attempts(self : RetryPolicy) -> Int {
  self.max_attempts
}

///|
pub fn RetryPolicy::should_retry(
  self : RetryPolicy,
  attempt~ : Int,
  retryable~ : Bool,
) -> Bool {
  retryable && attempt >= 1 && attempt < self.max_attempts
}

///|
pub struct IncrementalState {
  records : Map[String, @core.Record]
  batches : Map[String, Bool]
} derive(Debug)

///|
pub fn IncrementalState::new() -> IncrementalState {
  { records: Map([]), batches: Map([]) }
}

///|
/// Insert a record, returning false when an existing ID was replaced.
pub fn IncrementalState::upsert(
  self : IncrementalState,
  record : @core.Record,
) -> Bool {
  let is_new = !self.records.contains(record.id)
  self.records.set(record.id, record)
  is_new
}

///|
pub fn IncrementalState::get(
  self : IncrementalState,
  id : String,
) -> @core.Record? {
  self.records.get(id)
}

///|
pub fn IncrementalState::record_count(self : IncrementalState) -> Int {
  self.records.length()
}

///|
/// Accept a batch identifier once; duplicate batches are no-ops.
pub fn IncrementalState::accept_batch(
  self : IncrementalState,
  batch_id : String,
) -> Bool {
  if self.batches.contains(batch_id) {
    false
  } else {
    self.batches.set(batch_id, true)
    true
  }
}

///|
pub fn IncrementalState::batch_count(self : IncrementalState) -> Int {
  self.batches.length()
}

///|
pub struct RunSummary {
  batch_id : String
  mut processed_records : Int
  mut candidate_pairs : Int
  mut matches : Int
  mut failures : Int
  mut elapsed_millis : Int64
} derive(Debug, Eq)

///|
pub fn RunSummary::new(batch_id : String) -> RunSummary {
  {
    batch_id,
    processed_records: 0,
    candidate_pairs: 0,
    matches: 0,
    failures: 0,
    elapsed_millis: 0L,
  }
}

///|
pub fn RunSummary::add_page(
  self : RunSummary,
  processed~ : Int,
  candidates~ : Int,
  matches~ : Int,
  failures~ : Int,
) -> Unit {
  let processed_value = if processed < 0 { 0 } else { processed }
  let candidate_value = if candidates < 0 { 0 } else { candidates }
  let match_value = if matches < 0 { 0 } else { matches }
  let failure_value = if failures < 0 { 0 } else { failures }
  self.processed_records = self.processed_records + processed_value
  self.candidate_pairs = self.candidate_pairs + candidate_value
  self.matches = self.matches + match_value
  self.failures = self.failures + failure_value
}

///|
pub fn RunSummary::set_elapsed_millis(
  self : RunSummary,
  elapsed : Int64,
) -> Unit {
  self.elapsed_millis = if elapsed < 0L { 0L } else { elapsed }
}

///|
pub fn RunSummary::throughput_per_second(self : RunSummary) -> Double {
  if self.elapsed_millis == 0L {
    0.0
  } else {
    self.processed_records.to_double() *
    1000.0 /
    self.elapsed_millis.to_double()
  }
}
