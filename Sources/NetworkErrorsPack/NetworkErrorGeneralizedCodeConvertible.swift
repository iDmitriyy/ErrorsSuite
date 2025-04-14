//
//  NetworkErrorGeneralizedCodeConvertible.swift
//  swifty-kit
//
//  Created by Dmitriy Ignatyev on 15.12.2024.
//

import HttpStatus

/// Семейство кодов ошибок для Api-сервисов
public protocol NetworkErrorGeneralizedCodeConvertible: BaseErrorCode {
  var generalizedNetworkErrorCode: NetworkErrorGeneralizedCode { get }
  
  var errorLocalizedMessage: String { get }
  var shouldShowCodesChain: Bool { get }
}

extension NetworkErrorGeneralizedCodeConvertible {
  /// Default implementation
  public var errorLocalizedMessage: String {
    generalizedNetworkErrorCode.errorLocalizedMessage
  }
  
  /// Default implementation
  public var shouldShowCodesChain: Bool {
    generalizedNetworkErrorCode.shouldShowCodesChain
  }
}

extension NetworkErrorGeneric where LibError: ConcreteBaseError, LibError.ErrorCode: NetworkErrorGeneralizedCodeConvertible {
  public var generalizedNetworkErrorCode: NetworkErrorGeneralizedCode {
    switch self {
    case .sessionError(let nsUrlError, _): nsUrlError.errorCode.generalizedNetworkErrorCode
    case .mappingError(let mappingError, _): mappingError.errorCode.generalizedNetworkErrorCode
    case .httpStatusError(let httpStatusError, _): httpStatusError.errorCode.generalizedNetworkErrorCode
    case .unintendedError: .notRecoverable
    }
  }
}

// MARK: Implementations

extension URLSessionErrorCode: NetworkErrorGeneralizedCodeConvertible {
  public var generalizedNetworkErrorCode: NetworkErrorGeneralizedCode {
    switch self {
    case .unknown: .onceRetriable
    case .cancelled: .requestCancelled
    case .badURL: .clientNotRecoverable
    case .timeOut: .badNetworkAlwaysRetriable
    case .unsupportedURL: .clientNotRecoverable
    case .cannotFindHost: .badNetworkOnceRetriable
    case .cannotConnectToHost: .badNetworkOnceRetriable
    case .networkConnectionLost: .badNetworkAlwaysRetriable
    case .dNSLookupFailed: .badNetworkOnceRetriable
    case .httpTooManyRedirects: .notRecoverable
    case .resourceUnavailable: .notRecoverable
    case .notConnectedToInternet: .notConnectedToInternet
    case .redirectToNonExistentLocation: .serverNotRecoverable
    case .badServerResponse: .onceRetriable
    case .userCancelledAuthentication: .alwaysRetriable
    case .userAuthenticationRequired: .authenticationRequired
    case .zeroByteResource: .dataMapping
    case .cannotDecodeRawData: .dataMapping
    case .cannotDecodeContentData: .dataMapping
    case .cannotParseResponse: .dataMapping
    case .appTransportSecurityRequiresSecureConnection: .clientNotRecoverable
    case .fileDoesNotExist: .notRecoverable
    case .fileIsDirectory: .notRecoverable
    case .noPermissionsToReadFile: .clientNotRecoverable
    case .dataLengthExceedsMaximum: .onceRetriable
    case .fileOutsideSafeArea: .notRecoverable
      
    // MARK: SSL errors
    case .secureConnectionFailed: .onceRetriable
    case .serverCertificateHasBadDate: .serverNotRecoverable
    case .serverCertificateUntrusted: .serverNotRecoverable
    case .serverCertificateHasUnknownRoot: .serverNotRecoverable
    case .serverCertificateNotYetValid: .serverNotRecoverable
    case .clientCertificateRejected: .serverNotRecoverable
    case .clientCertificateRequired: .clientNotRecoverable
    case .cannotLoadFromNetwork: .onceRetriable
      
    // MARK: Download and file I/O errors
    case .cannotCreateFile: .alwaysRetriable
    case .cannotOpenFile: .alwaysRetriable
    case .cannotCloseFile: .alwaysRetriable
    case .cannotWriteToFile: .alwaysRetriable
    case .cannotRemoveFile: .alwaysRetriable
    case .cannotMoveFile: .alwaysRetriable
    case .downloadDecodingFailedMidStream: .clientNotRecoverable
    case .downloadDecodingFailedToComplete: .clientNotRecoverable
    case .internationalRoamingOff: .internationalRoamingOff
    case .callIsActive: .alwaysRetriable
    case .dataNotAllowed: .cellularLoadingNotAllowed
    case .requestBodyStreamExhausted: .clientNotRecoverable
    case .backgroundSessionRequiresSharedContainer: .clientNotRecoverable
    case .backgroundSessionInUseByAnotherProcess: .onceRetriable
    case .backgroundSessionWasDisconnected: .alwaysRetriable
    }
  }
}

extension NetworkMappingErrorCode: NetworkErrorGeneralizedCodeConvertible {
  public var generalizedNetworkErrorCode: NetworkErrorGeneralizedCode {
    .dataMapping
  }
}

extension HttpStatusCode: NetworkErrorGeneralizedCodeConvertible {
  public var generalizedNetworkErrorCode: NetworkErrorGeneralizedCode {
    switch self {
    case .status1xx(let statusCode): statusCode.generalizedNetworkErrorCode
    case .status2xx(let statusCode): statusCode.generalizedNetworkErrorCode
    case .status3xx(let statusCode): statusCode.generalizedNetworkErrorCode
    case .status4xx(let statusCode): statusCode.generalizedNetworkErrorCode
    case .status5xx(let statusCode): statusCode.generalizedNetworkErrorCode
    case .unknown: .notRecoverable
    }
  }
}

extension Http1xxStatusCode: NetworkErrorGeneralizedCodeConvertible {
  public var generalizedNetworkErrorCode: NetworkErrorGeneralizedCode {
    .serverNotRecoverable
  }
}

extension Http2xxStatusCode: NetworkErrorGeneralizedCodeConvertible {
  public var generalizedNetworkErrorCode: NetworkErrorGeneralizedCode {
    .onceRetriable
  }
}

extension Http3xxStatusCode: NetworkErrorGeneralizedCodeConvertible {
  public var generalizedNetworkErrorCode: NetworkErrorGeneralizedCode {
    .serverNotRecoverable
  }
}

extension Http4xxStatusCode: NetworkErrorGeneralizedCodeConvertible {
  /// 400-е ошибки, за несколькими исключениями, невосстановимые
  public var generalizedNetworkErrorCode: NetworkErrorGeneralizedCode {
    switch self {
    case .badRequest: .clientNotRecoverable
    case .unauthorized: .authenticationRequired
    case .paymentRequired: .notRecoverable
    case .forbidden: .authenticationRequired
    case .notFound: .notRecoverable
    case .methodNotAllowed: .notRecoverable
    case .notAcceptable: .notRecoverable
    case .proxyAuthenticationRequired: .authenticationRequired
    case .requestTimeout: .badNetworkOnceRetriable
    case .conflict: .notRecoverable
    case .gone: .notRecoverable
    case .lengthRequired: .notRecoverable
    case .preconditionFailed: .notRecoverable
    case .payloadTooLarge: .notRecoverable
    case .uriTooLong: .notRecoverable
    case .unsupportedMediaType: .notRecoverable
    case .rangeNotSatisfiable: .notRecoverable
    case .expectationFailed: .notRecoverable
    case .iAmTeapot: .notRecoverable
    case .authenticationTimeout: .onceRetriable
    case .misdirectedRequest: .notRecoverable
    case .unprocessableEntity: .notRecoverable
    case .locked: .notRecoverable
    case .failedDependency: .notRecoverable
    case .upgradeRequired: .notRecoverable
    case .preconditionRequired: .notRecoverable
    case .tooManyRequests: .onceRetriable
    case .requestHeaderFieldsTooLarge: .notRecoverable
    case .retryWith: .notRecoverable
    case .unavailableForLegalReasons: .notRecoverable
    case .clientClosedRequest: .alwaysRetriable
    }
  }
}

extension Http5xxStatusCode: NetworkErrorGeneralizedCodeConvertible {
  public var generalizedNetworkErrorCode: NetworkErrorGeneralizedCode {
    /// При всплеске ошибок службой мониторинга заводятся инциденты, поэтому частые ошибки можно сделать
    /// как .alwaysRetriable вместо .onceRetriable, чтоб юзеры писали меньше писем
    switch self {
    case .internalServerError: .alwaysRetriable
    case .notImplemented: .serverNotRecoverable
    case .badGateway: .onceRetriable
    case .serviceUnavailable: .alwaysRetriable
    case .gatewayTimeout: .alwaysRetriable
    case .httpVersionNotSupported: .serverNotRecoverable
    case .variantAlsoNegotiates: .serverNotRecoverable
    case .insufficientStorage: .serverNotRecoverable
    case .loopDetected: .onceRetriable
    case .bandwidthLimitExceeded: .alwaysRetriable
    case .notExtended: .serverNotRecoverable
    case .networkAuthenticationReq: .alwaysRetriable
    case .timeOut: .badNetworkAlwaysRetriable
    }
  }
}
