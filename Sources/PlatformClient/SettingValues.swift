/// SettingValueError is text a form holds that cannot be written as a setting's value.
public enum SettingValueError: Error, Sendable, Hashable, CustomStringConvertible {
  /// notOfKind is text that is not a value of the setting's kind, as the server reads one.
  case notOfKind(text: String, kind: Primandproper_Platform_Settings_V1_SettingKind)
  /// unknownKind is a kind with no value case to write: unspecified, which the server refuses
  /// to define a setting as, or one newer than this client.
  case unknownKind(Primandproper_Platform_Settings_V1_SettingKind)

  public var description: String {
    switch self {
    case .notOfKind(let text, .integer):
      "\(text.debugDescription) is not an integer"
    case .notOfKind(let text, let kind):
      "\(text.debugDescription) is not a \(kindName(kind))"
    case .unknownKind(let kind):
      "a setting of \(kindName(kind)) kind has no value this client can write"
    }
  }
}

extension Primandproper_Platform_Settings_V1_TypedValue {
  /// init(text:kind:) is the value a write carries for `text`, a form's answer to a setting of
  /// `kind`. The case follows `kind` and never `text`, because the server refuses a case that
  /// is not the setting's kind (settings.ErrKindMismatch): a string setting is written as text
  /// even when its answer looks like a number.
  ///
  /// Text is a value of a kind when Go's strconv reads it as one, which is how the server
  /// checks a definition's default and enumeration: "true", "True", "t" and "1" are all
  /// booleans, "+5" is an integer, and "NaN", "-Inf" and "1_000" are floats. An integer or a
  /// float out of range is not. Anything that is not throws `SettingValueError`.
  public init(text: String, kind: Primandproper_Platform_Settings_V1_SettingKind) throws {
    self.init()
    switch kind {
    case .string:
      value = .stringValue(text)
    case .boolean:
      guard let flag = goBool(text) else {
        throw SettingValueError.notOfKind(text: text, kind: kind)
      }
      value = .boolValue(flag)
    case .integer:
      guard let number = Int64(text) else {
        throw SettingValueError.notOfKind(text: text, kind: kind)
      }
      value = .intValue(number)
    case .float:
      guard let number = goFloat(text) else {
        throw SettingValueError.notOfKind(text: text, kind: kind)
      }
      value = .floatValue(number)
    case .unspecified, .UNRECOGNIZED:
      throw SettingValueError.unknownKind(kind)
    }
  }

  /// text is the value as the server stores it, which is the form a definition's enumeration
  /// is compared in: "true" or "false", base ten, and a float as Go's
  /// `strconv.FormatFloat(f, 'g', -1, 64)` writes it ("1", "1e+06", "NaN").
  ///
  /// It is nil when no case is set, which is how a resolution whose source is
  /// `VALUE_SOURCE_UNSET` reads, and nil is not "": a string setting answered with nothing is
  /// "".
  public var text: String? {
    switch value {
    case .stringValue(let text): text
    case .boolValue(let flag): String(flag)
    case .intValue(let number): String(number)
    case .floatValue(let number): goFormat(number)
    case nil: nil
    }
  }
}

private func kindName(_ kind: Primandproper_Platform_Settings_V1_SettingKind) -> String {
  switch kind {
  case .string: "string"
  case .boolean: "boolean"
  case .integer: "integer"
  case .float: "float"
  case .unspecified: "unspecified"
  case .UNRECOGNIZED(let raw): "unrecognized (\(raw))"
  }
}

/// goBool reads `text` as Go's strconv.ParseBool does, or is nil where it refuses it.
private func goBool(_ text: String) -> Bool? {
  switch text {
  case "1", "t", "T", "TRUE", "true", "True": true
  case "0", "f", "F", "FALSE", "false", "False": false
  default: nil
  }
}

/// goFloat reads `text` as Go's strconv.ParseFloat(text, 64) does, or is nil where it refuses
/// it, out of range included. Swift's Double(_:) admits a different syntax (hex without an
/// exponent, "nan(...)", no underscores), so the syntax is checked here and Double only converts.
private func goFloat(_ text: String) -> Double? {
  var body = Substring(text)
  var sign = 1.0
  if let first = body.first, first == "+" || first == "-" {
    sign = first == "-" ? -1 : 1
    body = body.dropFirst()
  }
  switch body.lowercased() {
  case "inf", "infinity":
    return sign * .infinity
  case "nan" where body.count == text.count:
    return .nan
  default:
    break
  }

  guard isGoFloatSyntax(Array(body.unicodeScalars)),
    let number = Double(text.filter { $0 != "_" }.lowercased()), number.isFinite
  else {
    return nil
  }
  return number
}

/// isGoFloatSyntax is readFloat's grammar from Go's strconv, for an unsigned number: decimal
/// with an optional exponent, or hexadecimal with a mandatory binary one.
private func isGoFloatSyntax(_ scalars: [Unicode.Scalar]) -> Bool {
  let hex = scalars.count >= 2 && scalars[0] == "0" && (scalars[1] == "x" || scalars[1] == "X")
  var i = hex ? 2 : 0
  var sawDigits = false
  var sawDot = false
  var underscores = false

  while i < scalars.count {
    let c = scalars[i]
    if c == "_" {
      underscores = true
    } else if c == "." {
      if sawDot { return false }
      sawDot = true
    } else if isDigit(c, hex: hex) {
      sawDigits = true
    } else {
      break
    }
    i += 1
  }
  if !sawDigits { return false }

  let exponent: Set<Unicode.Scalar> = hex ? ["p", "P"] : ["e", "E"]
  if i < scalars.count, exponent.contains(scalars[i]) {
    i += 1
    if i < scalars.count, scalars[i] == "+" || scalars[i] == "-" {
      i += 1
    }
    guard i < scalars.count, isDigit(scalars[i], hex: false) else { return false }
    while i < scalars.count, isDigit(scalars[i], hex: false) || scalars[i] == "_" {
      underscores = underscores || scalars[i] == "_"
      i += 1
    }
  } else if hex {
    return false
  }

  return i == scalars.count && (!underscores || underscoresSeparateDigits(scalars, hex: hex))
}

/// underscoresSeparateDigits is Go's underscoreOK: each underscore sits between two digits,
/// or between the base prefix and a digit.
private func underscoresSeparateDigits(_ scalars: [Unicode.Scalar], hex: Bool) -> Bool {
  enum Last {
    case start
    case digit
    case underscore
    case other
  }
  var last: Last = hex ? .digit : .start
  for c in scalars[(hex ? 2 : 0)...] {
    if isDigit(c, hex: hex) {
      last = .digit
    } else if c == "_" {
      if last != .digit { return false }
      last = .underscore
    } else if last == .underscore {
      return false
    } else {
      last = .other
    }
  }
  return last != .underscore
}

private func isDigit(_ c: Unicode.Scalar, hex: Bool) -> Bool {
  ("0"..."9").contains(c) || hex && (("a"..."f").contains(c) || ("A"..."F").contains(c))
}

/// goFormat writes `number` as Go's strconv.FormatFloat(number, 'g', -1, 64) does. Swift's
/// description carries the same shortest digits that read back as `number`, in another layout,
/// so this reads the digits out of it and lays them out as Go does: an exponent below -4 or
/// from 6 up is written as one, and anything else is written out in full.
private func goFormat(_ number: Double) -> String {
  if number.isNaN { return "NaN" }
  if number.isInfinite { return number < 0 ? "-Inf" : "+Inf" }

  let sign = number.sign == .minus ? "-" : ""
  var mantissa = Substring(number.magnitude.description)
  var exponent = 0
  if let e = mantissa.firstIndex(of: "e") {
    exponent = Int(mantissa[mantissa.index(after: e)...]) ?? 0
    mantissa = mantissa[..<e]
  }
  let point = mantissa.firstIndex(of: ".") ?? mantissa.endIndex
  var decimalPoint = mantissa.distance(from: mantissa.startIndex, to: point) + exponent
  var digits = Array(mantissa.filter { $0 != "." })
  while digits.first == "0" {
    digits.removeFirst()
    decimalPoint -= 1
  }
  while digits.last == "0" {
    digits.removeLast()
  }
  if digits.isEmpty { return sign + "0" }

  let scientific = decimalPoint - 1
  if scientific < -4 || scientific >= 6 {
    let fraction = digits.count > 1 ? "." + String(digits[1...]) : ""
    let magnitude = abs(scientific)
    return sign + String(digits[0]) + fraction + "e" + (scientific < 0 ? "-" : "+")
      + (magnitude < 10 ? "0" : "") + String(magnitude)
  }

  let whole =
    decimalPoint > 0
    ? String(digits.prefix(decimalPoint))
      + String(repeating: "0", count: max(decimalPoint - digits.count, 0))
    : "0"
  let fractionDigits = max(digits.count - decimalPoint, 0)
  if fractionDigits == 0 { return sign + whole }
  let fraction = (0..<fractionDigits).map { j -> Character in
    let index = decimalPoint + j
    return index >= 0 && index < digits.count ? digits[index] : "0"
  }
  return sign + whole + "." + String(fraction)
}
