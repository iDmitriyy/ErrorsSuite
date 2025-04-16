//
//  AppLinkError.swift
//  swifty-kit
//
//  Created by Dmitriy Ignatyev on 14.12.2024.
//

import struct Foundation.URL
private import SwiftyKit

/// Ошибка связанная с созданием URL'ов, DeepLink'ов и UniversalLink'ов.
public final class AppLinkError: ConcreteBaseError {
  public let domainShortCode: String = "AL"
  
  public let errorCode: ErrorCode
  
  public let underlying: (any BaseError)?
  
  public let primaryInfo: ErrorInfo
  
  public let info: ErrorInfo
  
  public let debugDetails: String?
  
  public let identitySuffix: String?
  
  public let localizedMessage: String
  
  public var providesCodeChain: Bool { true }
  
  public init(errorCode: ErrorCode,
              url: URL? = nil,
              localizedMessage: String? = nil,
              debugMessage: String? = nil,
              underlyingError: (any Error)? = nil,
              primaryInfo: ErrorInfo = [:],
              info: ErrorInfo = [:],
              file: StaticString = #fileID,
              line: UInt = #line) {
    self.errorCode = errorCode
    
    underlying = underlyingError.map { error -> any BaseError in
      (error as? any BaseError) ?? AnyBaseError(error: error)
    }
    
    let (fileLineKey, fileLineValue) = Self.impFuncs.fileLine(fileId: file, line: line, domainShortCode: domainShortCode)
    
    let _primaryInfo = mutate(value: ErrorInfo()) {
      $0[fileLineKey] = fileLineValue
      if let url {
        $0["url"] = url
      }
    }
    self.primaryInfo = ErrorInfo.merged(_primaryInfo, primaryInfo)
    
    self.info = info
    self.debugDetails = debugMessage
    identitySuffix = Self.impFuncs.shortCodeOf(fileId: file)
    
    let maybeLocalizedMessage = localizedMessage.flatMap { $0.trimmingWhitespacesAndNewlines().isEmpty ? nil : $0 }
    self.localizedMessage = maybeLocalizedMessage ?? errorCode.defaultLocalizedMessage
  }
  
  public enum ErrorCode: Int, BaseErrorCode {
    case urlFromStringFailed = 0
    case typeCastFailed = 2
    case foundationIncompatible = 3
    case invalidURL = 4
    
    case cantOpenURL = 10
    case cantOpenDeepLink = 11
    
    case unexpectedNilValue = 15
    case unexpectedNilURL = 16
    
    case cantCreateURLComponents = 20
    
    case missingScheme = 25
    case missingHost = 26
    case missingPath = 27
    
    case missingPathComponent = 30
    case missingQueryItem = 31
    
    case incorrectScheme = 40
    case incorrectHost = 41
    
    // MARK: Специфичны для парсинга DeepLink / UniversalLink

    case moreParamsThanPlaceholders = 50
    case morePlaceholdersThanParams = 51
    case noMatchingDiscriminant = 52
    
    // MARK: Others

    case notEqualURLs = 60
    
    case folderNotExists = 90
    case fileNotExists = 91
    
    fileprivate var defaultLocalizedMessage: String {
      switch self {
      case .urlFromStringFailed: "Не удалось преобразовать строку в URL"
      case .typeCastFailed: "Не удалось преобразовать Тип"
      case .foundationIncompatible: "Ссылка не совместима с Foundation.URL"
      case .invalidURL: "Невалидная ссылка"
      case .cantOpenURL: "Ссылка не может быть открыта"
      case .cantOpenDeepLink: "Не удалось открыть диплинк"
      case .unexpectedNilValue: "Неожиданное отсутствие значения"
      case .unexpectedNilURL: "Неожиданное отсутствие ссылки"
      case .cantCreateURLComponents: "Не удалось создать компоненты ссылки"
      case .missingScheme: "Отсутствует схема"
      case .missingHost: "Отсутствует хост"
      case .missingPath: "Отсутствует путь"
      case .missingPathComponent: "Отсутствует компонент пути"
      case .missingQueryItem: "Отсуствует ожидаемый QueryItem"
      case .incorrectScheme: "Некорректная схема"
      case .incorrectHost: "Некорректный хост"
      case .notEqualURLs: "Ссылки неэквивалентны"
      case .folderNotExists: "Папка не существует"
      case .fileNotExists: "Файл не существует"
      case .moreParamsThanPlaceholders,
           .morePlaceholdersThanParams,
           .noMatchingDiscriminant: "Не удалось обработать ссылку"
      }
    }
  }
}
