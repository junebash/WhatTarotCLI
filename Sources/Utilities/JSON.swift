public enum JSON: Hashable, Sendable {
  case null
  case bool(Bool)
  case number(Double)
  case string(String)
  case array([JSON])
  case object([String: JSON])

  var null: Void? { if case .null = self { .some(()) } else { .none } }

  var bool: Bool? {
    if case .bool(let bool) = self {
      bool
    } else {
      nil
    }
  }

  var number: Double? {
    if case .number(let number) = self {
      number
    } else {
      nil
    }
  }

  var string: String? {
    if case .string(let string) = self {
      string
    } else {
      nil
    }
  }

  var array: [JSON]? {
    if case .array(let array) = self {
      array
    } else {
      nil
    }
  }

  var object: [String: JSON]? {
    if case .object(let object) = self {
      object
    } else {
      nil
    }
  }
}

extension JSON: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if container.decodeNil() {
      self = .null
    }
    if let bool = try? container.decode(Bool.self) {
      self = .bool(bool)
      return
    }
    if let number = try? container.decode(Double.self) {
      self = .number(number)
      return
    }
    if let string = try? container.decode(String.self) {
      self = .string(string)
      return
    }
    if let array = try? container.decode([JSON].self) {
      self = .array(array)
      return
    }
    if let object = try? container.decode([String: JSON].self) {
      self = .object(object)
      return
    }
    throw DecodingError.dataCorrupted(
      DecodingError.Context(
        codingPath: decoder.codingPath,
        debugDescription: "Unsupported JSON type"
      )
    )
  }

  public func encode(to encoder: any Encoder) throws {
    switch self {
    case .null:
      var container = encoder.singleValueContainer()
      try container.encodeNil()
    case .bool(let bool):
      var container = encoder.singleValueContainer()
      try container.encode(bool)
    case .number(let double):
      var container = encoder.singleValueContainer()
      try container.encode(double)
    case .string(let string):
      var container = encoder.singleValueContainer()
      try container.encode(string)
    case .array(let array):
      var container = encoder.unkeyedContainer()
      for element in array {
        try container.encode(element)
      }
    case .object(let object):
      var container = encoder.container(keyedBy: ObjectKey.self)
      for (key, value) in object {
        try container.encode(value, forKey: .init(stringValue: key))
      }
    }
  }
}

private struct ObjectKey: CodingKey {
  var stringValue: String

  var intValue: Int? { Int(stringValue) }

  init(stringValue: String) {
    self.stringValue = stringValue
  }

  init(intValue: Int) {
    stringValue = String(intValue)
  }
}

extension JSON {
  subscript(key: String) -> JSON? {
    guard case .object(let dictionary) = self else {
      return nil
    }
    return dictionary[key]
  }
}

extension JSON: ExpressibleByNilLiteral {
  public init(nilLiteral: ()) {
    self = .null
  }
}

extension JSON: ExpressibleByArrayLiteral {
  public init(arrayLiteral elements: JSON...) {
    self = .array(elements)
  }
}

extension JSON: ExpressibleByDictionaryLiteral {
  public init(dictionaryLiteral elements: (String, JSON)...) {
    var dictionary: [String: JSON] = [:]
    for (key, value) in elements {
      dictionary[key] = value
    }
    self = .object(dictionary)
  }
}

extension JSON: ExpressibleByFloatLiteral {
  public init(floatLiteral value: Double) {
    self = .number(value)
  }
}

extension JSON: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: Double) {
    self = .number(value)
  }
}

extension JSON: ExpressibleByBooleanLiteral {
  public init(booleanLiteral value: Bool) {
    self = .bool(value)
  }
}

extension JSON: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self = .string(value)
  }
}
