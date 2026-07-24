// Metaphone Phonetic Encoding
// Approximates the English pronunciation of a word into a canonical code.
// Implements a simplified Metaphone algorithm suitable for matching.

///|
/// Check if character is a vowel (a, e, i, o, u).
fn is_vowel_ch(ch : Char) -> Bool {
  ch == 'a' || ch == 'e' || ch == 'i' || ch == 'o' || ch == 'u'
}

///|
/// Normalize input: lowercase, strip non-alpha.
fn prepare_for_metaphone(s : String) -> Array[Char] {
  let chars = s.to_array()
  let result : Array[Char] = []
  for ch in chars {
    if ch >= 'A' && ch <= 'Z' {
      result.push(Char::from_int(ch.to_int() + 32))
    } else if ch >= 'a' && ch <= 'z' {
      result.push(ch)
    }
  }
  result
}

///|
/// Safely get char at index, or '\x00' if out of bounds.
fn get_ch(chars : Array[Char], idx : Int) -> Char {
  if idx >= 0 && idx < chars.length() {
    chars[idx]
  } else {
    '\x00'
  }
}

///|
/// Compute a simplified Metaphone code for an English word.
/// Returns a string representing the approximate pronunciation.
pub fn metaphone(s : String) -> String {
  let chars = prepare_for_metaphone(s)
  let n = chars.length()
  if n == 0 {
    return ""
  }
  let sb = StringBuilder(size_hint=16)
  let mut i = 0
  // Drop initial silent letters
  let first2 = if n >= 2 {
    chars[0].to_string() + chars[1].to_string()
  } else {
    chars[0].to_string()
  }
  if first2 == "ae" ||
    first2 == "gn" ||
    first2 == "kn" ||
    first2 == "pn" ||
    first2 == "wr" {
    i = 1
  }
  while i < n {
    let ch = chars[i]
    let prev = get_ch(chars, i - 1)
    let next = get_ch(chars, i + 1)
    let next2 = get_ch(chars, i + 2)
    // Skip duplicate adjacent letters
    if ch != 'c' && ch == prev {
      i = i + 1
      continue
    }
    match ch {
      'a' | 'e' | 'i' | 'o' | 'u' => if i == 0 { sb.write_char(ch) }
      'b' => if !(prev == 'm' && i == n - 1) { sb.write_char('b') }
      'c' =>
        if next == 'i' || next == 'e' || next == 'y' {
          sb.write_char('s')
          if next == 'i' && next2 == 'a' {
            sb.write_char('x')
            i = i + 2
          }
        } else if next == 'h' {
          sb.write_char('x')
          i = i + 1
        } else {
          sb.write_char('k')
        }
      'd' =>
        if next == 'g' && (next2 == 'e' || next2 == 'y' || next2 == 'i') {
          sb.write_char('j')
          i = i + 1
        } else {
          sb.write_char('t')
        }
      'f' => sb.write_char('f')
      'g' => {
        let gg_skip = next == 'h' && !is_vowel_ch(next2)
        if !gg_skip && next != 'n' {
          if next == 'e' || next == 'i' || next == 'y' {
            sb.write_char('j')
          } else {
            sb.write_char('k')
          }
        }
      }
      'h' => if is_vowel_ch(next) && !is_vowel_ch(prev) { sb.write_char('h') }
      'j' => sb.write_char('j')
      'k' => if prev != 'c' { sb.write_char('k') }
      'l' => sb.write_char('l')
      'm' => sb.write_char('m')
      'n' => sb.write_char('n')
      'p' =>
        if next == 'h' {
          sb.write_char('f')
          i = i + 1
        } else {
          sb.write_char('p')
        }
      'q' => sb.write_char('k')
      'r' => sb.write_char('r')
      's' =>
        if next == 'h' || (next == 'i' && (next2 == 'a' || next2 == 'o')) {
          sb.write_char('x')
        } else if next == 'c' && next2 == 'h' {
          sb.write_char('s')
          sb.write_char('k')
          i = i + 2
        } else {
          sb.write_char('s')
        }
      't' =>
        if next == 'h' {
          sb.write_char('0')
          i = i + 1
        } else if next == 'i' && (next2 == 'a' || next2 == 'o') {
          sb.write_char('x')
        } else if next != 'c' || next2 != 'h' {
          sb.write_char('t')
        }
      'v' => sb.write_char('f')
      'w' => if is_vowel_ch(next) { sb.write_char('w') }
      'x' => {
        sb.write_char('k')
        sb.write_char('s')
      }
      'y' => if is_vowel_ch(next) { sb.write_char('y') }
      'z' => sb.write_char('s')
      _ => ()
    }
    i = i + 1
  }
  sb.to_string()
}

///|
/// Return true if two strings share the same Metaphone code.
pub fn metaphone_match(a : String, b : String) -> Bool {
  metaphone(a) == metaphone(b)
}
