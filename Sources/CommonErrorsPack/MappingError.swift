//
//  MappingError.swift
//  swifty-kit
//
//  Created by Dmitriy Ignatyev on 14.12.2024.
//

import struct Foundation.Data
private import SwiftyKit

/// Ошибка маппинга данных. Например, при преобразовании сетевого DTO в доменную модель, или преобразовании Int числа в доменный enum.
public final class MappingError: ConcreteBaseError {
  public let domainShortCode: String = "ME"
  
  public let errorCode: ErrorCode
  
  public let underlying: (any BaseError)?
  
  public let info: ErrorInfo
  
  public let primaryInfo: ErrorInfo
  
  public let debugDetails: String?
  
  public let identitySuffix: String?
  
  public let localizedMessage: String
  
  public let providesCodeChain = true
  
  public init(code: ErrorCode,
              localizedMessage: String? = nil,
              debugMessage: String? = nil,
              underlyingError: (any BaseError)? = nil,
              primaryInfo: ErrorInfo = [:],
              info: ErrorInfo = [:],
              file: StaticString = #fileID,
              line: UInt = #line) {
    self.errorCode = code
    underlying = underlyingError
        
    debugDetails = debugMessage
    // Для ошибок маппинга 2 букв домена недостаточно, чтоб с достаточной точностью дифференцировать ошибки в логах.
    // Поэтому добавляем короткий код файла.
    identitySuffix = Self.impFuncs.shortCodeOf(fileId: file)
    
    let (fileLineKey, fileLineValue) = Self.impFuncs.fileLine(fileId: file, line: line, domainShortCode: domainShortCode)
    self.primaryInfo = mutate(value: primaryInfo) { $0[fileLineKey] = fileLineValue }
    
    self.info = info
    
    self.localizedMessage = localizedMessage ?? "Произошла ошибка преобразования данных"
  }
  
  public convenience init(code: ErrorCode, info: ErrorInfo = [:], file: StaticString = #fileID, line: UInt = #line) {
    self.init(code: code, debugMessage: nil, underlyingError: nil, info: info, file: file, line: line)
  }
  
  /// - Parameters:
  ///   - codableError: error thrown by Decoder / Encoder
  public convenience init(codableError: any Error,
                          typeOfValue: Any.Type? = nil,
                          jsonData: Data? = nil,
                          info: ErrorInfo = [:],
                          file: StaticString = #fileID,
                          line: UInt = #line) {
    var errorInfo: ErrorInfo = [:]
    errorInfo.add(key: Self.infoKeys.typeTKey, optionalValue: typeOfValue.map { "\($0)" })
    
    ErrorInfo.merge(info, to: &errorInfo)
    
    Self.impFuncs.processCodableError(codableError, responseData: jsonData, putInfoTo: &errorInfo)
    
    // пробуем скастить в BaseError. Это даст дополнительную информацию в логах
    self.init(code: .codable,
              debugMessage: nil,
              underlyingError: codableError as? any BaseError,
              info: errorInfo,
              file: file,
              line: line)
  }
  
  public enum ErrorCode: Int, BaseErrorCode {
    case typeConversionFailed = 0
    case typeCastFailed = 1
    case nilData = 2
    case emptyData = 5
    case unexpectedNilValue = 3
    case unexpectedValue = 4
    case missingValueInSequence = 6
    
    case unexpectedEmptyArray = 10
    case unexpectedEmptyString = 11
    case unexpectedEmptyDict = 12
    case unexpectedEmptySet = 13
    case invalidElementsCount = 19
    
    /// Некорректный тип элемента в массиве
    case invalidElementType = 21
    case invalidData = 22
    case invalidValue = 23
    
    case formatLogicalControl = 30
    
    case codable = 40
    case outOfRange = 50
    
    case dtoMappingFailed = 60
  }
}

extension MappingError {
  public static func formatLogicalСontrolFailure<T>(value: T, file: StaticString = #fileID, line: UInt = #line) -> Self {
    let debugMessage = "Value \(value) is not logically valid, file: \(file) line: \(line)"
    return Self(code: .formatLogicalControl,
                debugMessage: debugMessage,
                underlyingError: nil,
                info: [:],
                file: file,
                line: line)
  }
}
