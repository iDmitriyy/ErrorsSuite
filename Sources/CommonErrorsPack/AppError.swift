//
//  AppError.swift
//  swifty-kit
//
//  Created by Dmitriy Ignatyev on 14.12.2024.
//

import func Functions.mutate

/// Внутренняя ошибка приложения. Подходит для случаев, когда её нужно показать пользователю.
/// По больше части предназначена для использования в Interactor'ах и иногда впровайдерах.
public final class AppError: ConcreteBaseError {
  public let domainShortCode: String = "AP"
  
  public let errorCode: ErrorCode
  
  /// Always nil, because MappingError is a root error
  public let underlying: (any BaseError)?
  
  public let primaryInfo: ErrorInfo
  
  public let info: ErrorInfo
  
  public let localizedMessage: String
  
  public var providesCodeChain: Bool { underlying?.providesCodeChain ?? false }
  
  private init(_errorCode: ErrorCode,
               localizedMessage: String,
               underlyingError: (any BaseError)?,
               info: ErrorInfo,
               file: StaticString,
               line: UInt) {
    errorCode = _errorCode
    underlying = underlyingError
    
    let (fileLineKey, fileLineValue) = Self.impFuncs.fileLine(fileId: file, line: line, domainShortCode: domainShortCode)
    primaryInfo = mutate(value: ErrorInfo()) {
      $0[fileLineKey] = fileLineValue
    }
        
    self.info = info
    
    self.localizedMessage = localizedMessage
  }
  
  public convenience init(errorCode: ErrorCode,
                          localizedMessage: String,
                          underlyingError: (any BaseError)? = nil,
                          info: ErrorInfo = [:],
                          file: StaticString = #fileID,
                          line: UInt = #line) {
    self.init(_errorCode: errorCode,
              localizedMessage: localizedMessage,
              underlyingError: underlyingError,
              info: info,
              file: file,
              line: line)
  }
  
  public enum ErrorCode: Int, BaseErrorCode {
    case userMessage = 0
    
    case unexpectedNilValue = 3
    case unexpectedValue = 4
    case unexpectedNilObject = 5
    
    case unexpectedEmptyArray = 10
    case invalidElementsCount = 11
    
    case outOfRange = 13
    
    case unwantedError = 20
    case unexpectedState = 21
    case overflowPrevented = 22
    // кейс добавлен в исследовательских целях, чтобы понять насколько часто приложение засыпает во время ожидания ответа
    // на запрос или декодинга полученных данных
    case sleepDueToRequest = 30
  }
}
