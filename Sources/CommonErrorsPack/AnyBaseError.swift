//
//  AnyBaseError.swift
//  swifty-kit
//
//  Created by Dmitriy Ignatyev on 14.12.2024.
//

import Foundation

/// Wrapper for errors that are thrown / returned from third party SDKs.
public final class AnyBaseError: BaseError {
  public let fullName: String = String(describing: AnyBaseError.self)

  public let intCode: Int

  public let domainShortCode: String

  public let domain: String

  /// Will always be nil
  public let underlying: (any BaseError)?

  public let primaryInfo: ErrorInfo = [:]
  
  public let info: ErrorInfo

  public let localizedMessage: String

  public let debugDetails: String?
  
  public var providesCodeChain: Bool { underlying?.providesCodeChain ?? true }

  private init(code: Int,
               domain: String,
               underlying: (any BaseError)?,
               localizedMessage: String,
               debugDescription: String?,
               info: ErrorInfo) {
    self.intCode = code
    domainShortCode = domain
    self.domain = domain
    
    var info: ErrorInfo = info
    do {
      let keySuffix: String = "_" + domainShortCode + "\(code)"
      info["localizedMessage" + keySuffix] = localizedMessage
    }
    
    self.underlying = underlying
    self.info = info
    self.localizedMessage = localizedMessage
    self.debugDetails = debugDescription
  }
}

extension AnyBaseError {
  public convenience init(error: any Error, info: ErrorInfo = [:]) {
    if let baseError = error as? any BaseError {
      self.init(code: baseError.intCode,
                domain: baseError.domain,
                underlying: baseError,
                localizedMessage: baseError.localizedMessage,
                debugDescription: baseError.debugDetails,
                info: info)
    } else {
      var localInfo: ErrorInfo = [:]
      let underlyingError: (any BaseError)?
      if error is DecodingError || error is EncodingError {
        Self.impFuncs.processCodableError(error, responseData: nil, putInfoTo: &localInfo)
        underlyingError = nil
      } else {
        var errorUserInfo = (error._userInfo as? [String: Any]) ?? [:]
        
        if let nsUnderlyingError = errorUserInfo[NSUnderlyingErrorKey] as? any Error {
          underlyingError = AnyBaseError(error: nsUnderlyingError)
          errorUserInfo[NSUnderlyingErrorKey] = nil
        } else {
          underlyingError = nil
        }
        if let dictLocalizedDescription = errorUserInfo[NSLocalizedDescriptionKey] as? String,
           dictLocalizedDescription == error.localizedDescription {
          errorUserInfo[NSLocalizedDescriptionKey] = nil
        }
        ErrorInfo.merge(ErrorInfo(legacyUserInfo: errorUserInfo), to: &localInfo)
      }
      
      self.init(code: error._code,
                domain: error._domain,
                underlying: underlyingError,
                localizedMessage: error.localizedDescription,
                debugDescription: nil,
                info: .merged(localInfo, info))
    }
  }

  public convenience init(nsError: NSError) {
    var legacyInfo = nsError.userInfo

    let underlyingError: (any BaseError)?
    if let unerlyingNsError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
      underlyingError = AnyBaseError(nsError: unerlyingNsError)
      legacyInfo[NSUnderlyingErrorKey] = nil
    } else {
      underlyingError = nil
    }
    legacyInfo["\(nsError._domain) \(nsError._code) debugDescription"] = String(reflecting: nsError)

    self.init(code: nsError.code,
              domain: nsError.domain,
              underlying: underlyingError,
              localizedMessage: nsError.localizedDescription,
              debugDescription: nil,
              info: ErrorInfo(legacyUserInfo: legacyInfo))
  }
}
