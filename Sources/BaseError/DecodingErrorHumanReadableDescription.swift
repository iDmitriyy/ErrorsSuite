//
//  DecodingErrorHumanReadableDescription.swift
//  errors-suite
//
//  Created by Dmitriy Ignatyev on 14.04.2025.
//

private import class Foundation.NSError
private import let Foundation.NSDebugDescriptionErrorKey

extension DecodingError {
  /// Описание ошибки в человеческом виде.
  /// Очень часто при ошибках декодинга нужно понять, по какому ключу не замапилось значение и по какой причине.
  /// Дефолтное же описание в свою очередь очень длинное, помимо полезной информации содержит много шума и его сложно читать.
  public var humanReadableDescription: String {
    let underlyingErrDescr: ((any Error)?) -> String? = {
      guard let error = $0 else { return nil }
      
      let common = ", context.underlyingError: "
      let nsError = error as NSError
      
      guard let debugDescr = nsError.userInfo[NSDebugDescriptionErrorKey] as? String else {
        return common + "детали отсутствуют, т.к. по ключу NSDebugDescriptionErrorKey нет описания"
      }
      // В отличии от String(reflecting: self), userInfo[NSDebugDescriptionErrorKey] содержит только текст вида
      // "No string key for value in object around character 1", без лишнего шума.
      return common + debugDescr
    }
    
    switch self {
    case let .typeMismatch(type, context):
      let kind = "DecodingError typeMismatch"
      return kind
        + " for key '\(context.codingPathDescription)', Type \(type), contextDebugDescr: "
        + context.debugDescription + ", "
        + (underlyingErrDescr(context.underlyingError).map { ", " + $0 } ?? "")
      
    case let .valueNotFound(type, context):
      let kind = "DecodingError valueNotFound"
      return kind
        + " for key '\(context.codingPathDescription)', Type \(type), contextDebugDescr: "
        + context.debugDescription + ", "
        + (underlyingErrDescr(context.underlyingError).map { ", " + $0 } ?? "")
      
    case let .keyNotFound(_, context):
      let kind = "DecodingError keyNotFound"
      return kind
        + ", contextDebugDescr: "
        + context.debugDescription + ", "
        + (underlyingErrDescr(context.underlyingError).map { ", " + $0 } ?? "")
      
    case .dataCorrupted(let context):
      let kind = "DecodingError dataCorrupted"
      return kind
        + " for key '\(context.codingPathDescription)', contextDebugDescr: "
        + context.debugDescription
        + (underlyingErrDescr(context.underlyingError).map { ", " + $0 } ?? "")
    @unknown default:
      return String(reflecting: self)
    }
  }
}

extension DecodingError.Context {
  fileprivate var codingPathDescription: String {
    let components = codingPath.map { $0.stringValue }
    return components.joined(separator: ">")
  }
}

extension EncodingError {
  public var humanReadableDescription: String {
    switch self {
    case .invalidValue(_, let context):
      let kind = "DecodingError invalidValue"
      return kind + " for key '\(context.codingPathDescription)', explanation: " + context.debugDescription
    @unknown default:
      return String(describing: self)
    }
  }
}

extension EncodingError.Context {
  fileprivate var codingPathDescription: String {
    let components = codingPath.map { $0.stringValue }
    return components.joined(separator: ">")
  }
}
