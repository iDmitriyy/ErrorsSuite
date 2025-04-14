//
//  NetworkDomainableError.swift
//  swifty-kit
//
//  Created by Dmitriy Ignatyev on 15.12.2024.
//

// MARK: - Domain Meta Code

public protocol DomainCodeType: Sendable, CaseIterable, RawRepresentable where RawValue == String {}

/*
// MARK: - Network Domainable Error

/// Ошибка для случаев, в ответе сервера приходит ошибка в поле 'code'. Определённые в спецификации коды иногда важны для бизнес логики.
/// См. NetworkErrorDTO
public enum NetworkDomainableError<DomainCode: DomainCodeType>: ConcreteBaseError {
  case networkError(NetworkError)
  
  /// Доменная ошибка, которая возникла в недрах бэкэндах
  case domainError(BackendDomainError<DomainCode>, response: DataTaskHttpResponse)
  
  // MARK: ConcreteBaseError Imp
  
  /// AD - Api Domainable
  public var domainShortCode: String { "AD" }
  
  public var errorCode: ErrorCode {
    switch self {
    case .networkError: return .networkError
    case .domainError: return .domainError
    }
  }
  
  public var underlying: (any BaseError)? {
    switch self {
    case .networkError(let error): return error
    case .domainError(let error, _): return error
    }
  }
  
  public var primaryInfo: ErrorInfo { [:] }
  
  /// ApiServiceDomainableError - это enum-обёртка, поэтому своего userInfo у неё нет
  public var info: ErrorInfo { [:] }
  
  /// Provides underlying error localizedMessage
  public var localizedMessage: String {
    switch self {
    case .networkError(let error): return error.localizedMessage
    case .domainError(let error, _): return error.localizedMessage
    }
  }
  
  public var providesCodeChain: Bool {
    switch self {
    case .networkError(let error): return error.providesCodeChain
    case .domainError(let error, _): return error.providesCodeChain
    }
  }
  
  public enum ErrorCode: Int, BaseErrorCode {
    case networkError = 0
    case domainError = 1
  }
}

// MARK: Bidirectional conversion to and from NetworkError

extension NetworkDomainableError {
  public func asNetworkError() -> NetworkError {
    switch self {
    case .networkError(let networkError):
      return networkError
    case let .domainError(backendDomainError, response):
      return .httpStatusError(error: backendDomainError.httpStatusError, response: response)
    }
  }
  
  public init(networkError: NetworkError) {
    switch networkError {
    case let .httpStatusError(error, response):
      // Доменные ошибки приходят с бэкэнда для статус кодов 400 / 500.
      // Однако, ничего страшного, если мы будем обрабатывать ошибки с ответами с другими статус кодами.
      if let backendDomainError = BackendDomainError<DomainCode>(httpStatusError: error) {
        self = .domainError(backendDomainError, response: response)
      } else {
        self = .networkError(networkError)
      }
    case .urlSessionError, .mappingError, .unintendedError:
      self = .networkError(networkError)
    }
  }
}

// MARK: - Backend Domain Error

import HttpStatus

/// Доменные ошибки, которые приходят с бэкэнда.
/// Экзмепляр этой ошибки можно получить из HttpStatusError.
/// Основное назначение этой ошибки в том,  что она имеет типизированный DomainCode, с которым удобно работать.
public final class BackendDomainError<DomainCode: DomainCodeType>: ConcreteBaseError {
  public let domainShortCode: String = "BD" // Backend Domain
  
  public var errorCode: HttpStatusCode { httpStatusError.errorCode }
  
  fileprivate let httpStatusError: HttpStatusError
  
  public var  underlying: (any BaseError)? { httpStatusError }
  
  public let primaryInfo: ErrorInfo = [:]
  
  public let info: ErrorInfo
  
  public let localizedMessage: String
  
  public let providesCodeChain = false
  
  // MARK: Данные, которые приходят от бэка в случае ошибки:

  public let domainCode: DomainCode
  public let systemMessage: String
  
  /// - Parameters:
  ///   - localizedMessage: текст ошибки, который приходит с бэкнэда
  fileprivate init(httpStatusError: HttpStatusError,
                   domainCode: DomainCode,
                   localizedMessage: String,
                   systemMessage: String,
                   info: ErrorInfo = [:]) {
    self.httpStatusError = httpStatusError
    self.info = info
    
    self.localizedMessage = localizedMessage
    self.domainCode = domainCode
    self.systemMessage = systemMessage
  }
  
  convenience init?(httpStatusError: HttpStatusError) {
    if let codeRawValue = httpStatusError.domainCode, let domainCode = DomainCode(rawValue: codeRawValue) {
      self.init(httpStatusError: httpStatusError,
                domainCode: domainCode,
                localizedMessage: httpStatusError.localizedMessage,
                systemMessage: httpStatusError.systemMessage)
    } else {
      return nil
    }
  }
}

*/
