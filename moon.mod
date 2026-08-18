// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "didiLjf/moon-record-linkage"

version = "0.1.3"

readme = "README.mbt.md"

repository = "https://github.com/didiLjf/moon-record-linkage"

license = "Apache-2.0"

keywords = [
  "record-linkage",
  "entity-resolution",
  "deduplication",
  "blocking",
  "entity-matching",
]

preferred_target = "wasm-gc"

description = "A native MoonBit engine for record linkage, entity matching, deduplication, explainable scoring, and reproducible evaluation."
