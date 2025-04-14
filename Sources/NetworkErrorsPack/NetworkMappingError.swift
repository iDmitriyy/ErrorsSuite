//
//  NetworkMappingError.swift
//  swifty-kit
//
//  Created by Dmitriy Ignatyev on 15.12.2024.
//

import Foundation
import Functions
import HttpStatus

/// Ошибка маппинга уровня сетевого слоя
public final class NetworkMappingError: ConcreteBaseError {
  public let domainShortCode: String = "NM"
  
  public let errorCode: NetworkMappingErrorCode
  
  /// Always nil, because MappingError is a root error
  public let underlying: (any BaseError)?
  
  public let primaryInfo: ErrorInfo
  
  public let info: ErrorInfo
  
  public let debugDetails: String?
  
  public let localizedMessage: String
  
  public let providesCodeChain: Bool
  
  public let identitySuffix: String?
  
  public init(errorCode: NetworkMappingErrorCode,
              debugMessage: String?,
              underlying: (any BaseError)?,
              primaryInfo: ErrorInfo = [:],
              info: ErrorInfo = [:],
              identity: String? = nil,
              file: StaticString = #fileID,
              line: UInt = #line) {
    self.errorCode = errorCode
    self.underlying = underlying
    identitySuffix = identity.map { Self.impFuncs.shortCodeOf(identity: $0) }
    debugDetails = debugMessage
    
    let (fileLineKey, fileLineValue) = Self.impFuncs.fileLine(fileId: file, line: line, domainShortCode: domainShortCode)
    self.primaryInfo = mutate(value: primaryInfo) {
      $0[fileLineKey] = fileLineValue
    }
    
    self.info = info
    
    localizedMessage = errorCode.errorLocalizedMessage
    providesCodeChain = errorCode.shouldShowCodesChain
  }
}

extension NetworkMappingError {
  /// - Parameters:
  ///   - codableError: error thrown by Decoder / Encoder
  public static func codable(codableError: any Error,
                             requestURL: String?,
                             statusCode: HttpStatusCode,
                             responseData: Data,
                             codableType: Any.Type,
                             useIdentity: Bool = true,
                             file: StaticString = #fileID,
                             line: UInt = #line) -> NetworkMappingError {
    var primaryErrorInfo: ErrorInfo = [:]
    primaryErrorInfo[Self.infoKeys.requestURLKey] = requestURL
    primaryErrorInfo["statusCode"] = String(describing: statusCode)
    
    var errorInfo: ErrorInfo = [:]
    errorInfo[Self.infoKeys.typeTKey] = "\(codableType)"
    
    Self.impFuncs.processCodableError(codableError, responseData: responseData, putInfoTo: &errorInfo)
    
    // пробуем скастить в BaseError. Это даст дополнительную информацию в логах
    return NetworkMappingError(errorCode: .decoding,
                               debugMessage: nil,
                               underlying: codableError as? any BaseError,
                               primaryInfo: primaryErrorInfo,
                               info: errorInfo,
                               identity: useIdentity ? "\(codableType)" : nil,
                               file: file,
                               line: line)
  }
}

public enum NetworkMappingErrorCode: Int, BaseErrorCode {
  case nilResponse = 0
  case nilData = 1
  case emptyData = 2
  case decoding = 10
  case encoding = 11
  case missingValueInSequence = 20
}
