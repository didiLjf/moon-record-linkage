// Edit Distance Metrics:
// - Levenshtein distance (insertions, deletions, substitutions)
// - Damerau-Levenshtein distance (+ transpositions)
// - Hamming distance
// - Normalized similarity scores

///|
/// Compute the Levenshtein edit distance between two strings.
/// Time: O(n*m), Space: O(n+m) with two-row DP.
pub fn levenshtein_distance(a : String, b : String) -> Int {
  let a_chars = a.to_array()
  let b_chars = b.to_array()
  let m = a_chars.length()
  let n = b_chars.length()
  if m == 0 {
    return n
  }
  if n == 0 {
    return m
  }
  // Two row DP
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
        let del_cost = prev[j] + 1
        let ins_cost = curr[j - 1] + 1
        let sub_cost = prev[j - 1] + 1
        let min12 = if del_cost < ins_cost { del_cost } else { ins_cost }
        curr[j] = if min12 < sub_cost { min12 } else { sub_cost }
      }
    }
    // Swap rows
    let tmp = prev
    prev = curr
    curr = tmp
  }
  prev[n]
}

///|
/// Normalized Levenshtein similarity in [0.0, 1.0].
/// Returns 1.0 for identical strings, 0.0 for completely different.
pub fn levenshtein_similarity(a : String, b : String) -> Double {
  let a_len = a.length()
  let b_len = b.length()
  if a_len == 0 && b_len == 0 {
    return 1.0
  }
  let dist = levenshtein_distance(a, b)
  let max_len = if a_len > b_len { a_len } else { b_len }
  1.0 - dist.to_double() / max_len.to_double()
}

///|
/// Compute the Damerau-Levenshtein distance (allows adjacent transpositions).
pub fn damerau_levenshtein_distance(a : String, b : String) -> Int {
  let a_chars = a.to_array()
  let b_chars = b.to_array()
  let m = a_chars.length()
  let n = b_chars.length()
  if m == 0 {
    return n
  }
  if n == 0 {
    return m
  }
  let dp = Array::make(m + 1, FixedArray::make(n + 1, 0))
  for i = 0; i <= m; i = i + 1 {
    dp[i] = FixedArray::make(n + 1, 0)
    dp[i][0] = i
  }
  for j = 0; j <= n; j = j + 1 {
    dp[0][j] = j
  }
  for i = 1; i <= m; i = i + 1 {
    for j = 1; j <= n; j = j + 1 {
      let cost = if a_chars[i - 1] == b_chars[j - 1] { 0 } else { 1 }
      let del_cost = dp[i - 1][j] + 1
      let ins_cost = dp[i][j - 1] + 1
      let sub_cost = dp[i - 1][j - 1] + cost
      let min12 = if del_cost < ins_cost { del_cost } else { ins_cost }
      let mut best = if min12 < sub_cost { min12 } else { sub_cost }
      // Transposition
      if i > 1 &&
        j > 1 &&
        a_chars[i - 1] == b_chars[j - 2] &&
        a_chars[i - 2] == b_chars[j - 1] {
        let trans = dp[i - 2][j - 2] + cost
        if trans < best {
          best = trans
        }
      }
      dp[i][j] = best
    }
  }
  dp[m][n]
}

///|
/// Normalized Damerau-Levenshtein similarity in [0.0, 1.0].
pub fn damerau_levenshtein_similarity(a : String, b : String) -> Double {
  let a_len = a.length()
  let b_len = b.length()
  if a_len == 0 && b_len == 0 {
    return 1.0
  }
  let dist = damerau_levenshtein_distance(a, b)
  let max_len = if a_len > b_len { a_len } else { b_len }
  1.0 - dist.to_double() / max_len.to_double()
}

///|
/// Compute the Hamming distance between two equal-length strings.
/// Returns -1 if strings have different lengths.
pub fn hamming_distance(a : String, b : String) -> Int {
  let a_chars = a.to_array()
  let b_chars = b.to_array()
  if a_chars.length() != b_chars.length() {
    return -1
  }
  let mut count = 0
  for i = 0; i < a_chars.length(); i = i + 1 {
    if a_chars[i] != b_chars[i] {
      count = count + 1
    }
  }
  count
}

///|
/// Normalized Hamming similarity in [0.0, 1.0].
/// Returns 0.0 if lengths differ.
pub fn hamming_similarity(a : String, b : String) -> Double {
  let dist = hamming_distance(a, b)
  if dist < 0 {
    return 0.0
  }
  if a.length() == 0 {
    return 1.0
  }
  1.0 - dist.to_double() / a.length().to_double()
}
