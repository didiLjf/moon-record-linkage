// Canopy Clustering Blocker
// Groups records into overlapping canopies using two distance thresholds T1 < T2.
// - T1 (tight): records within T1 are candidates for detailed comparison
// - T2 (loose): records within T2 are assigned to the same canopy

///|
pub struct CanopyBlocker {
  key_field : String
  t1 : Double
  t2 : Double
} derive(Debug, Eq)

///|
pub fn CanopyBlocker::new(
  key_field : String,
  t1? : Double = 0.5,
  t2? : Double = 0.8,
) -> CanopyBlocker {
  { key_field, t1, t2 }
}

///|
/// Compute normalized edit similarity between two strings as a "distance" proxy.
fn canopy_string_similarity(a : String, b : String) -> Double {
  let a_chars = a.to_array()
  let b_chars = b.to_array()
  let m = a_chars.length()
  let n = b_chars.length()
  if m == 0 && n == 0 {
    return 1.0
  }
  if m == 0 || n == 0 {
    return 0.0
  }
  // Levenshtein distance via two-row DP
  let mut prev = FixedArray::make(n + 1, 0)
  let mut curr = FixedArray::make(n + 1, 0)
  for j = 0; j <= n; j = j + 1 {
    prev[j] = j
  }
  for i = 1; i <= m; i = i + 1 {
    curr[0] = i
    for j = 1; j <= n; j = j + 1 {
      if a_chars[i - 1] == b_chars[j - 1] {
        curr[j] = prev[j - 1]
      } else {
        let d = prev[j] + 1
        let ins = curr[j - 1] + 1
        let sub = prev[j - 1] + 1
        let min12 = if d < ins { d } else { ins }
        curr[j] = if min12 < sub { min12 } else { sub }
      }
    }
    let tmp = prev
    prev = curr
    curr = tmp
  }
  let dist = prev[n]
  let max_len = if m > n { m } else { n }
  1.0 - dist.to_double() / max_len.to_double()
}

///|
pub struct Canopy {
  center_id : String
  members : Array[String]
} derive(Debug)

///|
/// Build canopies from a list of records.
/// Returns an array of Canopy objects.
pub fn CanopyBlocker::build_canopies(
  self : CanopyBlocker,
  records : Array[@core.Record],
) -> Array[Canopy] {
  let canopies : Array[Canopy] = []
  let removed : Map[String, Bool] = Map([])
  let keys : Array[(String, String)] = [] // (record_id, key_value)
  for r in records {
    let key = @normalization.to_lowercase(r.get_string(self.key_field))
    keys.push((r.id, key))
  }
  let mut i = 0
  while i < keys.length() {
    let (center_id, center_key) = keys[i]
    if removed.contains(center_id) {
      i = i + 1
      continue
    }
    let canopy : Canopy = { center_id, members: [center_id] }
    for j = 0; j < keys.length(); j = j + 1 {
      if i == j {
        continue
      }
      let (other_id, other_key) = keys[j]
      if removed.contains(other_id) {
        continue
      }
      let sim = canopy_string_similarity(center_key, other_key)
      if sim >= self.t1 {
        canopy.members.push(other_id)
        // Remove from pool if within tight threshold
        if sim >= self.t2 {
          removed.set(other_id, true)
        }
      }
    }
    canopies.push(canopy)
    removed.set(center_id, true)
    i = i + 1
  }
  canopies
}

///|
/// Generate candidate pairs from canopies.
pub fn canopies_to_pairs(canopies : Array[Canopy]) -> Array[(String, String)] {
  let seen : Map[String, Bool] = Map([])
  let result : Array[(String, String)] = []
  for canopy in canopies {
    let n = canopy.members.length()
    for i = 0; i < n; i = i + 1 {
      for j = i + 1; j < n; j = j + 1 {
        let key = canopy.members[i] + "##" + canopy.members[j]
        if !seen.contains(key) {
          seen.set(key, true)
          result.push((canopy.members[i], canopy.members[j]))
        }
      }
    }
  }
  result
}
