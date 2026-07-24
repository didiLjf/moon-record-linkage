// Match Rating Approach (MRA) Phonetic Encoding
// A phonetic algorithm developed by Western Airlines in 1977.
// Works better than Soundex for short names.

///|
fn mra_upper_alpha(s : String) -> Array[Char] {
  let chars = s.to_array()
  let result : Array[Char] = []
  for ch in chars {
    if ch >= 'a' && ch <= 'z' {
      result.push(Char::from_int(ch.to_int() - 32))
    } else if ch >= 'A' && ch <= 'Z' {
      result.push(ch)
    }
  }
  result
}

///|
fn is_mra_vowel(ch : Char) -> Bool {
  ch == 'A' || ch == 'E' || ch == 'I' || ch == 'O' || ch == 'U'
}

///|
/// Compute the MRA phonetic code for a name.
pub fn mra_encode(s : String) -> String {
  let chars = mra_upper_alpha(s)
  if chars.is_empty() {
    return ""
  }
  // Step 1: Save first letter
  let first = chars[0]
  // Step 2: Remove all vowels after the first character
  let step2 : Array[Char] = [first]
  for i = 1; i < chars.length(); i = i + 1 {
    if !is_mra_vowel(chars[i]) {
      step2.push(chars[i])
    }
  }
  // Step 3: Remove duplicate adjacent letters
  let step3 : Array[Char] = []
  for ch in step2 {
    if step3.is_empty() || step3[step3.length() - 1] != ch {
      step3.push(ch)
    }
  }
  // Step 4: If length > 6, keep first 3 and last 3
  let code = if step3.length() > 6 {
    let n = step3.length()
    let sb = StringBuilder(size_hint=6)
    sb.write_char(step3[0])
    sb.write_char(step3[1])
    sb.write_char(step3[2])
    sb.write_char(step3[n - 3])
    sb.write_char(step3[n - 2])
    sb.write_char(step3[n - 1])
    sb.to_string()
  } else {
    let sb = StringBuilder(size_hint=step3.length())
    for c in step3 {
      sb.write_char(c)
    }
    sb.to_string()
  }
  code
}

///|
/// MRA minimum rating threshold based on name lengths.
fn mra_minimum_rating(len_a : Int, len_b : Int) -> Int {
  let sum = len_a + len_b
  if sum <= 4 {
    5
  } else if sum <= 7 {
    4
  } else if sum <= 11 {
    3
  } else {
    2
  }
}

///|
/// Compare two names using the MRA rating scheme.
/// Returns a similarity score between 0.0 and 1.0.
pub fn mra_similarity(a : String, b : String) -> Double {
  let code_a = mra_encode(a)
  let code_b = mra_encode(b)
  let la = code_a.length()
  let lb = code_b.length()
  if la == 0 || lb == 0 {
    return 0.0
  }
  // Check minimum rating threshold
  let min_rating = mra_minimum_rating(la, lb)
  // Count unmatched characters
  let arr_a = code_a.to_array()
  let arr_b = code_b.to_array()
  // Left-to-right scan
  let matched_a = FixedArray::make(la, false)
  let matched_b = FixedArray::make(lb, false)
  for i = 0; i < la; i = i + 1 {
    for j = 0; j < lb; j = j + 1 {
      if !matched_a[i] && !matched_b[j] && arr_a[i] == arr_b[j] {
        matched_a[i] = true
        matched_b[j] = true
        break
      }
    }
  }
  let mut match_count = 0
  for i = 0; i < la; i = i + 1 {
    if matched_a[i] {
      match_count = match_count + 1
    }
  }
  let unmatched_a = la - match_count
  let unmatched_b = lb - match_count
  let total_unmatched = unmatched_a + unmatched_b
  let rating = 6 - total_unmatched
  if rating >= min_rating {
    rating.to_double() / 6.0
  } else {
    0.0
  }
}

///|
/// Return true if two names are phonetically similar by MRA.
pub fn mra_match(a : String, b : String) -> Bool {
  mra_similarity(a, b) > 0.0
}
