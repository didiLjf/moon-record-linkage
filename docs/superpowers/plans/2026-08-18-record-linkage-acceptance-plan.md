# Moon-Record-Linkage 结项增强实施计划

> 目标：在不修改 `OSC2026_8月黑客松申报书.md` 的前提下，把现有实体匹配引擎扩展为可运行、可解释、可评估的生产级 MoonBit 库，并以真实命令输出证明验收条件。

## 现状和实施边界

- 根模块：`didiLjf/moon-record-linkage`；公开模块名保持不变，供 Mooncakes 发布。
- 现有包：`core`、`normalization`、`phonetic`、`similarity`、`blocking`、`model`、`graph`、`pipeline`、`export`、`main`。
- 当前基线：`moon test` 为 97/97 通过，但有弃用 API、未使用包和未使用构造器警告；严格检查暂不能作为完成证据。
- 当前 `.mbt` 非空行约 5,185，其中测试文件约 97 个测试声明；新增规模必须是可执行实现，目标为 `src/` 有效实现代码至少 8,000 行，最终使用脚本按文件输出明细。
- 不引入网络、文件系统、数据库或 C/JS 依赖；所有新增能力在 `wasm-gc`、`wasm`、`js`、`native` 可检查范围内保持纯 MoonBit。

## 公共接口约定

新增类型统一使用公开字段不可变的 struct + 构造器/方法风格，内部可变集合通过现有 MoonBit `Array` / `Map` 管理。返回失败使用 `Result[T, @core.RecordLinkageError]` 或结构化报告，不用空字符串表示错误。

核心新增接口草案（实现时以当前 `moon ide doc` 和编译器诊断为准）：

```moonbit
pub struct ValidationIssue {
  code : String
  field : String
  message : String
  severity : IssueSeverity
}

pub struct DatasetProfile {
  record_count : Int
  distinct_id_count : Int
  duplicate_id_count : Int
  field_profiles : Array[FieldProfile]
}

pub fn profile_dataset(records : Array[@core.Record]) -> DatasetProfile
pub fn validate_record(schema : @core.Schema, record : @core.Record) -> Array[ValidationIssue]
pub fn validate_config(config : @core.LinkageConfig) -> Result[Unit, @core.RecordLinkageError]

pub struct CandidatePlan {
  pairs : Array[CandidatePair]
  strategy_counts : Map[String, Int]
  raw_pair_count : Int
  deduplicated_pair_count : Int
}

pub fn plan_candidates(
  records_a : Array[@core.Record],
  records_b : Array[@core.Record],
  strategies : Array[@core.BlockingStrategy],
  options~ : PlannerOptions,
) -> CandidatePlan

pub struct ScoreExplanation {
  pair_id : String
  field_contributions : Array[FieldContribution]
  missing_fields : Array[String]
  composite_score : Double
  status : @core.MatchStatus
}

pub fn explain_pair(
  config : @core.LinkageConfig,
  record_a : @core.Record,
  record_b : @core.Record,
) -> ScoreExplanation

pub struct CalibrationReport {
  thresholds : Array[ThresholdPoint]
  best_f1_threshold : Double
  confusion_at_best : ConfusionMatrix
}

pub fn calibrate_thresholds(
  scores : Array[LabeledScore],
  step~ : Double,
) -> Result[CalibrationReport, @core.RecordLinkageError]
```

`ConfusionMatrix` is owned by the model calibration package in this plan and is referenced locally by `CalibrationReport`.

The exact public fields will be confirmed by `moon info`; fields that should not be constructed by consumers remain private, with read methods where required.

## Task 1 — Establish a clean strict-check baseline

Files:

- Modify existing warning sites in `src/blocking/standard_blocking.mbt`, `src/core/core_wbtest.mbt`, `src/graph/graph_wbtest.mbt`, `src/normalization/cleaner.mbt`, `src/normalization/domain_cleaners.mbt`, `src/phonetic/*.mbt`, `src/similarity/token_similarity.mbt`.
- Remove the unused dependency in `src/normalization/moon.pkg` only if `moon ide` confirms it is unused.
- Add `scripts/count_moonbit_lines.ps1` for reproducible production/test line counts; it must exclude generated `.mbti`, `_build`, `target`, `.mooncakes` and count non-empty `.mbt` lines with a production/test split.

Verification:

```text
moon fmt --check
moon check --deny-warn
moon test --deny-warn
powershell -NoProfile -File scripts/count_moonbit_lines.ps1
```

Expected result: no warning output from strict check/test, existing tests remain 97/97, and the line-count script prints a deterministic table. If a deprecated API replacement changes behavior, add or update the nearest existing test before applying the replacement.

## Task 2 — Add core validation, profiles, diagnostics, and statistics

Files:

- Add `src/core/quality_types.mbt`: `IssueSeverity`, `ValidationIssue`, `FieldProfile`, `DatasetProfile`, `ProfileSummary`, `DataQualityStatus` and deterministic constructors/accessors.
- Add `src/core/quality_validation.mbt`: record/schema validation for required fields, field type compatibility, empty values, numeric finite/range checks, geo latitude/longitude checks, ID checks, and duplicate ID reports.
- Add `src/core/quality_profile.mbt`: field presence counts, null rates, distinct counts, duplicate rates, source counts and timestamp ranges.
- Add `src/core/diagnostics.mbt`: structured `PipelineDiagnostic`, severity aggregation, error/warning counters, stable sorting and text rendering.
- Extend `src/core/types.mbt` only with compatible helpers needed by the new modules.
- Add `src/core/quality_wbtest.mbt`.

TDD sequence:

1. Write tests for empty datasets, missing required fields, wrong field type, invalid geo ranges, duplicate IDs, all-null fields, mixed sources and stable profile output.
2. Run `moon test src/core --deny-warn`; verify failures are missing declarations or expected assertion failures.
3. Implement the minimum types and validators.
4. Run package tests, then the full suite; refactor only after green.

Acceptance assertions:

- Empty input produces zero counts and no divide-by-zero result.
- A duplicate ID is reported once per duplicated ID, with deterministic ordering.
- `profile_dataset` does not mutate input records.
- Null rate is in `[0, 1]`; invalid records never produce a successful validation result.

Target: roughly 700–900 new production lines with direct functional value.

## Task 3 — Build a multi-strategy candidate planner

Files:

- Add `src/blocking/candidate_types.mbt`: `CandidatePair`, `CandidateOrigin`, `CandidatePlan`, `PlannerOptions`, `BlockingStats`.
- Add `src/blocking/candidate_planner.mbt`: candidate key creation, pair normalization, stable deduplication, union/intersection/fallback composition, empty-key policy, maximum candidate budget and statistics.
- Add `src/blocking/candidate_metrics.mbt`: raw Cartesian count, reduction ratio, block-size histogram, largest block, zero-candidate and over-blocking flags.
- Modify `src/blocking/moon.pkg` only if package exports/imports require it.
- Add `src/blocking/candidate_planner_wbtest.mbt`.

TDD sequence:

1. Write tests for union duplicate pairs, intersection retention, fallback when all keys are empty, reversed pair normalization, max budget truncation, zero records, one-record Cartesian count and stable strategy statistics.
2. Run the package tests and record the expected red output.
3. Implement candidate planning without changing existing blockers.
4. Add an adapter in `src/pipeline/batch_pipeline.mbt` so `run_link` consumes a plan from all configured strategies instead of silently selecting the first one.
5. Run old pipeline tests and new planner tests.

Acceptance assertions:

- No `(a, b)` and `(b, a)` duplicates in a cross-dataset plan.
- Candidate reduction is `0` for an empty Cartesian denominator and never negative.
- Each retained pair has at least one origin strategy unless fallback explicitly created it.
- Applying a candidate budget is deterministic and reports truncation.

Target: roughly 700–1,000 new production lines.

## Task 4 — Add explainable scoring and threshold calibration

Files:

- Add `src/model/explanation_types.mbt`: `FieldContribution`, `ScoreExplanation`, `LabeledScore`, `ThresholdPoint`, `CalibrationReport`, `ConfusionMatrix` and stable status labels.
- Add `src/model/explainable_scorer.mbt`: field extraction, missingness contribution, weighted contribution, score bounds, threshold decision and explanation rendering.
- Add `src/model/calibration.mbt`: threshold grid generation, confusion matrix, precision/recall/F1, best-threshold tie breaking and invalid-step validation.
- Add `src/model/comparison_adapters.mbt`: exact, string, numeric, date, geo and phonetic comparison adapters using existing verified similarity APIs.
- Add `src/model/explainability_wbtest.mbt` and `src/model/calibration_wbtest.mbt`.
- Modify `src/pipeline/batch_pipeline.mbt` to reuse the scorer so the explanation and production decision cannot drift.

TDD sequence:

1. Test equal records, missing fields, zero total weight, negative weights rejected by config validation, exact threshold boundaries, empty labels, all-positive labels, all-negative labels and tied F1 thresholds.
2. Run the tests to observe the intended red state.
3. Implement scorer and calibration.
4. Integrate the scorer into the pipeline and run regression tests.

Acceptance assertions:

- Every field contribution is finite and the sum of contributions equals the composite score within the documented tolerance.
- Scores remain in `[0, 1]` for all built-in metrics.
- Threshold calibration never mutates source scores and chooses the lowest threshold on an exact F1 tie.
- Invalid calibration step and empty labels return structured errors.

Target: roughly 800–1,100 new production lines.

## Task 5 — Make graph clustering and canonicalization operational

Files:

- Add `src/graph/conflict_types.mbt`: `FieldConflict`, `ConflictReport`, `ClusterQuality`, `CanonicalEvidence`.
- Add `src/graph/conflict_detector.mbt`: per-component field conflict detection, missing-value handling, numeric tolerance and conflict severity.
- Modify `src/graph/canonical_merger.mbt` to implement all declared strategies, including deterministic majority vote, highest confidence and most recent selection; retain compatibility with existing constructors.
- Add `src/graph/canonical_evidence.mbt`: source vote counts, selected value, confidence and tie resolution.
- Add `src/graph/quality_wbtest.mbt`.

TDD sequence:

1. Test singleton clusters, empty clusters, all-null values, equal-vote ties, timestamp ties, conflicting phone/name fields and confidence ties.
2. Confirm red tests.
3. Implement detector and merger behavior.
4. Integrate canonicalization and conflict report into pipeline results.

Acceptance assertions:

- Canonical selection is stable for equal inputs.
- A conflict report is generated only when two non-null normalized values disagree beyond the configured policy.
- Cluster quality counts sum to the number of cluster records.

Target: roughly 500–750 new production lines.

## Task 6 — Add incremental, paged, and retry-safe pipeline execution

Files:

- Add `src/pipeline/operational_types.mbt`: `BatchWindow`, `PageRequest`, `PageResult`, `RunSummary`, `RetryPolicy`, `FailureRecord`, `IncrementalState`.
- Add `src/pipeline/incremental_pipeline.mbt`: upsert by ID, processed-batch tracking, duplicate-batch detection, page slicing, no-op replay and state snapshot methods.
- Add `src/pipeline/retry_executor.mbt`: bounded retry decision, failure isolation, deterministic attempt records and retryable/non-retryable classification.
- Add `src/pipeline/run_summary.mbt`: timings supplied by caller, counts and merge operations; no hidden system-clock dependency in library code.
- Add `src/pipeline/operational_wbtest.mbt`.
- Extend `BatchLinkageResult` with compatible optional operational fields only if `moon info` shows the generated interface remains manageable.

TDD sequence:

1. Test empty pages, page boundaries, overlapping pages, duplicate batch IDs, upsert replacement, retry exhaustion, non-retryable failures and idempotent replay.
2. Verify red tests.
3. Implement operational state and pipeline adapters.
4. Add one integration test covering a two-page cross-source run and a replay.

Acceptance assertions:

- Replaying the same batch does not duplicate output pairs.
- Page slicing never drops or duplicates a record when pages are non-overlapping.
- Retry attempts are bounded by policy and all failures remain inspectable.

Target: roughly 700–950 new production lines.

## Task 7 — Add deterministic evaluation and benchmark package

Files:

- Add `src/evaluation/moon.pkg` importing only public local packages.
- Add `src/evaluation/random_source.mbt`: a small deterministic seedable PRNG with documented sequence and no global state.
- Add `src/evaluation/synthetic_types.mbt`: `SyntheticDatasetConfig`, `SyntheticEntity`, `SyntheticDataset`, `NoiseProfile`, `GoldPair`.
- Add `src/evaluation/synthetic_generator.mbt`: deterministic entity generation, duplicate/noise injection, field omission, typo, phone formatting and source assignment.
- Add `src/evaluation/gold_standard.mbt`: gold links, non-links and canonical labels.
- Add `src/evaluation/evaluation_metrics.mbt`: pair precision/recall/F1, cluster metrics, candidate reduction, confusion matrix and invalid-input diagnostics.
- Add `src/evaluation/benchmark_types.mbt`: `BenchmarkConfig`, `BenchmarkSample`, `BenchmarkReport`, `BenchmarkSummary`.
- Add `src/evaluation/benchmark_runner.mbt`: warmup/sample loops, injected elapsed units, throughput calculation, peak candidate count and deterministic aggregation.
- Add `src/evaluation/report_text.mbt`, `report_csv.mbt`, and `report_json.mbt` using existing exporter conventions.
- Add `src/evaluation/evaluation_wbtest.mbt` and `src/evaluation/benchmark_wbtest.mbt`.

TDD sequence:

1. Test PRNG repeatability, same-seed dataset equality, zero entities, zero duplicates, 100% duplicates, zero noise, maximum noise, gold-pair counts and metric edge cases.
2. Run red tests.
3. Implement generator and metrics.
4. Test benchmark aggregation with injected sample durations; no test may rely on wall-clock thresholds.
5. Implement report renderers and integration with `BatchPipeline`.

Required benchmark scenarios:

- `smoke-100`: 100 source records with deterministic noise;
- `acceptance-1000`: 1,000 records, multiple sources and non-zero noise;
- `blocking-comparison`: same dataset with full Cartesian and multi-strategy blocking.

The CLI output must include record count, gold links, candidate pairs, reduction ratio, precision, recall, F1, total elapsed units and throughput. README numbers are written only after running the command and copying its exact output.

Target: roughly 1,800–2,600 new production lines. This is the principal source of real application value and the largest line-count increase.

## Task 8 — Complete CLI, examples, and documentation

Files:

- Modify `src/main/main.mbt` to retain the current demo and add deterministic benchmark, quality profile and calibration demos as separate functions.
- Modify `cmd/main/main.mbt` to parse the minimal supported command mode (`demo`, `benchmark`, `quality`) without external dependencies; default remains the current demo.
- Add `src/main/main_wbtest.mbt` coverage for default mode, benchmark mode and invalid mode output helpers.
- Update `README.md` to identify the August Hackathon, explain the module layout, public API examples, benchmark commands, measured output, line-count method, test/CI commands, license, maintainer and provenance.
- Update `README.mbt.md` with concise package-facing documentation; keep `OSC2026_8月黑客松申报书.md` unchanged.
- Update `moon.mod` `repository`, `description`, and `keywords` only with values matching the GitHub module; do not change module namespace or license.

Verification:

```text
moon run src/main
moon run cmd/main
moon run cmd/main -- benchmark --records 1000 --seed 20260818
moon run cmd/main -- quality
moon fmt --check
```

Target: roughly 250–450 new production lines plus documentation.

## Task 9 — Upgrade CI and add manual Mooncakes release workflow

Files:

- Replace `.github/workflows/test.yml` with a reviewed version of the MoonBit community `check.yml` pattern: three OS matrix, `actions/checkout@v4` with `persist-credentials: false`, official stable installer, `moon version --all`, `moon update`, `moon fmt --check`, `moon info` + `git diff --exit-code`, `moon check --deny-warn --target all`, `moon test --deny-warn --target all`, native test, coverage summary and CLI smoke run.
- Add `.github/workflows/publish.yml` based on the community template: `workflow_dispatch` only, read-only contents permission, prepublish check/test, temporary `MOONCAKES` credentials and cleanup.
- Review `.github/workflows/copilot-setup-steps.yml`; keep it only if valid and make checkout credentials read-only and toolchain setup consistent.
- Add `.github/dependabot.yml` only if the repository currently has no dependency automation and the syntax can be validated without third-party dependencies.

CI acceptance:

- No hard-coded personal tokens, user paths or non-stable nightly flags.
- `target all` does not include LLVM; native is explicit.
- Windows shell uses the official PowerShell installer path; Unix shells use the official Unix installer path.
- The workflow does not modify the repository silently; generated `moon.info`/format changes fail the job.

## Task 10 — Final quality gate, commits, remotes, and publication

Before any push, run the complete gate in a fresh shell and capture exit codes:

```text
moon version --all
moon fmt --check
moon info
git diff --exit-code
moon check --deny-warn --target all
moon test --deny-warn --target all
moon test --target native
moon build --target all
moon run src/main
moon run cmd/main -- benchmark --records 1000 --seed 20260818
powershell -NoProfile -File scripts/count_moonbit_lines.ps1
git diff --check
git status --short --branch
```

The count script must report `production_nonempty_lines >= 8000` and list all counted files. If the number is below target, only add a missing practical capability and its tests; do not add filler.

Account/remote verification, using only the currently authorized account:

```text
git remote -v
git remote show origin
git ls-remote --symref origin HEAD
gh api user --jq .login
gh repo view didiLjf/moon-record-linkage --json nameWithOwner,defaultBranchRef,owner
gh api repos/didiLjf/moon-record-linkage/contributors?per_page=100
moon login --help
moon publish --help
```

The expected GitHub login is `didiLjf`; if the API reports another user, stop before pushing. Verify the default branch from the remote response, verify the repository owner is `didiLjf`, and inspect contributors for the unique-contributor requirement. Verify the GitLink remote separately. Do not read or import unrelated cached accounts.

Commit sequence:

1. `docs: define acceptance enhancement design` (already committed as `036cc35`).
2. `refactor: make strict MoonBit checks clean`.
3. `feat: add quality profiles and candidate planning`.
4. `feat: add explainable scoring and operational pipeline`.
5. `feat: add deterministic evaluation benchmarks`.
6. `ci: add strict multi-target checks and publish workflow`.
7. `docs: record acceptance evidence`.

After each logical commit, run the nearest package tests and `git diff --check`; before merge/push run the full gate. Push only after account and remote verification:

```text
git push origin <verified-default-branch>
git push gitlink <verified-gitlink-branch>
```

Mooncakes publication is performed only after the GitHub push has succeeded and the published module name is confirmed as `didiLjf/moon-record-linkage`. Use `moon publish` through the already authorized login; if the registry reports the version already exists, increment `moon.mod` version only after checking the remote package state and preserving compatibility.

## Final self-review checklist

Apply the upstream `osc2026-guide` acceptance checklist to local evidence:

- valid MoonBit project and strict `moon check`/`moon test`;
- CI exists and covers check/build/test;
- GitHub default branch is verified, not assumed;
- GitHub owner, applicant, maintainer and sole contributor are consistent;
- Apache-2.0 root license is present;
- README has reproducible commands, runnable examples and real benchmark output;
- source scale is measured with implementation/test split;
- commit history contains meaningful contest-period work;
- no build artifacts, caches, copied code or unlicensed fixtures;
- package is published to Mooncakes and module namespace matches the account;
- runtime demo and benchmark complete without severe correctness/performance issues;
- `OSC2026_8月黑客松申报书.md` has no diff.

Any item without command/file evidence is reported as unresolved rather than claimed complete.
