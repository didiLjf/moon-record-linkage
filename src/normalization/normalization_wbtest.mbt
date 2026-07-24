// Unit Tests for Normalization Module

///|
test "normalize whitespace" {
  assert_eq(normalize_whitespace("  hello   world  "), "hello world")
  assert_eq(normalize_whitespace("\thello\n\rworld"), "hello world")
  assert_eq(normalize_whitespace(""), "")
  assert_eq(normalize_whitespace("   "), "")
}

///|
test "to_lowercase and to_uppercase" {
  assert_eq(to_lowercase("Hello World"), "hello world")
  assert_eq(to_uppercase("hello world"), "HELLO WORLD")
  assert_eq(to_lowercase("ABC123"), "abc123")
}

///|
test "strip_punctuation" {
  assert_eq(strip_punctuation("hello, world!"), "hello world")
  assert_eq(strip_punctuation("foo@bar.com"), "foobarcom")
  assert_eq(strip_punctuation("test123"), "test123")
}

///|
test "clean_text full pipeline" {
  assert_eq(clean_text("  Hello, World!  "), "hello world")
  assert_eq(clean_text("O'Brien & Co."), "obrien co")
}

///|
test "word tokenize" {
  let tokens = word_tokenize("hello world foo")
  assert_eq(tokens.length(), 3)
  assert_eq(tokens[0], "hello")
  assert_eq(tokens[1], "world")
  assert_eq(tokens[2], "foo")
}

///|
test "word tokenize empty" {
  let tokens = word_tokenize("")
  assert_eq(tokens.length(), 0)
}

///|
test "char_ngrams bigrams" {
  let grams = char_ngrams("abcde", 2)
  assert_eq(grams.length(), 4)
  assert_eq(grams[0], "ab")
  assert_eq(grams[1], "bc")
  assert_eq(grams[3], "de")
}

///|
test "char_ngrams trigrams" {
  let grams = char_ngrams("hello", 3)
  assert_eq(grams.length(), 3)
  assert_eq(grams[0], "hel")
}

///|
test "char_ngrams too short" {
  let grams = char_ngrams("ab", 5)
  assert_eq(grams.length(), 0)
}

///|
test "filter stop words" {
  let tokens = ["the", "quick", "brown", "fox", "is", "fast"]
  let filtered = filter_stop_words(tokens)
  assert_true(!filtered.contains("the"))
  assert_true(!filtered.contains("is"))
  assert_true(filtered.contains("quick"))
  assert_true(filtered.contains("fast"))
}

///|
test "token frequency" {
  let tokens = ["a", "b", "a", "c", "a", "b"]
  let freq = token_frequency(tokens)
  assert_eq(freq.get("a"), Some(3))
  assert_eq(freq.get("b"), Some(2))
  assert_eq(freq.get("c"), Some(1))
}

///|
test "normalize phone" {
  assert_eq(normalize_phone("+86 138-1234-5678"), "+8613812345678")
  assert_eq(normalize_phone("(021) 1234-5678"), "02112345678")
}

///|
test "normalize email" {
  assert_eq(normalize_email("  User@Example.COM  "), "user@example.com")
  assert_eq(normalize_email("TEST@test.org"), "test@test.org")
}

///|
test "normalize_id_card" {
  assert_eq(normalize_id_card("110101199001011234"), "110101199001011234")
  assert_eq(normalize_id_card("11010119900101123x"), "11010119900101123X")
}

///|
test "normalize_company_name" {
  let name = normalize_company_name("北京天工信息技术有限公司")
  // Should remove 有限公司 suffix
  assert_true(name.length() < "北京天工信息技术有限公司".length())
}

///|
test "normalize_person_name" {
  let name = normalize_person_name("张三先生")
  assert_eq(name, "张三")
}
