// Deterministic Rule Engine for Record Matching
// Supports compound rules with AND/OR/NOT logic, field weights, and thresholds.

///|
pub enum RuleOp {
  And
  Or
} derive(Debug, Eq)

///|
/// Return the supported boolean operators for configuration UIs and reports.
pub fn RuleOp::supported() -> Array[RuleOp] {
  [And, Or]
}

///|
pub enum RuleAtom {
  FieldEqual(String)
  FieldSimilarityAbove(String, Double)
  Phonetic(String)
  AlwaysTrue
  AlwaysFalse
} derive(Debug, Eq)

///|
/// Return representative atom constructors for introspection tools.
pub fn RuleAtom::supported_examples() -> Array[RuleAtom] {
  [
    FieldEqual("field"),
    FieldSimilarityAbove("field", 0.8),
    Phonetic("field"),
    AlwaysTrue,
    AlwaysFalse,
  ]
}

///|
pub enum RuleExpr {
  Atom(RuleAtom)
  Not(RuleExpr)
  Combine(RuleOp, Array[RuleExpr])
} derive(Debug)

///|
/// Return representative expression constructors for introspection tools.
pub fn RuleExpr::supported_examples() -> Array[RuleExpr] {
  [Atom(AlwaysTrue), Not(Atom(AlwaysFalse)), Combine(And, [Atom(AlwaysTrue)])]
}

///|
pub struct RuleSet {
  rules : Array[RuleExpr]
  combination_op : RuleOp
} derive(Debug)

///|
pub fn RuleSet::new(combination_op? : RuleOp = And) -> RuleSet {
  { rules: [], combination_op }
}

///|
pub fn RuleSet::add_rule(self : RuleSet, rule : RuleExpr) -> Unit {
  self.rules.push(rule)
}

///|
pub struct RuleContext {
  field_similarities : Map[String, Double]
  record_a : @core.Record
  record_b : @core.Record
} derive(Debug)

///|
pub fn RuleContext::new(
  record_a : @core.Record,
  record_b : @core.Record,
) -> RuleContext {
  { field_similarities: Map([]), record_a, record_b }
}

///|
pub fn RuleContext::set_similarity(
  self : RuleContext,
  field : String,
  sim : Double,
) -> Unit {
  self.field_similarities.set(field, sim)
}

///|
pub fn RuleContext::get_similarity(
  self : RuleContext,
  field : String,
) -> Double {
  match self.field_similarities.get(field) {
    Some(s) => s
    None => 0.0
  }
}

///|
/// Evaluate a rule expression given a context.
pub fn eval_rule(expr : RuleExpr, ctx : RuleContext) -> Bool {
  match expr {
    Atom(atom) => eval_atom(atom, ctx)
    Not(inner) => !eval_rule(inner, ctx)
    Combine(op, sub_rules) =>
      match op {
        And => {
          for r in sub_rules {
            if !eval_rule(r, ctx) {
              return false
            }
          }
          true
        }
        Or => {
          for r in sub_rules {
            if eval_rule(r, ctx) {
              return true
            }
          }
          false
        }
      }
  }
}

///|
fn eval_atom(atom : RuleAtom, ctx : RuleContext) -> Bool {
  match atom {
    AlwaysTrue => true
    AlwaysFalse => false
    FieldEqual(field) => {
      let a = ctx.record_a.get_string(field)
      let b = ctx.record_b.get_string(field)
      a == b && !a.is_empty()
    }
    FieldSimilarityAbove(field, threshold) =>
      ctx.get_similarity(field) >= threshold
    Phonetic(field) => {
      let a = ctx.record_a.get_string(field)
      let b = ctx.record_b.get_string(field)
      @similarity.jaro_winkler(a, b) >= 0.85
    }
  }
}

///|
/// Evaluate a ruleset and return whether all/any rules match.
pub fn RuleSet::evaluate(self : RuleSet, ctx : RuleContext) -> Bool {
  if self.rules.is_empty() {
    return false
  }
  match self.combination_op {
    And => {
      for r in self.rules {
        if !eval_rule(r, ctx) {
          return false
        }
      }
      true
    }
    Or => {
      for r in self.rules {
        if eval_rule(r, ctx) {
          return true
        }
      }
      false
    }
  }
}
