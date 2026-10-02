import PlatformClient
import Testing

private typealias TypedValue = Primandproper_Platform_Settings_V1_TypedValue
private typealias ResolvedSetting = Primandproper_Platform_Settings_V1_ResolvedSetting

private func refusal(_ text: String, _ kind: Primandproper_Platform_Settings_V1_SettingKind)
  -> SettingValueError?
{
  do {
    _ = try TypedValue(text: text, kind: kind)
    return nil
  } catch let error as SettingValueError {
    return error
  } catch {
    Issue.record("threw \(error), not a SettingValueError")
    return nil
  }
}

@Suite struct TypedValueTextTests {
  @Test func roundTripsAValueOfEachKind() throws {
    let cases: [(String, Primandproper_Platform_Settings_V1_SettingKind, TypedValue.OneOf_Value)] =
      [
        ("metric", .string, .stringValue("metric")),
        ("true", .boolean, .boolValue(true)),
        ("false", .boolean, .boolValue(false)),
        ("-42", .integer, .intValue(-42)),
        ("1.5", .float, .floatValue(1.5)),
      ]
    for (text, kind, value) in cases {
      let typed = try TypedValue(text: text, kind: kind)
      #expect(typed.value == value)
      #expect(typed.text == text)
    }
  }

  @Test func writesAStringSettingAsTextEvenWhenItLooksLikeANumber() throws {
    #expect(try TypedValue(text: "42", kind: .string).value == .stringValue("42"))
    #expect(try TypedValue(text: "true", kind: .string).value == .stringValue("true"))
  }

  @Test func readsNoValueAsNilAndAnEmptyStringAsEmpty() throws {
    #expect(TypedValue().text == nil)

    let empty = try TypedValue(text: "", kind: .string)
    #expect(empty.value == .stringValue(""))
    #expect(empty.text == "")
  }

  @Test func readsAnUnsetResolutionAsNil() {
    var resolution = ResolvedSetting()
    resolution.source = .unset

    #expect(resolution.typedValue.text == nil)
  }

  @Test func readsBooleansAsStrconvParseBoolDoes() throws {
    for text in ["true", "True", "TRUE", "t", "T", "1"] {
      #expect(try TypedValue(text: text, kind: .boolean).value == .boolValue(true))
    }
    for text in ["false", "False", "FALSE", "f", "F", "0"] {
      #expect(try TypedValue(text: text, kind: .boolean).value == .boolValue(false))
    }
    #expect(try TypedValue(text: "True", kind: .boolean).text == "true")
    for text in ["tRUE", "yes", "", " true", "2"] {
      #expect(refusal(text, .boolean) == .notOfKind(text: text, kind: .boolean))
    }
  }

  @Test func readsIntegersInBaseTenAndRefusesOverflow() throws {
    #expect(try TypedValue(text: "9223372036854775807", kind: .integer).value == .intValue(.max))
    #expect(try TypedValue(text: "-9223372036854775808", kind: .integer).value == .intValue(.min))
    #expect(try TypedValue(text: "+5", kind: .integer).value == .intValue(5))
    #expect(try TypedValue(text: "007", kind: .integer).text == "7")
    for text in ["9223372036854775808", "-9223372036854775809", "1.0", "1_000", "", "+", " 1"] {
      #expect(refusal(text, .integer) == .notOfKind(text: text, kind: .integer))
    }
  }

  @Test func acceptsNonFiniteFloatsAsTheServerDoes() throws {
    #expect(try TypedValue(text: "NaN", kind: .float).floatValue.isNaN)
    #expect(try TypedValue(text: "nan", kind: .float).text == "NaN")
    #expect(try TypedValue(text: "inf", kind: .float).value == .floatValue(.infinity))
    #expect(try TypedValue(text: "-Infinity", kind: .float).text == "-Inf")
    #expect(try TypedValue(text: "+Inf", kind: .float).text == "+Inf")
    for text in ["-nan", "infin", "nan(1)", "1e400", "-1e400"] {
      #expect(refusal(text, .float) == .notOfKind(text: text, kind: .float))
    }
  }

  @Test func readsFloatsAsStrconvParseFloatDoes() throws {
    let accepted: [(String, Double)] = [
      (".5", 0.5), ("5.", 5), ("1E5", 100_000), ("1_000", 1000), ("0x1p-2", 0.25),
      ("0X.8P1", 1), ("0x_1p0", 1), ("2e-324", 0),
    ]
    for (text, number) in accepted {
      #expect(try TypedValue(text: text, kind: .float).value == .floatValue(number))
    }
    for text in ["", ".", "1e", "0x1.8", "1__0", "1_", "_1", "1_.5", " 1", "1,5", "0b1"] {
      #expect(refusal(text, .float) == .notOfKind(text: text, kind: .float))
    }
  }

  @Test func writesFloatsAsStrconvFormatFloatDoes() {
    let formatted: [(Double, String)] = [
      (0, "0"), (-0.0, "-0"), (1, "1"), (-2.5, "-2.5"), (123_456, "123456"),
      (1_000_000, "1e+06"), (1_234_567, "1.234567e+06"), (0.0001, "0.0001"), (0.00001, "1e-05"),
      (1e21, "1e+21"), (5e-324, "5e-324"), (.greatestFiniteMagnitude, "1.7976931348623157e+308"),
    ]
    for (number, text) in formatted {
      var value = TypedValue()
      value.floatValue = number
      #expect(value.text == text)
    }
  }

  @Test func refusesAKindWithNoValueCase() {
    #expect(refusal("x", .unspecified) == .unknownKind(.unspecified))
    #expect(refusal("x", .UNRECOGNIZED(9)) == .unknownKind(.UNRECOGNIZED(9)))
  }

  @Test func describesARefusalInTheServersWords() {
    #expect(
      SettingValueError.notOfKind(text: "abc", kind: .integer).description
        == "\"abc\" is not an integer")
    #expect(
      SettingValueError.notOfKind(text: "yes", kind: .boolean).description
        == "\"yes\" is not a boolean")
  }
}
