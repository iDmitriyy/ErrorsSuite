//
//  BaseErrorImpFunctions.swift
//  swifty-kit
//
//  Created by Dmitriy Ignatyev on 14.12.2024.
//

private import struct Foundation.Data
private import struct Foundation.Date
private import struct Foundation.TimeZone
private import struct Foundation.Calendar
private import class Foundation.DateFormatter
private import FoundationExtensions

extension BaseErrorImpFunctions {
  /// 512
  public static let stringValMaxLength: Int = 512
  /// 50
  public static let dictKeyMaxLength: Int = 50
  
  /// Date.now() in `yyyyMMddTHHmmssxxx` format with .current timeZone
  public static var dateWithTimeZone: String {
    Date.now.string(withFormat: "yyyy-MM-dd'T'HH:mm:ssxxx", timeZone: .current, calendar: .current)
  }
}

// ⚠️ @iDmitriyy
// TODO: - ADD compile flag for configuration of constants either with default values nor some other mechanism –
// complie string-flag, conformance for special type, etc.

extension Date {
  fileprivate func string(withFormat format: String, timeZone: TimeZone, calendar _: Calendar) -> String {
    var calendar = Calendar(identifier: .gregorian) // FIXME: LocalDateGregorian.calendarIdentifier
    calendar.timeZone = timeZone
    
    let formatter = DateFormatter()
    formatter.dateFormat = format
    formatter.calendar = calendar
    formatter.timeZone = timeZone
    
    return formatter.string(from: self)
  }
}
