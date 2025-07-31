//
//  ProcessCodableError.swift
//  errors-suite
//
//  Created by Dmitriy Ignatyev on 28/07/2025.
//

// MARK: - Process CodableError

extension BaseErrorImpFunctions {
  public static func processCodableError(_ codableError: any Error,
                                         responseData: Data?,
                                         putInfoTo outerErrorInfo: inout ErrorInfo) {
    var localInfo: ErrorInfo = [:]
    let codableErrorInfo: ErrorInfo
    defer {
      ErrorInfo.merge(localInfo, to: &outerErrorInfo)
      ErrorInfo.merge(codableErrorInfo, to: &outerErrorInfo)
    }
    
    func getCodableErrorInfo() -> ErrorInfo { ErrorInfo(legacyUserInfo: (codableError._userInfo as? [String: Any]) ?? [:]) }
    
    let debugMessage: (key: String, message: String)?
    if let decodingError = codableError as? DecodingError {
      debugMessage = ("DecodingError debugMessage", decodingError.humanReadableDescription)
      // Дата нужна, чтобы потом в логах бэка можно было найти полный json ответа
      localInfo[BaseErrorUserInfoKey.decodingDateKey] = Self.dateWithTimeZone
      switch decodingError {
      case .typeMismatch:
        break
      case .valueNotFound:
        break
      case .keyNotFound:
        break
      case .dataCorrupted:
        // В случае .dataCorrupted отправляем кусок ответа, чтоб было понятно что там приходит. Часто бэк отправляет html
        // вместо json'a при 500 ответах.
        if let responseData { Self.putDataAsString(responseData, to: &localInfo) }
      @unknown default:
        break
      }
      codableErrorInfo = getCodableErrorInfo()
    } else if let encodingError = codableError as? EncodingError {
      debugMessage = ("EncodingError debugMessage", encodingError.humanReadableDescription)
      codableErrorInfo = getCodableErrorInfo()
    } else if codableError is any BaseError {
      debugMessage = nil
      codableErrorInfo = [:]
    } else {
      // Improvements: этот код пересекается с обработкой в AnyBaseError
      // имеет смысл возвращать (any BaseError)?, если удалось скастить в BaseError или AnyBaseError, если ошибка не является
      // ни Codable ошибкой на BaseError Типом
      localInfo["raw_error_code"] = codableError._code
      localInfo["raw_error_domain"] = codableError._domain
      localInfo["raw_error_localized_description"] = codableError.localizedDescription
      debugMessage = ("raw_error_debugDescr", String(reflecting: codableError))
      codableErrorInfo = getCodableErrorInfo()
    }
    
    if let debugMessage { localInfo[debugMessage.key] = debugMessage.message }
  }
}
