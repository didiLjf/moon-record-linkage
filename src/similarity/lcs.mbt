// Longest Common Subsequence (LCS) and Sequence Similarity

///|
/// Compute the length of the Longest Common Subsequence of two strings.
pub fn lcs_length(a : String, b : String) -> Int {
  let a_chars = a.to_array()
  let b_chars = b.to_array()
  let m = a_chars.length()
  let n = b_chars.length()
  if m == 0 || n == 0 {
    return 0
  }
  let mut prev = FixedArray::make(n + 1, 0)
  let mut curr = FixedArray::make(n + 1, 0)
  for i = 1; i <= m; i = i + 1 {
    for j = 1; j <= n; j = j + 1 {
      if a_chars[i - 1] == b_chars[j - 1] {
        curr[j] = prev[j - 1] + 1
      } else {
        curr[j] = if prev[j] > curr[j - 1] { prev[j] } else { curr[j - 1] }
      }
    }
    let tmp = prev
    prev = curr
    curr = tmp
  }
  prev[n]
}

///|
/// Normalized LCS similarity: LCS length / max length.
pub fn lcs_similarity(a : String, b : String) -> Double {
  let a_len = a.length()
  let b_len = b.length()
  if a_len == 0 && b_len == 0 {
    return 1.0
  }
  let lcs = lcs_length(a, b)
  let max_len = if a_len > b_len { a_len } else { b_len }
  lcs.to_double() / max_len.to_double()
}

///|
/// Compute Longest Common Substring length (contiguous).
pub fn longest_common_substring_length(a : String, b : String) -> Int {
  let a_chars = a.to_array()
  let b_chars = b.to_array()
  let m = a_chars.length()
  let n = b_chars.length()
  let mut max_len = 0
  let mut prev = FixedArray::make(n + 1, 0)
  let mut curr = FixedArray::make(n + 1, 0)
  for i = 1; i <= m; i = i + 1 {
    for j = 1; j <= n; j = j + 1 {
      if a_chars[i - 1] == b_chars[j - 1] {
        curr[j] = prev[j - 1] + 1
        if curr[j] > max_len {
          max_len = curr[j]
        }
      } else {
        curr[j] = 0
      }
    }
    let tmp = prev
    prev = curr
    curr = tmp
  }
  max_len
}

///|
/// Normalized longest common substring similarity.
pub fn longest_common_substring_similarity(a : String, b : String) -> Double {
  let a_len = a.length()
  let b_len = b.length()
  if a_len == 0 && b_len == 0 {
    return 1.0
  }
  let lcs = longest_common_substring_length(a, b)
  let max_len = if a_len > b_len { a_len } else { b_len }
  lcs.to_double() / max_len.to_double()
}
