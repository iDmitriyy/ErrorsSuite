//
//  JsonMappingError.swift
//  swifty-kit
//
//  Created by Dmitriy Ignatyev on 14.12.2024.
//

private import SwiftyKit

/// Ошибка маппинга, которую можно throw'ить в Decodeable / Encodable методах.
public final class JsonMappingError: ConcreteBaseError {
  public let domainShortCode: String = "JM"
  
  public let errorCode: ErrorCode
  
  /// Always nil, because MappingError is a root error
  public let underlying: (any BaseError)?
  
  public let primaryInfo: ErrorInfo
  
  public let info: ErrorInfo
  
  public let debugDetails: String?
  
  public let localizedMessage: String
  
  public let providesCodeChain = false
  
  public let identitySuffix: String?
  
  private init(errorCode: ErrorCode,
               debugMessage: String?,
               underlyingError: (any BaseError)?,
               primaryInfo: ErrorInfo,
               info: ErrorInfo,
               identity: String?,
               file: StaticString,
               line: UInt) {
    self.errorCode = errorCode
    underlying = underlyingError
    self.identitySuffix = identity.map { Self.impFuncs.shortCodeOf(identity: $0) }
    debugDetails = debugMessage
    
    let (fileLineKey, fileLineValue) = Self.impFuncs.fileLine(fileId: file, line: line, domainShortCode: domainShortCode)
    self.primaryInfo = mutate(value: primaryInfo) {
      $0[fileLineKey] = fileLineValue
    }
    
    self.info = info
    localizedMessage = "Произошла ошибка преобразования данных"
  }
  
  /// Для случаев, когда параметры file и line нужно прокинуть из другой функции
  public convenience init(code: ErrorCode, info: ErrorInfo = [:], file: StaticString, line: UInt) {
    self.init(errorCode: code,
              debugMessage: nil,
              underlyingError: nil,
              primaryInfo: [:],
              info: info,
              identity: nil,
              file: file,
              line: line)
  }
  
  /// Для случаев, когда нужно прокинуть rawValue проперти, чтобы стало понятно, почему Json не смог быть декодирован
  public convenience init(code: ErrorCode,
                          rawValue: any ErrorInfo.ValueType,
                          info: ErrorInfo = [:],
                          file: StaticString = #fileID,
                          line: UInt = #line) {
    self.init(errorCode: code,
              debugMessage: nil,
              underlyingError: nil,
              primaryInfo: ["rawValue": rawValue],
              info: info,
              identity: "\(type(of: rawValue))",
              file: file,
              line: line)
  }
  
  /// Для случаев, когда нужно прокинуть Тип значения, чтобы понять, почему Json не смог быть декодирован.
  /// Как правило, это бывает нужно внутри decode(from:) метода у Generic структур. Например при декодинге Either.
  public convenience init<T>(code: ErrorCode,
                             typeOfValue: T.Type,
                             debugMessage: String? = nil,
                             underlyingError: (any BaseError)? = nil,
                             info: ErrorInfo = [:],
                             file: StaticString = #fileID,
                             line: UInt = #line) {
    self.init(errorCode: code,
              debugMessage: debugMessage,
              underlyingError: underlyingError,
              primaryInfo: [Self.infoKeys.typeTKey: "\(typeOfValue)"],
              info: info,
              identity: "\(typeOfValue)",
              file: file,
              line: line)
  }
  
  public enum ErrorCode: Int, BaseErrorCode {
    case typeCastFailed = 0
    case nilData = 1
    case unexpectedNilValue = 2
    case unexpectedValue = 3
    
    case unexpectedEmptyArray = 10
    case unexpectedEmptyString = 13
    
    case invalidElementsCount = 11
    case outOfRange = 12
    
    case unknownElementType = 14
    /// Некорректный тип элемента в массиве
    case invalidElementType = 15
    case invalidJson = 16
    
    /// Не получилось преобразовать Data в String
    case invalidDataFromString = 21
    case invalidStringFromData = 22
    
    case invalidDateFormat = 31
  }
}
