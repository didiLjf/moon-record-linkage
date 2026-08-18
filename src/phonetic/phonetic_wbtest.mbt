// Phonetic Module Tests

///|
test "soundex basic" {
  assert_eq(soundex("Robert"), "R163")
  assert_eq(soundex("Rupert"), "R163")
  assert_eq(soundex("Rubin"), "R150")
  assert_eq(soundex(""), "0000")
}

///|
test "soundex match" {
  assert_true(soundex_match("Smith", "Smythe"))
  assert_true(soundex_match("Robert", "Rupert"))
  assert_true(!soundex_match("Robert", "Rubin"))
}

///|
test "metaphone basic" {
  let code = metaphone("Smith")
  assert_true(code.length() > 0)
  // Smith and Smyth should produce same code
  assert_eq(metaphone("Smith"), metaphone("Smyth"))
}

///|
test "metaphone silent letters" {
  // KN- is silent
  let code = metaphone("Knight")
  assert_true(!code.has_prefix("K"))
}

///|
test "nysiis basic" {
  let code = nysiis("Thompson")
  assert_true(code.length() > 0)
}

///|
test "nysiis match" {
  // Similar-sounding names
  assert_true(nysiis("Brown").length() > 0)
  assert_true(nysiis("Braun").length() > 0)
}

///|
test "mra encode" {
  let code = mra_encode("Smith")
  assert_true(code.length() > 0)
  assert_true(code.length() <= 6)
}

///|
test "mra encode deduplication" {
  // No duplicate adjacent chars
  let code = mra_encode("Bobbington")
  let chars = code.to_array()
  for i = 1; i < chars.length(); i = i + 1 {
    assert_true(chars[i] != chars[i - 1])
  }
}

///|
test "mra similarity same name" {
  let sim = mra_similarity("Smith", "Smith")
  assert_true(sim > 0.0)
}

///|
test "mra similarity empty" {
  let sim = mra_similarity("", "Smith")
  assert_eq(sim, 0.0)
}
