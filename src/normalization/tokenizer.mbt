// Text Tokenization: N-gram, Q-gram, word tokenizer, stop-word filtering

///|
/// Split string on whitespace boundaries into tokens.
pub fn word_tokenize(s : String) -> Array[String] {
  let chars = s.to_array()
  let tokens : Array[String] = []
  let sb = StringBuilder(size_hint=32)
  for ch in chars {
    if ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' {
      if !sb.is_empty() {
        tokens.push(sb.to_string())
        sb.reset()
      }
    } else {
      sb.write_char(ch)
    }
  }
  if !sb.is_empty() {
    tokens.push(sb.to_string())
  }
  tokens
}

///|
/// Generate character n-grams of size n from a string.
/// Returns an array of n-gram strings.
pub fn char_ngrams(s : String, n : Int) -> Array[String] {
  let chars = s.to_array()
  let len = chars.length()
  let result : Array[String] = []
  if n <= 0 || len < n {
    return result
  }
  for i = 0; i <= len - n; i = i + 1 {
    let sb = StringBuilder(size_hint=n)
    for j = i; j < i + n; j = j + 1 {
      sb.write_char(chars[j])
    }
    result.push(sb.to_string())
  }
  result
}

///|
/// Generate a set (as sorted array, no duplicates) of n-grams.
pub fn char_ngram_set(s : String, n : Int) -> Array[String] {
  let grams = char_ngrams(s, n)
  let map : Map[String, Bool] = Map([])
  for g in grams {
    map.set(g, true)
  }
  let result : Array[String] = []
  for entry in map {
    result.push(entry.0)
  }
  result
}

///|
/// Generate word-level bigrams (adjacent word pairs).
pub fn word_bigrams(s : String) -> Array[String] {
  let tokens = word_tokenize(s)
  let result : Array[String] = []
  for i = 0; i < tokens.length() - 1; i = i + 1 {
    result.push(tokens[i] + " " + tokens[i + 1])
  }
  result
}

///|
/// English stop words set.
let stop_words_en : Array[String] = [
  "a", "an", "the", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with",
  "by", "from", "is", "are", "was", "were", "be", "been", "being", "have", "has",
  "had", "do", "does", "did", "will", "would", "could", "should", "may", "might",
  "can", "shall", "that", "this", "these", "those", "it", "its",
]

///|
/// Filter stop words from a token list using a provided stop word set.
pub fn filter_stop_words(
  tokens : Array[String],
  stop_words? : Array[String] = stop_words_en,
) -> Array[String] {
  let stop_map : Map[String, Bool] = Map([])
  for sw in stop_words {
    stop_map.set(sw, true)
  }
  let result : Array[String] = []
  for t in tokens {
    if !stop_map.contains(t) {
      result.push(t)
    }
  }
  result
}

///|
/// Tokenize, remove stop words, and return sorted unique tokens.
pub fn tokenize_and_filter(s : String) -> Array[String] {
  let tokens = word_tokenize(s)
  let filtered = filter_stop_words(tokens)
  filtered.sort()
  filtered
}

///|
/// Build a token frequency map from an array of tokens.
pub fn token_frequency(tokens : Array[String]) -> Map[String, Int] {
  let freq : Map[String, Int] = Map([])
  for t in tokens {
    match freq.get(t) {
      Some(cnt) => freq.set(t, cnt + 1)
      None => freq.set(t, 1)
    }
  }
  freq
}
