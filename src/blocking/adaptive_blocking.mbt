///|
pub(all) enum AdaptiveMode {
  Conservative
  Balanced
  Aggressive
} derive(Debug, Eq)

///|
pub struct AdaptivePlan {
  selected_field : String
  strategies : Array[@core.BlockingStrategy]
  expected_candidate_count : Int
  largest_block_size : Int
  reason : String
} derive(Debug)

///|
fn select_field(
  records : Array[@core.Record],
  fields : Array[String],
) -> (String, BlockingStats) {
  if fields.is_empty() {
    return ("id", block_statistics(records, ["id"]))
  }
  let mut selected = fields[0]
  let mut selected_stats = block_statistics(records, [selected])
  for field in fields {
    let stats = block_statistics(records, [field])
    if stats.block_count > selected_stats.block_count ||
      (
        stats.block_count == selected_stats.block_count &&
        stats.largest_block_size < selected_stats.largest_block_size
      ) {
      selected = field
      selected_stats = stats
    }
  }
  (selected, selected_stats)
}

///|
/// Recommend a blocking policy from observed block selectivity.
pub fn recommend_blocking(
  records : Array[@core.Record],
  fields : Array[String],
  mode~ : AdaptiveMode,
) -> AdaptivePlan {
  let (selected, stats) = select_field(records, fields)
  let strategies : Array[@core.BlockingStrategy] = [
    @core.StandardBlocking([selected]),
  ]
  match mode {
    Conservative => ()
    Balanced => ()
    Aggressive => strategies.push(@core.SortedNeighborhood(selected, 3))
  }
  let expected = if stats.block_count == 0 {
    0
  } else {
    stats.largest_block_size * stats.largest_block_size
  }
  {
    selected_field: selected,
    strategies,
    expected_candidate_count: expected,
    largest_block_size: stats.largest_block_size,
    reason: "selected " +
    selected +
    " with " +
    stats.block_count.to_string() +
    " blocks",
  }
}
