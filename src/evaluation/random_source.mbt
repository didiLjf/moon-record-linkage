///|
/// Small deterministic pseudo-random source for reproducible fixtures and benchmarks.
pub struct DeterministicRandom {
  mut state : Int
} derive(Debug, Eq)

///|
pub fn DeterministicRandom::new(seed : Int) -> DeterministicRandom {
  let normalized = if seed <= 0 { 1 } else { seed % 2147483647 }
  { state: normalized }
}

///|
pub fn DeterministicRandom::next(self : DeterministicRandom) -> Int {
  self.state = self.state * 48271 % 2147483647
  if self.state <= 0 {
    self.state = 1
  }
  self.state
}

///|
pub fn DeterministicRandom::next_bounded(
  self : DeterministicRandom,
  bound~ : Int,
) -> Int {
  if bound <= 1 {
    0
  } else {
    self.next() % bound
  }
}

///|
pub fn DeterministicRandom::next_unit(self : DeterministicRandom) -> Double {
  self.next().to_double() / 2147483647.0
}
