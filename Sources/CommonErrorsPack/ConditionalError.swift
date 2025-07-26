//
//  ConditionalError.swift
//  swifty-kit
//
//  Created by Dmitriy Ignatyev on 14.12.2024.
//

/// ConditionalError нужен для отслеживания ошибочных ситуаций, которые не отображаются в UI и не влияют на поведение
/// объектов.
/// Например рассмотрим код 'guard let tariff = Tariff.first else { return }'. Предполагается, что массив тарифов не пустой.
/// Однако если он пуст, то приложение никак не реагирует. Пользователь никак не узнает что произошла ошибка в логике.
/// Разработчики тоже об этом не узнают. В этом случае, мы можем залогировать такую ошибочную ситуацию.
public final class ConditionalError: ConcreteBaseError { // TODO: - make it a struct
  public let domainShortCode: String = "CL" // Conditional Error
  
  public let errorCode: ConditionalErrorCode
  
  public let underlying: (any BaseError)?
  
  public let primaryInfo: ErrorInfo
  
  public let info: ErrorInfo
  
  public let debugDetails: String?
  
  public let identitySuffix: String?
  
  public let localizedMessage: String = "Произошла непредвиденная ошибка в приложении"
  
  /// У этой ошибки всегда показываем код
  public let providesCodeChain = true
  
  private init(code: ConditionalErrorCode,
               debugMessage: String?,
               underlyingError: (any BaseError)?,
               info: ErrorInfo,
               file: StaticString,
               line: UInt) {
    self.errorCode = code
    underlying = underlyingError
        
    debugDetails = debugMessage
    // для ошибок ConditionalError 2 букв домена недостаточно, чтоб с достаточной точностью дифференцировать ошибки в логах.
    identitySuffix = Self.impFuncs.shortCodeOf(fileId: file)
    
    let (fileLineKey, fileLineValue) = Self.impFuncs.fileLine(fileId: file, line: line, domainShortCode: domainShortCode)
    primaryInfo = [fileLineKey: fileLineValue]
    
    self.info = info
  }
  
  public convenience init(code: ConditionalErrorCode,
                          debugMessage: String? = nil,
                          info: ErrorInfo = [:],
                          file: StaticString = #fileID,
                          line: UInt = #line) {
    self.init(code: code, debugMessage: debugMessage, underlyingError: nil, info: info, file: file, line: line)
  }
  
  public convenience init(code: ConditionalErrorCode,
                          underlyingError: (any BaseError)?,
                          debugMessage: String? = nil,
                          info: ErrorInfo = [:],
                          file: StaticString = #fileID,
                          line: UInt = #line) {
    self.init(code: code,
              debugMessage: debugMessage,
              underlyingError: underlyingError,
              info: info,
              file: file,
              line: line)
  }
}

extension ConditionalError {
  /// Example of call: indexOutOfBounds(index: index, array: allTariffs.count, arrayName: "All client tariffs")
  public static func indexOutOfBounds(index: Int,
                                      arrayCount: Int,
                                      file: StaticString = #fileID,
                                      line: UInt = #line) -> ConditionalError {
    let message = "invalid index \(index) for " + ". Array count: \(arrayCount)."
    return ConditionalError(code: .indexOutOfBounds,
                            debugMessage: message,
                            underlyingError: nil,
                            info: [:],
                            file: file,
                            line: line)
  }
  
  public static func unexpectedValue(_ value: any CustomStringConvertible,
                                     named valueName: String,
                                     file: StaticString = #fileID,
                                     line: UInt = #line) -> ConditionalError {
    let message = "Unexpected value '\(valueName)': \(value)"
    return ConditionalError(code: .unexpectedValue,
                            debugMessage: message,
                            underlyingError: nil,
                            info: [:],
                            file: file,
                            line: line)
  }
}

public enum ConditionalErrorCode: Int, BaseErrorCode {
  case valueOutOfRange = 2
  case missingObjectWithId = 1
  
  // MARK: - Sequence
  case indexOutOfBounds = 0
  case missingValueInSequence = 20
  case unexpectedSequenceCount = 21
  case unexpectedValueInSequence = 22
  case valueCollision = 51
  case duplicatedElement = 52
  case duplicatedObject = 53
  case duplicatedValue = 54
  
  // MARK: Unexpected
  case unexpectedNilValue = 30
  case unexpectedValue = 31
  case unexpectedNilObject = 32
  case unexpectedRange = 33
  case unexpectedEnumCase = 34
  case unexpectedType = 35
  case unexpectedState = 36
  case unexpectedEmptyString = 37
  
  case typeCastFailed = 40
  case valueConversionFailed = 41
  case objectInitFailed = 42
  case notEqualValues = 43
  case notEqualObjects = 44
  case notEqualElements = 45
  
  // MARK: Execution flow
  
  case invalidState = 70
  case inappropriateConditions = 71
  case unexpectedCodeEntrance = 72
  case excessOfLimit = 73
  
  case mainThreadViolation = 90
}
