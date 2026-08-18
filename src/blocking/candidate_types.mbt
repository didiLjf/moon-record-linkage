///|
/// Controls how several blocking strategies are combined.
pub(all) enum PlanMode {
  Union
  Intersection
  Fallback
} derive(Debug, Eq)

///|
/// A normalized pair retained by the candidate planner.
pub struct CandidatePair {
  left_id : String
  right_id : String
  origins : Array[String]
} derive(Debug, Eq)

///|
/// Candidate planning limits and empty-key behavior.
pub struct PlannerOptions {
  mode : PlanMode
  max_pairs : Int
  keep_empty_keys : Bool
} derive(Debug, Eq)

///|
pub fn PlannerOptions::new(
  mode? : PlanMode = Union,
  max_pairs? : Int = 100000,
  keep_empty_keys? : Bool = false,
) -> PlannerOptions {
  {
    mode,
    max_pairs: if max_pairs < 0 {
      0
    } else {
      max_pairs
    },
    keep_empty_keys,
  }
}

///|
/// The full candidate set plus auditable planning statistics.
pub struct CandidatePlan {
  pairs : Array[CandidatePair]
  strategy_counts : Map[String, Int]
  raw_pair_count : Int
  deduplicated_pair_count : Int
  truncated : Bool
} derive(Debug)

///|
pub fn CandidatePlan::reduction_ratio(
  self : CandidatePlan,
  left_count : Int,
  right_count : Int,
) -> Double {
  let total = left_count * right_count
  if total <= 0 {
    0.0
  } else {
    1.0 - self.pairs.length().to_double() / total.to_double()
  }
}

///|
/// Per-block size statistics used to spot overly broad or empty blocks.
pub struct BlockingStats {
  record_count : Int
  block_count : Int
  largest_block_size : Int
  total_memberships : Int
  average_block_size : Double
} derive(Debug, Eq)
