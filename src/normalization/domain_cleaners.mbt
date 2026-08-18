// Domain-specific cleaners for Chinese names, company names, addresses, phones, IDs

///|
/// Common Chinese corporate suffixes to remove during company name normalization.
let company_suffixes : Array[String] = [
  "有限公司", "股份有限公司", "有限责任公司", "集团", "集团公司",
  "科技有限公司", "信息技术有限公司", "实业有限公司", "贸易有限公司",
  "发展有限公司", "投资有限公司", "控股有限公司", "企业管理有限公司",
  "咨询有限公司",
]

///|
/// Common address tokens to remove for cleaner address comparison.
let address_noise_tokens : Array[String] = [
  "省", "市", "区", "县", "镇", "乡", "街道", "路", "号", "楼", "室",
  "单元", "栋", "幢", "巷", "弄", "里", "园", "村",
]

///|
/// Normalize a Chinese company name: remove trailing corporate suffix variants,
/// collapse spaces.
pub fn normalize_company_name(name : String) -> String {
  let mut result = name
  // Remove parenthetical content like (北京)
  result = remove_parenthetical(result)
  // Strip known suffixes
  for suffix in company_suffixes {
    if result.has_suffix(suffix) {
      let new_len = result.length() - suffix.length()
      result = string_slice(result, 0, new_len)
      break
    }
  }
  normalize_whitespace_simple(result)
}

///|
/// Normalize a Chinese personal name: strip titles, honorifics, middle dots.
pub fn normalize_person_name(name : String) -> String {
  let mut result = name
  // Remove common honorifics
  for
    prefix in [
      "先生", "女士", "小姐", "博士", "教授", "总", "主任",
    ] {
    if result.has_suffix(prefix) {
      let new_len = result.length() - prefix.length()
      result = string_slice(result, 0, new_len)
    }
  }
  // Remove middle dots (·) used in transliterations
  result = remove_char(result, '·')
  result = remove_char(result, '•')
  normalize_whitespace_simple(result)
}

///|
/// Normalize a phone number: keep only digits and leading '+'.
pub fn normalize_phone(phone : String) -> String {
  let chars = phone.to_array()
  let sb = StringBuilder(size_hint=chars.length())
  let mut first = true
  for ch in chars {
    if ch == '+' && first {
      sb.write_char('+')
      first = false
    } else if ch >= '0' && ch <= '9' {
      sb.write_char(ch)
      first = false
    }
  }
  sb.to_string()
}

///|
/// Normalize a Chinese address: remove noise tokens, collapse whitespace.
pub fn normalize_address(addr : String) -> String {
  let mut result = addr
  for token in address_noise_tokens {
    result = replace_all(result, token, " ")
  }
  normalize_whitespace_simple(result)
}

///|
/// Normalize a Chinese ID card number: uppercase, strip spaces and dashes.
pub fn normalize_id_card(id : String) -> String {
  let chars = id.to_array()
  let sb = StringBuilder(size_hint=chars.length())
  for ch in chars {
    if (ch >= '0' && ch <= '9') || ch == 'X' || ch == 'x' {
      if ch == 'x' {
        sb.write_char('X')
      } else {
        sb.write_char(ch)
      }
    }
  }
  sb.to_string()
}

///|
/// Normalize an email address: lowercase and trim.
pub fn normalize_email(email : String) -> String {
  let chars = email.to_array()
  let sb = StringBuilder(size_hint=chars.length())
  let mut started = false
  let mut ended = false
  for ch in chars {
    if ch == ' ' || ch == '\t' {
      if started && !ended {
        ended = true
      }
    } else {
      started = true
      ended = false
      if ch >= 'A' && ch <= 'Z' {
        sb.write_char((ch.to_int() + 32).unsafe_to_char())
      } else {
        sb.write_char(ch)
      }
    }
  }
  sb.to_string()
}

// ---- Internal helpers ----

///|
fn normalize_whitespace_simple(s : String) -> String {
  let chars = s.to_array()
  let sb = StringBuilder(size_hint=chars.length())
  let mut prev_space = true
  for ch in chars {
    if ch == ' ' || ch == '\t' {
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
  trim_right_space(trim_left_space(raw))
}

///|
fn trim_left_space(s : String) -> String {
  let chars = s.to_array()
  let mut i = 0
  while i < chars.length() && chars[i] == ' ' {
    i = i + 1
  }
  if i == 0 {
    s
  } else {
    let sb = StringBuilder(size_hint=chars.length() - i)
    for j = i; j < chars.length(); j = j + 1 {
      sb.write_char(chars[j])
    }
    sb.to_string()
  }
}

///|
fn trim_right_space(s : String) -> String {
  let chars = s.to_array()
  let mut i = chars.length()
  while i > 0 && chars[i - 1] == ' ' {
    i = i - 1
  }
  if i == chars.length() {
    s
  } else {
    let sb = StringBuilder(size_hint=i)
    for j = 0; j < i; j = j + 1 {
      sb.write_char(chars[j])
    }
    sb.to_string()
  }
}

///|
fn string_slice(s : String, start : Int, end_idx : Int) -> String {
  let chars = s.to_array()
  let sb = StringBuilder(size_hint=end_idx - start)
  for i = start; i < end_idx && i < chars.length(); i = i + 1 {
    sb.write_char(chars[i])
  }
  sb.to_string()
}

///|
fn remove_char(s : String, target : Char) -> String {
  let chars = s.to_array()
  let sb = StringBuilder(size_hint=chars.length())
  for ch in chars {
    if ch != target {
      sb.write_char(ch)
    }
  }
  sb.to_string()
}

///|
fn remove_parenthetical(s : String) -> String {
  let chars = s.to_array()
  let sb = StringBuilder(size_hint=chars.length())
  let mut depth = 0
  for ch in chars {
    match ch {
      '(' | '（' => depth = depth + 1
      ')' | '）' => if depth > 0 { depth = depth - 1 }
      _ => if depth == 0 { sb.write_char(ch) }
    }
  }
  sb.to_string()
}

///|
fn replace_all(s : String, pattern : String, replacement : String) -> String {
  if pattern.is_empty() {
    return s
  }
  let pat_chars = pattern.to_array()
  let src_chars = s.to_array()
  let pat_len = pat_chars.length()
  let src_len = src_chars.length()
  let sb = StringBuilder(size_hint=src_len)
  let mut i = 0
  while i < src_len {
    // Check if pattern starts at position i
    let mut matched = pat_len <= src_len - i
    if matched {
      for k = 0; k < pat_len; k = k + 1 {
        if src_chars[i + k] != pat_chars[k] {
          matched = false
          break
        }
      }
    }
    if matched {
      sb.write_string(replacement)
      i = i + pat_len
    } else {
      sb.write_char(src_chars[i])
      i = i + 1
    }
  }
  sb.to_string()
}
