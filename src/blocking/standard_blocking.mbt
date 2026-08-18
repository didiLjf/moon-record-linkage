// Standard Blocking: partitions records into blocks by a blocking key
// so that comparisons are only performed within the same block.

///|
/// A blocking index: maps blocking key -> array of record IDs in that block.
pub struct BlockingIndex {
  blocks : Map[String, Array[String]]
  field_names : Array[String]
} derive(Debug)

///|
pub fn BlockingIndex::new(field_names : Array[String]) -> BlockingIndex {
  { blocks: Map([]), field_names }
}

///|
/// Compute a normalized blocking key from the complete field values.
pub fn BlockingIndex::compute_key(
  self : BlockingIndex,
  record : @core.Record,
) -> String {
  let sb = StringBuilder(size_hint=32)
  let mut first = true
  for fname in self.field_names {
    if !first {
      sb.write_char('|')
    }
    first = false
    let val = record.get_string(fname)
    sb.write_string(@normalization.to_lowercase(val))
  }
  @normalization.to_lowercase(sb.to_string())
}

///|
/// Add a record to the blocking index.
pub fn BlockingIndex::add_record(
  self : BlockingIndex,
  record : @core.Record,
) -> Unit {
  let key = self.compute_key(record)
  match self.blocks.get(key) {
    Some(ids) => ids.push(record.id)
    None => self.blocks.set(key, [record.id])
  }
}

///|
/// Add all records from an array to the index.
pub fn BlockingIndex::build_from(
  self : BlockingIndex,
  records : Array[@core.Record],
) -> Unit {
  for r in records {
    self.add_record(r)
  }
}

///|
/// Return all candidate pairs for comparison from the blocking index.
pub fn BlockingIndex::candidate_pairs(
  self : BlockingIndex,
) -> Array[(String, String)] {
  let pairs : Array[(String, String)] = []
  for entry in self.blocks {
    let ids = entry.1
    let n = ids.length()
    for i = 0; i < n; i = i + 1 {
      for j = i + 1; j < n; j = j + 1 {
        pairs.push((ids[i], ids[j]))
      }
    }
  }
  pairs
}

///|
/// Return the number of blocks.
pub fn BlockingIndex::block_count(self : BlockingIndex) -> Int {
  self.blocks.length()
}

///|
/// Return candidate pairs from two separate indexes (cross-dataset matching).
pub fn cross_match_pairs(
  index_a : BlockingIndex,
  index_b : BlockingIndex,
) -> Array[(String, String)] {
  let pairs : Array[(String, String)] = []
  for entry in index_a.blocks {
    let key = entry.0
    let ids_a = entry.1
    match index_b.blocks.get(key) {
      Some(ids_b) =>
        for id_a in ids_a {
          for id_b in ids_b {
            pairs.push((id_a, id_b))
          }
        }
      None => ()
    }
  }
  pairs
}

///|
/// Multi-key blocking: union of blocking pairs from multiple single-key indexes.
pub struct MultiKeyBlocker {
  indexes : Array[BlockingIndex]
} derive(Debug)

///|
pub fn MultiKeyBlocker::new() -> MultiKeyBlocker {
  { indexes: [] }
}

///|
pub fn MultiKeyBlocker::add_index(
  self : MultiKeyBlocker,
  index : BlockingIndex,
) -> Unit {
  self.indexes.push(index)
}

///|
pub fn MultiKeyBlocker::all_candidate_pairs(
  self : MultiKeyBlocker,
) -> Array[(String, String)] {
  let seen : Map[String, Bool] = Map([])
  let result : Array[(String, String)] = []
  for idx in self.indexes {
    let pairs = idx.candidate_pairs()
    for pair in pairs {
      let key = pair.0 + "##" + pair.1
      if !seen.contains(key) {
        seen.set(key, true)
        result.push(pair)
      }
    }
  }
  result
}
