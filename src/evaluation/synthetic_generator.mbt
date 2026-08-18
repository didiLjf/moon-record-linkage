///|
fn synthetic_city(index : Int) -> String {
  match index % 5 {
    0 => "Beijing"
    1 => "Shanghai"
    2 => "Shenzhen"
    3 => "Hangzhou"
    _ => "Chengdu"
  }
}

///|
fn maybe_noise(
  value : String,
  random : DeterministicRandom,
  noise_level : Double,
) -> String {
  if value.is_empty() || random.next_unit() >= noise_level {
    value
  } else {
    value + "x"
  }
}

///|
fn synthetic_record(
  prefix : String,
  index : Int,
  source : String,
  name : String,
  city : String,
  phone : String,
) -> @core.Record {
  let record = @core.Record::new(
    prefix + "-" + index.to_string(),
    source~,
    timestamp=1700000000L + index.to_int64(),
  )
  record.set_field("name", @core.StringVal(name))
  record.set_field("city", @core.StringVal(city))
  record.set_field("phone", @core.StringVal(phone))
  record
}

///|
/// Generate two source datasets with deterministic noise and a gold link per entity.
pub fn generate_dataset(config : SyntheticDatasetConfig) -> SyntheticDataset {
  let left_records : Array[@core.Record] = []
  let right_records : Array[@core.Record] = []
  let gold_pairs : Array[GoldPair] = []
  let random = DeterministicRandom::new(config.seed)
  for index = 0; index < config.entity_count; index = index + 1 {
    let base_name = "Customer " + index.to_string()
    let city = synthetic_city(index)
    let phone = "138000" + index.to_string()
    let left = synthetic_record("left", index, "crm", base_name, city, phone)
    let include_right = random.next_unit() <= config.duplicate_rate
    if include_right {
      let right_name = maybe_noise(base_name, random, config.noise_level)
      let right_phone = maybe_noise(phone, random, config.noise_level)
      let right = synthetic_record(
        "right", index, "erp", right_name, city, right_phone,
      )
      right_records.push(right)
      gold_pairs.push(GoldPair::new(left.id, right.id, true))
    }
    left_records.push(left)
  }
  { left_records, right_records, gold_pairs, entity_count: config.entity_count }
}
