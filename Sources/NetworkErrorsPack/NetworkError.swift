//
//  NetworkError.swift
//  swifty-kit
//
//  Created by Dmitriy Ignatyev on 15.12.2024.
//

/// ApiError имеет двойственную природу.
/// С одной стороны, это отдельный тип ошибки. Если его передавать как объект Типа BaseError, то детали будут скрыты.
///
/// С другой стороны, это обёртка вокруг других сетевых ошибок. Если его передавать как объект Типа NetworkError, то можно
/// получить доступ к типизированным underlying-ошибкам и их типизированным кодам. Это может быть полезно для
/// реализации нужного поведения.
/// Например, код 401 служит для сетевого слоя сигналом о том, что требуется обновить access token.
public enum NetworkErrorGeneric<LibError: BaseError, Response: Sendable>: ConcreteBaseError {
  /// NSURLErrorDomain Errors
  case sessionError(error: LibError, response: Response?)
  
  case httpStatusError(error: HttpStatusError, response: Response)
  
  /// Ошибки маппинга данных
  case mappingError(NetworkMappingError, response: Response)
  
  /// Другие ошибки
  case unintendedError(any BaseError)
  
  // MARK: ConcreteBaseError Imp
  
  /// NE - Network Error
  public var domainShortCode: String { "NE" }
  
  public var errorCode: ErrorCode {
    switch self {
    case .sessionError: .urlSessionError
    case .httpStatusError: .httpStatusError
    case .mappingError: .mappingError
    case .unintendedError: .unintendedError
    }
  }
  
  public var underlying: (any BaseError)? { _underlying }
  
  public var primaryInfo: ErrorInfo { [:] }
  
  /// ApiError - это enum-обёртка, поэтому своего info у неё нет
  public var info: ErrorInfo { [:] }
  
  /// Convenience property. Returns the same value as 'underlying' property but not optional
  private var _underlying: any BaseError {
    switch self {
    case .sessionError(let underlyingError, _): underlyingError
    case .httpStatusError(let underlyingError, _): underlyingError
    case .mappingError(let underlyingError, _): underlyingError
    case .unintendedError(let underlyingError): underlyingError
    }
  }
  
  /// underlyingError.localizedMessage
  public var localizedMessage: String { _underlying.localizedMessage }
  
  /// underlyingError.providesCodeChain
  public var providesCodeChain: Bool { _underlying.providesCodeChain }
  
  public enum ErrorCode: Int, BaseErrorCode {
    case urlSessionError
    case httpStatusError
    case mappingError
    case unintendedError
  }
}

// MARK: - Convenience methods
