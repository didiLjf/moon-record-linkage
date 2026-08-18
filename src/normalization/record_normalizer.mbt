///|
pub(all) enum NormalizationRule {
  Lowercase
  Uppercase
  TrimWhitespace
  CleanText
  PhoneDigits
  Company
  Person
  Address
  Email
  IdCard
} derive(Debug, Eq)

///|
pub fn NormalizationRule::supported() -> Array[NormalizationRule] {
  [
    Lowercase,
    Uppercase,
    TrimWhitespace,
    CleanText,
    PhoneDigits,
    Company,
    Person,
    Address,
    Email,
    IdCard,
  ]
}

///|
pub struct FieldRule {
  field_name : String
  rule : NormalizationRule
} derive(Debug, Eq)

///|
pub fn FieldRule::new(
  field_name : String,
  rule : NormalizationRule,
) -> FieldRule {
  { field_name, rule }
}

///|
pub struct NormalizationAudit {
  field_name : String
  rule : NormalizationRule
  original : String
  normalized : String
  changed : Bool
  skipped : Bool
} derive(Debug, Eq)

///|
fn apply_rule(value : String, rule : NormalizationRule) -> String {
  match rule {
    Lowercase => normalize_whitespace(to_lowercase(value))
    Uppercase => to_uppercase(value)
    TrimWhitespace => normalize_whitespace(value)
    CleanText => clean_text(value)
    PhoneDigits => normalize_phone(value)
    Company => normalize_company_name(value)
    Person => normalize_person_name(value)
    Address => normalize_address(value)
    Email => normalize_email(value)
    IdCard => normalize_id_card(value)
  }
}

///|
/// Apply field-specific normalizers in order and return an audit trail.
pub fn normalize_record(
  record : @core.Record,
  rules : Array[FieldRule],
) -> Array[NormalizationAudit] {
  let audit : Array[NormalizationAudit] = []
  for field_rule in rules {
    match record.attributes.get(field_rule.field_name) {
      Some(@core.StringVal(original)) => {
        let normalized = apply_rule(original, field_rule.rule)
        record.set_field(field_rule.field_name, @core.StringVal(normalized))
        audit.push({
          field_name: field_rule.field_name,
          rule: field_rule.rule,
          original,
          normalized,
          changed: original != normalized,
          skipped: false,
        })
      }
      Some(value) => {
        let original = value.to_str()
        audit.push({
          field_name: field_rule.field_name,
          rule: field_rule.rule,
          original,
          normalized: original,
          changed: false,
          skipped: true,
        })
      }
      None =>
        audit.push({
          field_name: field_rule.field_name,
          rule: field_rule.rule,
          original: "",
          normalized: "",
          changed: false,
          skipped: true,
        })
    }
  }
  audit
}

///|
/// Normalize a dataset in place and return one audit list per record.
pub fn normalize_dataset(
  records : Array[@core.Record],
  rules : Array[FieldRule],
) -> Array[Array[NormalizationAudit]] {
  let audits : Array[Array[NormalizationAudit]] = []
  for record in records {
    audits.push(normalize_record(record, rules))
  }
  audits
}
