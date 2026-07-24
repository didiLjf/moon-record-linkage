// Jaro and Jaro-Winkler String Similarity Metrics
// Specifically designed for short string matching (names, IDs).

///|
/// Compute the Jaro similarity between two strings.
/// Returns a value in [0.0, 1.0].
pub fn jaro(a : String, b : String) -> Double {
  let a_chars = a.to_array()
  let b_chars = b.to_array()
  let a_len = a_chars.length()
  let b_len = b_chars.length()
  if a_len == 0 && b_len == 0 {
    return 1.0
  }
  if a_len == 0 || b_len == 0 {
    return 0.0
  }
  // Match window
  let max_len = if a_len > b_len { a_len } else { b_len }
  let match_window = max_len / 2 - 1
  let window = if match_window < 0 { 0 } else { match_window }
  let a_matched = FixedArray::make(a_len, false)
  let b_matched = FixedArray::make(b_len, false)
  let mut matches = 0
  // Find matches
  for i = 0; i < a_len; i = i + 1 {
    let start = if i - window > 0 { i - window } else { 0 }
    let end = if i + window + 1 < b_len { i + window + 1 } else { b_len }
    for j = start; j < end; j = j + 1 {
      if !b_matched[j] && a_chars[i] == b_chars[j] {
        a_matched[i] = true
        b_matched[j] = true
        matches = matches + 1
        break
      }
    }
  }
  if matches == 0 {
    return 0.0
  }
  // Count transpositions
  let mut transpositions = 0
  let mut k = 0
  for i = 0; i < a_len; i = i + 1 {
    if a_matched[i] {
      while !b_matched[k] {
        k = k + 1
      }
      if a_chars[i] != b_chars[k] {
        transpositions = transpositions + 1
      }
      k = k + 1
    }
  }
  let m = matches.to_double()
  let t = transpositions.to_double() / 2.0
  (m / a_len.to_double() + m / b_len.to_double() + (m - t) / m) / 3.0
}

///|
/// Compute the Jaro-Winkler similarity.
/// Gives extra weight to strings sharing a common prefix.
/// p is the scaling factor (typically 0.1, max 0.25).
pub fn jaro_winkler(
  a : String,
  b : String,
  prefix_weight? : Double = 0.1,
) -> Double {
  let j = jaro(a, b)
  let a_chars = a.to_array()
  let b_chars = b.to_array()
  let max_prefix = 4
  let min_len = if a_chars.length() < b_chars.length() {
    a_chars.length()
  } else {
    b_chars.length()
  }
  let limit = if min_len < max_prefix { min_len } else { max_prefix }
  let mut prefix_len = 0
  for i = 0; i < limit; i = i + 1 {
    if a_chars[i] == b_chars[i] {
      prefix_len = prefix_len + 1
    } else {
      break
    }
  }
  j + prefix_len.to_double() * prefix_weight * (1.0 - j)
}

///|
/// Threshold-based match: returns true if jaro_winkler >= threshold.
pub fn jaro_winkler_match(
  a : String,
  b : String,
  threshold? : Double = 0.9,
) -> Bool {
  jaro_winkler(a, b) >= threshold
}
