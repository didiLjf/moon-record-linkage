///|
/// Compute block-size statistics for a single blocking key.
pub fn block_statistics(
  records : Array[@core.Record],
  fields : Array[String],
) -> BlockingStats {
  let index = BlockingIndex::new(fields)
  index.build_from(records)
  let mut largest = 0
  let mut total = 0
  for entry in index.blocks {
    let size = entry.1.length()
    total = total + size
    if size > largest {
      largest = size
    }
  }
  let average = if index.blocks.length() == 0 {
    0.0
  } else {
    total.to_double() / index.blocks.length().to_double()
  }
  {
    record_count: records.length(),
    block_count: index.blocks.length(),
    largest_block_size: largest,
    total_memberships: total,
    average_block_size: average,
  }
}
