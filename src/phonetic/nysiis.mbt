// NYSIIS (New York State Identification and Intelligence System) Phonetic Encoding
// A phonetic algorithm for English names, often more accurate than Soundex.

///|
fn nysiis_upper(s : String) -> Array[Char] {
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
fn nysiis_get(chars : Array[Char], i : Int) -> Char {
  if i >= 0 && i < chars.length() {
    chars[i]
  } else {
    '\x00'
  }
}

///|
fn nysiis_starts_with2(
  chars : Array[Char],
  i : Int,
  a : Char,
  b : Char,
) -> Bool {
  nysiis_get(chars, i) == a && nysiis_get(chars, i + 1) == b
}

///|
/// Compute the NYSIIS code for an English name string.
pub fn nysiis(s : String) -> String {
  let chars = nysiis_upper(s)
  let n = chars.length()
  if n == 0 {
    return ""
  }
  // Replace leading prefixes
  let working : Array[Char] = []
  let mut i = 0
  // MAC -> MCC, KN -> NN, K -> C, PH -> FF, PF -> FF, SCH -> SSS
  if nysiis_starts_with2(chars, 0, 'M', 'A') && nysiis_get(chars, 2) == 'C' {
    working.push('M')
    working.push('C')
    working.push('C')
    i = 3
  } else if nysiis_starts_with2(chars, 0, 'K', 'N') {
    working.push('N')
    working.push('N')
    i = 2
  } else if chars[0] == 'K' {
    working.push('C')
    i = 1
  } else if nysiis_starts_with2(chars, 0, 'P', 'H') ||
    nysiis_starts_with2(chars, 0, 'P', 'F') {
    working.push('F')
    working.push('F')
    i = 2
  } else if nysiis_starts_with2(chars, 0, 'S', 'C') &&
    nysiis_get(chars, 2) == 'H' {
    working.push('S')
    working.push('S')
    working.push('S')
    i = 3
  }
  // Copy remaining initial chars
  while i < n {
    working.push(chars[i])
    i = i + 1
  }
  // Translate last characters
  let wn = working.length()
  // EV -> AF at end, else remove trailing vowels
  if wn >= 2 && working[wn - 2] == 'E' && working[wn - 1] == 'V' {
    working[wn - 2] = 'A'
    working[wn - 1] = 'F'
  }
  // Remove trailing S, AY, A
  let mut end = working.length()
  if end > 0 && working[end - 1] == 'S' {
    end = end - 1
  }
  if end >= 2 && working[end - 2] == 'A' && working[end - 1] == 'Y' {
    end = end - 2
  }
  if end > 0 && working[end - 1] == 'A' {
    end = end - 1
  }
  // Now build code from working[0..end]
  let code : Array[Char] = []
  if end > 0 {
    code.push(working[0])
  }
  let mut j = 1
  while j < end {
    let ch = working[j]
    let prev_code = if code.is_empty() {
      '\x00'
    } else {
      code[code.length() - 1]
    }
    let next_c = nysiis_get(working, j + 1)
    let mapped : Array[Char] = []
    match ch {
      'E' | 'I' | 'O' | 'U' => mapped.push('A')
      'Q' => mapped.push('G')
      'Z' => mapped.push('S')
      'M' => mapped.push('N')
      'K' =>
        if next_c == 'N' {
          mapped.push('N')
          j = j + 1
        } else {
          mapped.push('C')
        }
      'S' | 'C' =>
        if next_c == 'H' {
          mapped.push('S')
          mapped.push('S')
          j = j + 1
        } else {
          mapped.push(ch)
        }
      'P' =>
        if next_c == 'H' {
          mapped.push('F')
          j = j + 1
        } else {
          mapped.push(ch)
        }
      'H' =>
        if !is_nysiis_vowel(nysiis_get(working, j - 1)) ||
          !is_nysiis_vowel(next_c) {
          mapped.push('H')
        } else {
          // Absorb vowel before H
          mapped.push(prev_code)
        }
      'W' => if is_nysiis_vowel(nysiis_get(working, j - 1)) { mapped.push('W') }
      _ => mapped.push(ch)
    }
    for mc in mapped {
      if mc != prev_code {
        code.push(mc)
      }
    }
    j = j + 1
  }
  let sb = StringBuilder(size_hint=code.length())
  for c in code {
    sb.write_char(c)
  }
  sb.to_string()
}

///|
fn is_nysiis_vowel(ch : Char) -> Bool {
  ch == 'A' || ch == 'E' || ch == 'I' || ch == 'O' || ch == 'U'
}

///|
/// Return true if two names have the same NYSIIS code.
pub fn nysiis_match(a : String, b : String) -> Bool {
  nysiis(a) == nysiis(b)
}
