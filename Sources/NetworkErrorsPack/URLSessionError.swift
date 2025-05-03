//
//  URLSessionError.swift
//  swifty-kit
//
//  Created by Dmitriy Ignatyev on 15.12.2024.
//

import Foundation
private import SwiftyKit

public final class URLSessionError: ConcreteBaseError {
  public let domainShortCode: String = "NU" // NsUrl
  
  public let errorCode: URLSessionErrorCode
  
  /// Often nil, because NSUrlError is typically a root error.
  public let underlying: (any BaseError)?
  
  public let primaryInfo: ErrorInfo
  
  public let info: ErrorInfo
  
  public var domain: String { NSURLErrorDomain }
  
  public let localizedMessage: String
  
  public let providesCodeChain: Bool
  
  public init(errorCode: URLSessionErrorCode,
              underlying: (any BaseError)? = nil,
              primaryInfo: ErrorInfo = [:],
              info: ErrorInfo = [:],
              file: StaticString = #fileID,
              line: UInt = #line) {
    self.errorCode = errorCode
    self.underlying = underlying
    self.primaryInfo = primaryInfo
    
    let (fileLineKey, fileLineValue) = Self.impFuncs.fileLine(fileId: file, line: line, domainShortCode: domainShortCode)
    self.info = mutate(value: info) {
      $0[fileLineKey] = fileLineValue
    }
    
    localizedMessage = errorCode.errorLocalizedMessage
    providesCodeChain = errorCode.shouldShowCodesChain
  }
  
  public convenience init(nsError: NSError,
                          file: StaticString = #fileID,
                          line: UInt = #line) {
    var nsErrorInfo = nsError.userInfo
    var primaryErrorInfo: ErrorInfo = [:]
    
    primaryErrorInfo["failingURL"] =
      (nsErrorInfo[NSURLErrorFailingURLErrorKey] ?? nsErrorInfo[NSURLErrorFailingURLStringErrorKey])
        .map { prettyDescription(any: $0) }
    nsErrorInfo[NSURLErrorFailingURLErrorKey] = nil
    nsErrorInfo[NSURLErrorFailingURLStringErrorKey] = nil
    
    primaryErrorInfo["localizedDescription"] = nsErrorInfo[NSLocalizedDescriptionKey].map { prettyDescription(any: $0) }
    nsErrorInfo[NSLocalizedDescriptionKey] = nil
    
    do { // удаляем то что нам не нужно
      nsErrorInfo["_NSURLErrorFailingURLSessionTaskErrorKey"] = nil
      nsErrorInfo["_NSURLErrorRelatedURLSessionTaskErrorKey"] = nil
      nsErrorInfo[NSUnderlyingErrorKey] = nil
    }
    
    let code: URLSessionErrorCode
    if nsError.domain == NSURLErrorDomain, let errorCode = (try? URLSessionErrorCode(nsUrlErrorCode: nsError.code)) {
      code = errorCode
    } else {
      let message = "\(nsError.code). It is not handled by NSUrlErrorCode enumeration."
      nsErrorInfo["NSUrlError_Raw_Code"] = message
      nsErrorInfo["NSUrlError_Domain"] = nsError.domain
      code = .unknown
    }
    
    self.init(errorCode: code,
              underlying: nil,
              primaryInfo: primaryErrorInfo,
              info: ErrorInfo(legacyUserInfo: nsErrorInfo),
              file: file,
              line: line)
  }
}

extension URLSessionError {
  public func asNSError() -> NSError {
    NSError(domain: NSURLErrorDomain, code: code, userInfo: info.asStringDict)
  }
}

public enum URLSessionErrorCode: CaseIterable, BaseErrorCode {
  /// -1
  case unknown
  
  /// -999
  case cancelled
  
  /// -1000
  case badURL
  
  /// -1001
  case timeOut
  
  /// -1002
  case unsupportedURL
  
  /// -1003
  case cannotFindHost
  
  /// -1004 The host name for a URL couldn’t be resolved.
  case cannotConnectToHost
  
  /// -1005
  case networkConnectionLost
  
  /// -1006 This error code is no longer used. You should expect to handle NSURLErrorCannotFindHost instead
  case dNSLookupFailed
  
  /// -1007
  case httpTooManyRedirects
  
  /// -1008
  case resourceUnavailable
  
  /// -1009
  case notConnectedToInternet
  
  /// -1010
  case redirectToNonExistentLocation
  
  /// -1011 This is equivalent to the “500 Server Error” message sent by HTTP servers.
  case badServerResponse
  
  /// -1012
  case userCancelledAuthentication
  
  /// -1013 Authentication was required to access a resource.
  case userAuthenticationRequired
  
  /// -1014
  case zeroByteResource
  
  /// -1015
  case cannotDecodeRawData
  
  /// -1016
  case cannotDecodeContentData
  
  /// -1017 @available(iOS 9.0, *)
  case cannotParseResponse
  
  /// -1022
  case appTransportSecurityRequiresSecureConnection
  
  /// -1100
  case fileDoesNotExist
  
  /// -1101
  case fileIsDirectory
  
  /// -1102
  case noPermissionsToReadFile
  
  /// -1103 @available(iOS 2.0, *)
  case dataLengthExceedsMaximum
  
  /// -1104 @available(iOS 10.3, *)
  case fileOutsideSafeArea
  
  // MARK: - SSL errors
  
  /// -1200
  case secureConnectionFailed
  
  /// -1201
  case serverCertificateHasBadDate
  
  /// -1202
  case serverCertificateUntrusted
  
  /// -1203
  case serverCertificateHasUnknownRoot
  
  /// -1204
  case serverCertificateNotYetValid
  
  /// -1205
  case clientCertificateRejected
  
  /// -1206
  case clientCertificateRequired
  
  /// -2000 A properly formed URL couldn’t be handled by the framework. The most likely cause is that there is no
  /// available protocol handler for the URL.
  case cannotLoadFromNetwork
  
  // MARK: - Download and file I/O errors
  
  /// -3000
  case cannotCreateFile
  
  /// -3001
  case cannotOpenFile
  
  /// -3002
  case cannotCloseFile
  
  /// -3003
  case cannotWriteToFile
  
  /// -3004
  case cannotRemoveFile
  
  /// -3005
  case cannotMoveFile
  
  /// -3006
  case downloadDecodingFailedMidStream
  
  /// -3007
  case downloadDecodingFailedToComplete
  
  /// -1018 @available(iOS 3.0, *)
  case internationalRoamingOff
  
  /// -1019 @available(iOS 3.0, *). A connection was attempted while a phone call was active on a network that
  /// doesn’t support simultaneous phone and data communication, such as EDGE or GPRS.
  case callIsActive
  
  /// -1020 @available(iOS 3.0, *) The cellular network disallowed a connection.
  case dataNotAllowed
  
  /// -1021 @available(iOS 3.0, *) This impacts clients on iOS that send a POST request using a body stream but do
  /// not implement the NSURLSessionTaskDelegate delegate method URLSession:task:needNewBodyStream:
  case requestBodyStreamExhausted
  
  /// -995 @available(iOS 8.0, *)
  case backgroundSessionRequiresSharedContainer
  
  /// -996 @available(iOS 8.0, *) This error can occur when both an app and an app extension attempt to use a
  /// background session at the same time.
  case backgroundSessionInUseByAnotherProcess
  
  /// -997 @available(iOS 8.0, *)
  case backgroundSessionWasDisconnected
  
  public var rawValue: Int {
    nsUrlErrorCode
  }
  
  public init?(rawValue: Int) {
    try? self.init(nsUrlErrorCode: rawValue)
  }
  
  public init(nsUrlErrorCode: Int) throws {
    try self.init(value: nsUrlErrorCode, relatedTo: \.nsUrlErrorCode)
  }
  
  public var nsUrlErrorCode: Int {
    switch self {
    case .unknown: NSURLErrorUnknown
    case .cancelled: NSURLErrorCancelled
    case .badURL: NSURLErrorBadURL
    case .timeOut: NSURLErrorTimedOut
    case .unsupportedURL: NSURLErrorUnsupportedURL
    case .cannotFindHost: NSURLErrorCannotFindHost
    case .cannotConnectToHost: NSURLErrorCannotConnectToHost
    case .networkConnectionLost: NSURLErrorNetworkConnectionLost
    case .dNSLookupFailed: NSURLErrorDNSLookupFailed
    case .httpTooManyRedirects: NSURLErrorHTTPTooManyRedirects
    case .resourceUnavailable: NSURLErrorResourceUnavailable
    case .notConnectedToInternet: NSURLErrorNotConnectedToInternet
    case .redirectToNonExistentLocation: NSURLErrorRedirectToNonExistentLocation
    case .badServerResponse: NSURLErrorBadServerResponse
    case .userCancelledAuthentication: NSURLErrorUserCancelledAuthentication
    case .userAuthenticationRequired: NSURLErrorUserAuthenticationRequired
    case .zeroByteResource: NSURLErrorZeroByteResource
    case .cannotDecodeRawData: NSURLErrorCannotDecodeRawData
    case .cannotDecodeContentData: NSURLErrorCannotDecodeContentData
    case .cannotParseResponse: NSURLErrorCannotParseResponse
    case .appTransportSecurityRequiresSecureConnection: NSURLErrorAppTransportSecurityRequiresSecureConnection
    case .fileDoesNotExist: NSURLErrorFileDoesNotExist
    case .fileIsDirectory: NSURLErrorFileIsDirectory
    case .noPermissionsToReadFile: NSURLErrorNoPermissionsToReadFile
    case .dataLengthExceedsMaximum: NSURLErrorDataLengthExceedsMaximum
    case .fileOutsideSafeArea: NSURLErrorFileOutsideSafeArea
      
    // MARK: SSL errors
    case .secureConnectionFailed: NSURLErrorSecureConnectionFailed
    case .serverCertificateHasBadDate: NSURLErrorServerCertificateHasBadDate
    case .serverCertificateUntrusted: NSURLErrorServerCertificateUntrusted
    case .serverCertificateHasUnknownRoot: NSURLErrorServerCertificateHasUnknownRoot
    case .serverCertificateNotYetValid: NSURLErrorServerCertificateNotYetValid
    case .clientCertificateRejected: NSURLErrorClientCertificateRejected
    case .clientCertificateRequired: NSURLErrorClientCertificateRequired
    case .cannotLoadFromNetwork: NSURLErrorCannotLoadFromNetwork
      
    // MARK: Download and file I/O errors
    case .cannotCreateFile: NSURLErrorCannotCreateFile
    case .cannotOpenFile: NSURLErrorCannotOpenFile
    case .cannotCloseFile: NSURLErrorCannotCloseFile
    case .cannotWriteToFile: NSURLErrorCannotWriteToFile
    case .cannotRemoveFile: NSURLErrorCannotRemoveFile
    case .cannotMoveFile: NSURLErrorCannotMoveFile
    case .downloadDecodingFailedMidStream: NSURLErrorDownloadDecodingFailedMidStream
    case .downloadDecodingFailedToComplete: NSURLErrorDownloadDecodingFailedToComplete
      
    // MARK: Others
    case .internationalRoamingOff: NSURLErrorInternationalRoamingOff
    case .callIsActive: NSURLErrorCallIsActive
    case .dataNotAllowed: NSURLErrorDataNotAllowed
    case .requestBodyStreamExhausted: NSURLErrorRequestBodyStreamExhausted
    case .backgroundSessionRequiresSharedContainer: NSURLErrorBackgroundSessionRequiresSharedContainer
    case .backgroundSessionInUseByAnotherProcess: NSURLErrorBackgroundSessionInUseByAnotherProcess
    case .backgroundSessionWasDisconnected: NSURLErrorBackgroundSessionWasDisconnected
    }
  }
}
