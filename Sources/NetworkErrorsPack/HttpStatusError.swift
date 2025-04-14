//
//  HttpStatusError.swift
//  swifty-kit
//
//  Created by Dmitriy Ignatyev on 15.12.2024.
//

import HttpStatus
import Functions

public final class HttpStatusError: ConcreteBaseError {
  public let domainShortCode: String = "HT" // Http
  
  public let errorCode: HttpStatusCode
  
  /// Always nil, because HttpError is a root error
  public let underlying: (any BaseError)?
  
  public let primaryInfo: ErrorInfo
  
  public let info: ErrorInfo
  
  /// Вернёт текст ошибки, если он пришёл с бэкэнда. Если с бэка текст ошибки не пришёл, вернёт underlyingError.localizedMessage
  public let localizedMessage: String
  
  public let providesCodeChain: Bool
  
  // MARK: Данные, которые приходят от бэка в случае ошибки:
  public let domainCode: String?
  public let systemMessage: String
  
  /// Ошибка для 400 / 500-х и других http статус кодов.
  /// - Parameters:
  ///   - domainCode: код ошибок бизнес логики, которые произошли на бэке. Например хотели изменить e-mail, но он уже привязан
  ///   к другому аккаунту. Эти строковые коды потом мапятся в enum'овые код ошибки NetworkDomainableError на конкретных
  ///   запросах, и используются в интеракторах.
  ///   - message: локализованный текст ошибки, который может прийти с бэкэнда. Если будет nil, то подставим дефолтный текст.
  ///   - systemMessage: дебаг информация внутренней работы бэка
  ///   - failingURLString: URL запроса, на котором возникла ошибка
  public init(errorCode: HttpStatusCode,
              domainCode: String?,
              message: String?,
              systemMessage: String,
              failingURLString: String?,
              primaryInfo: ErrorInfo = [:],
              info: ErrorInfo = [:],
              file: StaticString = #fileID,
              line: UInt = #line) {
    self.errorCode = errorCode
    underlying = nil
    
    self.primaryInfo = mutate(value: primaryInfo) {
      $0["url"] = failingURLString
      $0["statusCode"] = errorCode.rawValue
      $0["systemMessage"] = systemMessage
    }
    
    let (fileLineKey, fileLineValue) = Self.impFuncs.fileLine(fileId: file, line: line, domainShortCode: domainShortCode)
    self.info = mutate(value: info) {
      $0[fileLineKey] = fileLineValue
    }
    
    providesCodeChain = errorCode.shouldShowCodesChain
    
    self.localizedMessage = message ?? errorCode.errorLocalizedMessage
    self.domainCode = domainCode
    self.systemMessage = systemMessage
  }
}

extension HttpStatusCode: BaseErrorCode {}
