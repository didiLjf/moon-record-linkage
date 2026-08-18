// Soundex Phonetic Encoding Algorithm
// Developed by Robert Russell and Margaret Odell.
// Maps English words to a 4-character code: letter + 3 digits.

///|
/// Soundex digit table for letters a-z (0-indexed from 'a').
let soundex_table : Array[Int] = [
  0, // a
   1, // b
   2, // c
   3, // d
   0, // e
   1, // f
   2, // g
   0, // h
   0, // i
   2, // j
   2, // k
   4, // l
   5, // m
   5, // n
   0, // o
   1, // p
   2, // q
   6, // r
   2, // s
   3, // t
   0, // u
   1, // v
   0, // w
   2, // x
   0, // y
   2, // z
]

///|
/// Return the Soundex digit for an ASCII letter (a-z, case-insensitive).
/// Returns 0 for vowels and H/W, -1 for non-letters.
fn soundex_digit(ch : Char) -> Int {
  let lower = if ch >= 'A' && ch <= 'Z' {
    (ch.to_int() + 32).unsafe_to_char()
  } else {
    ch
  }
  if lower >= 'a' && lower <= 'z' {
    soundex_table[lower.to_int() - 97]
  } else {
    -1
  }
}

///|
/// Compute the Soundex code for an English string.
/// Returns a 4-character code (e.g., "R163" for "Robert").
pub fn soundex(s : String) -> String {
  if s.is_empty() {
    return "0000"
  }
  let chars = s.to_array()
  // Find first letter
  let mut first_letter = ' '
  let mut first_idx = 0
  for i = 0; i < chars.length(); i = i + 1 {
    let ch = chars[i]
    if (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') {
      first_letter = if ch >= 'a' {
        ch
      } else {
        (ch.to_int() + 32).unsafe_to_char()
      }
      first_idx = i
      break
    }
  }
  if first_letter == ' ' {
    return "0000"
  }
  let upper_first = if first_letter >= 'a' && first_letter <= 'z' {
    (first_letter.to_int() - 32).unsafe_to_char()
  } else {
    first_letter
  }
  let sb = StringBuilder(size_hint=4)
  sb.write_char(upper_first)
  let mut prev_digit = soundex_digit(chars[first_idx])
  for i = first_idx + 1
      i < chars.length() && sb.to_string().length() < 4
      i = i + 1 {
    let ch = chars[i]
    let digit = soundex_digit(ch)
    if digit == -1 {
      continue
    }
    // H and W are ignored but don't separate codes
    if ch == 'h' || ch == 'H' || ch == 'w' || ch == 'W' {
      continue
    }
    if digit != 0 && digit != prev_digit {
      sb.write_char((48 + digit).unsafe_to_char())
    }
    if digit != 0 {
      prev_digit = digit
    } else {
      // vowels reset the previous digit tracking
      prev_digit = 0
    }
  }
  // Pad with zeros to length 4
  let current = sb.to_string()
  let pad_count = 4 - current.length()
  let result = StringBuilder(size_hint=4)
  result.write_string(current)
  for _ in 0..<pad_count {
    result.write_char('0')
  }
  result.to_string()
}

///|
/// Return true if two strings have the same Soundex code (phonetically similar).
pub fn soundex_match(a : String, b : String) -> Bool {
  soundex(a) == soundex(b)
}
