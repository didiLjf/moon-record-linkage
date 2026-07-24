// Sorted Neighborhood Method (SNM)
// Sort records by a key field, then compare only within a sliding window.

///|
fn compare_strings(a : String, b : String) -> Int {
  let ca = a.to_array()
  let cb = b.to_array()
  let la = ca.length()
  let lb = cb.length()
  let min_l = if la < lb { la } else { lb }
  for i = 0; i < min_l; i = i + 1 {
    if ca[i] < cb[i] {
      return -1
    } else if ca[i] > cb[i] {
      return 1
    }
  }
  if la < lb {
    -1
  } else if la > lb {
    1
  } else {
    0
  }
}

///|
pub struct SNMBlocker {
  key_field : String
  window_size : Int
} derive(Debug, Eq)

///|
pub fn SNMBlocker::new(
  key_field : String,
  window_size? : Int = 5,
) -> SNMBlocker {
  { key_field, window_size }
}

///|
/// Build a sorted list of (sort_key, record_id) pairs from the records.
pub fn SNMBlocker::build_sorted_keys(
  self : SNMBlocker,
  records : Array[@core.Record],
) -> Array[(String, String)] {
  let keyed : Array[(String, String)] = []
  for r in records {
    let key = @normalization.to_lowercase(r.get_string(self.key_field))
    keyed.push((key, r.id))
  }
  let n = keyed.length()
  for i = 0; i < n; i = i + 1 {
    let mut min_idx = i
    for j = i + 1; j < n; j = j + 1 {
      if compare_strings(keyed[j].0, keyed[min_idx].0) < 0 {
        min_idx = j
      }
    }
    if min_idx != i {
      let tmp = keyed[i]
      keyed[i] = keyed[min_idx]
      keyed[min_idx] = tmp
    }
  }
  keyed
}

///|
/// Generate candidate pairs using a sliding window over sorted records.
pub fn SNMBlocker::candidate_pairs(
  self : SNMBlocker,
  records : Array[@core.Record],
) -> Array[(String, String)] {
  let sorted = self.build_sorted_keys(records)
  let n = sorted.length()
  let pairs : Array[(String, String)] = []
  for i = 0; i < n; i = i + 1 {
    for j = i + 1; j < n && j <= i + self.window_size; j = j + 1 {
      pairs.push((sorted[i].1, sorted[j].1))
    }
  }
  pairs
}

///|
/// Cross-dataset SNM: merge two sorted lists and apply the window.
pub fn SNMBlocker::cross_candidate_pairs(
  self : SNMBlocker,
  records_a : Array[@core.Record],
  records_b : Array[@core.Record],
) -> Array[(String, String)] {
  // Tag which dataset each record belongs to
  let keyed : Array[(String, String, Bool)] = [] // (key, id, is_from_b)
  for r in records_a {
    let key = @normalization.to_lowercase(r.get_string(self.key_field))
    keyed.push((key, r.id, false))
  }
  for r in records_b {
    let key = @normalization.to_lowercase(r.get_string(self.key_field))
    keyed.push((key, r.id, true))
  }
  let n = keyed.length()
  for i = 0; i < n; i = i + 1 {
    let mut min_idx = i
    for j = i + 1; j < n; j = j + 1 {
      if compare_strings(keyed[j].0, keyed[min_idx].0) < 0 {
        min_idx = j
      }
    }
    if min_idx != i {
      let tmp = keyed[i]
      keyed[i] = keyed[min_idx]
      keyed[min_idx] = tmp
    }
  }
  let pairs : Array[(String, String)] = []
  for i = 0; i < n; i = i + 1 {
    for j = i + 1; j < n && j <= i + self.window_size; j = j + 1 {
      let (_, id_i, is_b_i) = keyed[i]
      let (_, id_j, is_b_j) = keyed[j]
      if is_b_i != is_b_j {
        if is_b_i {
          pairs.push((id_j, id_i))
        } else {
          pairs.push((id_i, id_j))
        }
      }
    }
  }
  pairs
}
