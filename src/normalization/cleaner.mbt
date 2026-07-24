// Text Cleaning and Standardization Engine
// Implements whitespace normalization, case folding, punctuation stripping,
// and domain-specific cleaning passes.

///|
/// Normalize whitespace: collapse multiple spaces, trim leading/trailing.
pub fn normalize_whitespace(s : String) -> String {
  let chars = s.to_array()
  let sb = StringBuilder(size_hint=chars.length())
  let mut prev_space = true
  for ch in chars {
    if ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' {
      if !prev_space {
        sb.write_char(' ')
        prev_space = true
      }
    } else {
      sb.write_char(ch)
      prev_space = false
    }
  }
  let raw = sb.to_string()
  trim_ascii(raw)
}

///|
/// Trim leading and trailing ASCII space characters.
pub fn trim_ascii(s : String) -> String {
  let chars = s.to_array()
  let n = chars.length()
  let mut start = 0
  let mut end = n
  while start < n && chars[start] == ' ' {
    start = start + 1
  }
  while end > start && chars[end - 1] == ' ' {
    end = end - 1
  }
  if start == 0 && end == n {
    s
  } else {
    let sb = StringBuilder(size_hint=end - start)
    for i = start; i < end; i = i + 1 {
      sb.write_char(chars[i])
    }
    sb.to_string()
  }
}

///|
/// Convert ASCII uppercase letters to lowercase.
pub fn to_lowercase(s : String) -> String {
  let chars = s.to_array()
  let sb = StringBuilder(size_hint=chars.length())
  for ch in chars {
    if ch >= 'A' && ch <= 'Z' {
      let shifted = Char::from_int(ch.to_int() + 32)
      sb.write_char(shifted)
    } else {
      sb.write_char(ch)
    }
  }
  sb.to_string()
}

///|
/// Convert ASCII lowercase letters to uppercase.
pub fn to_uppercase(s : String) -> String {
  let chars = s.to_array()
  let sb = StringBuilder(size_hint=chars.length())
  for ch in chars {
    if ch >= 'a' && ch <= 'z' {
      let shifted = Char::from_int(ch.to_int() - 32)
      sb.write_char(shifted)
    } else {
      sb.write_char(ch)
    }
  }
  sb.to_string()
}

///|
/// Remove all non-alphanumeric characters (keep only [a-zA-Z0-9] and spaces).
pub fn strip_punctuation(s : String) -> String {
  let chars = s.to_array()
  let sb = StringBuilder(size_hint=chars.length())
  for ch in chars {
    if is_alnum(ch) || ch == ' ' {
      sb.write_char(ch)
    }
  }
  sb.to_string()
}

///|
/// Remove all non-letter characters (keep only ASCII letters and spaces).
pub fn strip_non_alpha(s : String) -> String {
  let chars = s.to_array()
  let sb = StringBuilder(size_hint=chars.length())
  for ch in chars {
    if is_alpha(ch) || ch == ' ' {
      sb.write_char(ch)
    }
  }
  sb.to_string()
}

///|
/// Remove all non-digit characters.
pub fn strip_non_digit(s : String) -> String {
  let chars = s.to_array()
  let sb = StringBuilder(size_hint=chars.length())
  for ch in chars {
    if is_digit(ch) {
      sb.write_char(ch)
    }
  }
  sb.to_string()
}

///|
/// Return true if ch is an ASCII letter.
pub fn is_alpha(ch : Char) -> Bool {
  (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z')
}

///|
/// Return true if ch is an ASCII digit.
pub fn is_digit(ch : Char) -> Bool {
  ch >= '0' && ch <= '9'
}

///|
/// Return true if ch is alphanumeric.
pub fn is_alnum(ch : Char) -> Bool {
  is_alpha(ch) || is_digit(ch)
}

///|
/// Full standard cleaning pipeline: lowercase → strip punctuation → normalize
/// whitespace.
pub fn clean_text(s : String) -> String {
  let step1 = to_lowercase(s)
  let step2 = strip_punctuation(step1)
  normalize_whitespace(step2)
}

///|
/// Apply a sequence of cleaner functions to a string.
pub fn apply_cleaners(
  s : String,
  cleaners : Array[(String) -> String],
) -> String {
  let mut result = s
  for cleaner in cleaners {
    result = cleaner(result)
  }
  result
}
