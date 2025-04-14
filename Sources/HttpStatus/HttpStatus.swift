//
//  HttpStatus.swift
//  swifty-kit
//
//  Created by Dmitriy Ignatyev on 15.12.2024.
//

@_spiOnly @_spi(SwiftyKitBuiltinTypes) private import struct SwiftyKit.TextError
@_spiOnly @_spi(SwiftyKitBuiltinFuncs) private import func SwiftyKit._getEnumCaseName

// Список кодов и их описания взяты с ресурса: https://www.restapitutorial.com/httpstatuscodes.html

// TODO: - сделать как структуру с вложенным Enum. Цель сделать static `allStdardCases` который берет allcases из енама
// и при этом оставить возможность для кастомных кодов.
// Сейчас для кастомных кодов есть case unknown(rawStatusCode: Int), однако он представлен только на уровне
// HttpStatusCode и его нет на уровне отдельно взятых ипов для 5хх / 4хх / 3хх ...
// Подумать как это лучше задизайтить.

// MARK: - Http Status Codes

/// Типизированная репрезентация http status кодов
public protocol HttpStatusCodeType: Hashable, Sendable, RawRepresentable, BitwiseCopyable, CustomStringConvertible
  where RawValue == Int {
  static var codesGroupRange: ClosedRange<Int> { get }
  
  init(httpStatusCode: Int) throws
}

extension HttpStatusCodeType {
  /// Default Imp
  public init(httpStatusCode: Int) throws {
    let range = Self.codesGroupRange
    guard range.contains(httpStatusCode) else {
      throw TextError(text: "httpStatusCode \(httpStatusCode) is outOfRange \(range)")
    }
    
    guard let instance = Self(rawValue: httpStatusCode) else {
      throw TextError(text: "\(Self.self) init failed with rawValue \(httpStatusCode)")
    }
    
    self = instance
  }
  
  public static func == (lhs: Self, rhs: some HttpStatusCodeType) -> Bool {
    lhs.rawValue == rhs.rawValue
  }
}

extension HttpStatusCodeType {
  /// Пример: "500 internalServerError"
  fileprivate var defaultCaseIterableStatusCodeDescription: String {
    [String(rawValue), " ", _getEnumCaseName(for: self) ?? ""].joined()
  }
}

public enum HttpStatusCode: HttpStatusCodeType {
  public static let codesGroupRange = Http1xxStatusCode.codesGroupRange.lowerBound...Http5xxStatusCode.codesGroupRange.upperBound
  
  public var description: String {
    switch self {
    case .status1xx(let statusCode): String(describing: statusCode)
    case .status2xx(let statusCode): String(describing: statusCode)
    case .status3xx(let statusCode): String(describing: statusCode)
    case .status4xx(let statusCode): String(describing: statusCode)
    case .status5xx(let statusCode): String(describing: statusCode)
    case .unknown(let rawStatusCode): String(rawStatusCode) + " unknown"
    }
  }
  
  case status1xx(Http1xxStatusCode)
  case status2xx(Http2xxStatusCode)
  case status3xx(Http3xxStatusCode)
  case status4xx(Http4xxStatusCode)
  case status5xx(Http5xxStatusCode)
  case unknown(rawStatusCode: Int)
  
  public init?(rawValue: Int) {
    if let status500 = Http5xxStatusCode(rawValue: rawValue) {
      self = .status5xx(status500)
    } else if let status400 = Http4xxStatusCode(rawValue: rawValue) {
      self = .status4xx(status400)
    } else if let status300 = Http3xxStatusCode(rawValue: rawValue) {
      self = .status3xx(status300)
    } else if let status200 = Http2xxStatusCode(rawValue: rawValue) {
      self = .status2xx(status200)
    } else if let status100 = Http1xxStatusCode(rawValue: rawValue) {
      self = .status1xx(status100)
    } else {
      return nil
    }
  }
  
  public init(httpStatusCode: Int) {
    if let instance = Self(rawValue: httpStatusCode) {
      self = instance
    } else {
      self = .unknown(rawStatusCode: httpStatusCode)
    }
  }
  
  public var rawValue: Int {
    switch self {
    case .status1xx(let statusCode): statusCode.rawValue
    case .status2xx(let statusCode): statusCode.rawValue
    case .status3xx(let statusCode): statusCode.rawValue
    case .status4xx(let statusCode): statusCode.rawValue
    case .status5xx(let statusCode): statusCode.rawValue
    case .unknown(let rawStatusCode): rawStatusCode
    }
  }
}

extension HttpStatusCode {
  // ⚠️ @iDmitriyy
  // TODO: - revision: may be use OrderedSet instead of separate Array & Set properties
  // it is both effective for memory consumption and has right semantics
  
//  public static let _codes1xx: OrderedSet<Http1xxStatusCode> = OrderedSet(Http1xxStatusCode.allCases)
//  public static let _codes2xx: OrderedSet<Http2xxStatusCode> = OrderedSet(Http2xxStatusCode.allCases)
//  public static let _codes3xx: OrderedSet<Http3xxStatusCode> = OrderedSet(Http3xxStatusCode.allCases)
//  public static let _codes4xx: OrderedSet<Http4xxStatusCode> = OrderedSet(Http4xxStatusCode.allCases)
//  public static let _codes5xx: OrderedSet<Http5xxStatusCode> = OrderedSet(Http5xxStatusCode.allCases)
//  
//  public static let _allCases: [Self] = {
//    var allCodes: [Self] = []
//    allCodes.reserveCapacity(_codes1xx.count + _codes2xx.count + _codes3xx.count + _codes4xx.count + _codes5xx.count)
//    
//    allCodes.append(contentsOf: codes1xx)
//    allCodes.append(contentsOf: codes2xx)
//    allCodes.append(contentsOf: codes3xx)
//    allCodes.append(contentsOf: codes4xx)
//    allCodes.append(contentsOf: codes5xx)
//    
//    return allCodes
//  }()
  
  public static let codes1xx = Http1xxStatusCode.allCases.map { Self.status1xx($0) }
  public static let codes2xx = Http2xxStatusCode.allCases.map { Self.status2xx($0) }
  public static let codes3xx = Http3xxStatusCode.allCases.map { Self.status3xx($0) }
  public static let codes4xx = Http4xxStatusCode.allCases.map { Self.status4xx($0) }
  public static let codes5xx = Http5xxStatusCode.allCases.map { Self.status5xx($0) }
  
  public static let allCases: [Self] = {
    var allCodes: [Self] = []
    allCodes.reserveCapacity(codes1xx.count + codes2xx.count + codes3xx.count + codes4xx.count + codes5xx.count)
    
    allCodes.append(contentsOf: codes1xx)
    allCodes.append(contentsOf: codes2xx)
    allCodes.append(contentsOf: codes3xx)
    allCodes.append(contentsOf: codes4xx)
    allCodes.append(contentsOf: codes5xx)
    
    return allCodes
  }()
  
  public static let codes1xxSet = Set(codes1xx)
  public static let codes2xxSet = Set(codes2xx)
  public static let codes3xxSet = Set(codes3xx)
  public static let codes4xxSet = Set(codes4xx)
  public static let codes5xxSet = Set(codes5xx)
  
  public static let allCasesSet: Set<Self> = Set(allCases)
}

/// 5xx (Server Error): The server failed to fulfill an apparently valid request
public enum Http5xxStatusCode: Int, HttpStatusCodeType, CaseIterable {
  public static let codesGroupRange = 500...599
  
  public var description: String { defaultCaseIterableStatusCodeDescription }
  
  /// 500, внутренняя ошибка сервера
  case internalServerError = 500
  
  /// 501, не реализовано
  case notImplemented = 501
  
  /// 502, плохой, ошибочный шлюз
  case badGateway = 502
  
  /// 503, сервис недоступен
  case serviceUnavailable = 503
  
  /// 504, шлюз не отвечает
  case gatewayTimeout = 504
  
  /// 505, версия HTTP не поддерживается
  case httpVersionNotSupported = 505
  
  /// 506, вариант тоже проводит согласование
  case variantAlsoNegotiates = 506
  
  /// 507, переполнение хранилища
  case insufficientStorage = 507
  
  /// 508, обнаружено бесконечное перенаправление
  case loopDetected = 508
  
  /// 509, исчерпана пропускная ширина канала
  case bandwidthLimitExceeded = 509
  
  /** 510, не расширено. ...otherwise the client MAY present any entity included in the 510 response to the user,
   since that entity may include relevant diagnostic information. */
  case notExtended = 510
  
  /// 511, требуется сетевая аутентификация (смысл сильно отличается от ошибок 401, 403 и 407)
  case networkAuthenticationReq = 511
  
  /// 599, Network connect timeout error
  case timeOut = 599
}

/// 4xx (Client Error): The request contains bad syntax or cannot be fulfilled
public enum Http4xxStatusCode: Int, HttpStatusCodeType, CaseIterable {
  public static let codesGroupRange = 400...499
  
  public var description: String { defaultCaseIterableStatusCodeDescription }
  
  /// 400, плохой, неверный запрос
  case badRequest = 400
  
  /// 401, не авторизован (не представился).
  /// При рефреше токена, если сервер 3 раза возвращает 401 ошибку, то наш сетевой слой прекратит попытки обновить токен
  /// и вернёт ошибку 403
  case unauthorized = 401
  
  /// 402, необходима оплата»
  case paymentRequired = 402
  
  /// 403, запрещено (не уполномочен). The server understood the request, but is refusing to fulfill it. Authorization will
  /// not help and the request SHOULD NOT be repeated.
  case forbidden = 403
  
  /// 404, не найдено
  case notFound = 404
  
  /// 405, метод не поддерживается
  case methodNotAllowed = 405
  
  /// 406, неприемлемо
  case notAcceptable = 406
  
  /// 407, необходима аутентификация прокси (аналогична 401 только через прокси)
  case proxyAuthenticationRequired = 407
  
  /// 408, истекло время ожидания
  case requestTimeout = 408
  
  /// 409, конфликт
  case conflict = 409
  
  /// 410, удалён
  case gone = 410
  
  /// 411, необходима длина
  case lengthRequired = 411
  
  /// 412, условие ложно
  case preconditionFailed = 412
  
  /// 413, полезная нагрузка слишком велика
  case payloadTooLarge = 413
  
  /// 414, URI слишком длинный
  case uriTooLong = 414
  
  /// 415, неподдерживаемый тип данных
  case unsupportedMediaType = 415
  
  /// 416, диапазон недостижим
  case rangeNotSatisfiable = 416
  
  /// 417, ожидание не удалось
  case expectationFailed = 417
  
  /// 418, я — чайник»
  case iAmTeapot = 418
  
  /// 419, обычно ошибка проверки CSRF
  case authenticationTimeout = 419
  
  /// 421, запрос был перенаправлен на сервер, не способный дать ответ
  case misdirectedRequest = 421
  
  /// 422, необрабатываемый экземпляр
  case unprocessableEntity = 422
  
  /// 423, заблокировано
  case locked = 423
  
  /// 424, невыполненная зависимость
  case failedDependency = 424
  
  /// 426, необходимо обновление
  case upgradeRequired = 426
  
  /// 428, необходимо предусловие
  case preconditionRequired = 428
  
  /// 429, слишком много запросов
  case tooManyRequests = 429
  
  /// 431, поля заголовка запроса слишком большие
  case requestHeaderFieldsTooLarge = 431
  
  /// 449, повторить с
  case retryWith = 449
  
  /// 451, недоступно по юридическим причинам
  case unavailableForLegalReasons = 451
  
  /// 499, клиент закрыл соединение
  case clientClosedRequest = 499
}

/// 3xx (Redirection): Further action needs to be taken in order to complete the request
public enum Http3xxStatusCode: Int, HttpStatusCodeType, CaseIterable {
  public static let codesGroupRange = 300...399
  
  public var description: String { defaultCaseIterableStatusCodeDescription }
  
  /// 300, множество выборов
  case multipleChoices = 300
  
  /// 301, перемещено навсегда
  case movedPermanently = 301
  
  /// 302, найдено
  case found = 302
  
  /// 303, смотреть другое
  case seeOther = 303
  
  /// 304, не изменялось
  case notModified = 304
  
  /// 305, использовать прокси
  case useProxy = 305
  
  /// 306, зарезервировано (код использовался только в ранних спецификациях)
  case legacyReserved = 306
  
  /// 307, временное перенаправление
  case temporaryRedirect = 307
  
  /// 308, постоянное перенаправление
  case permanentRedirect = 308
}

/// 2xx (Successful): The request was successfully received, understood, and accepted
///
/// Не все 200-е коды говорят об успешном ответе сервера. Некоторые следует расценивать как ошибку.
public enum Http2xxStatusCode: Int, HttpStatusCodeType, CaseIterable {
  public static let codesGroupRange = 200...299
  
  public var description: String { defaultCaseIterableStatusCodeDescription }
  
  /// 200, хорошо
  case ok = 200
  
  /// 201, создано
  case created = 201
  
  /// 202, принято
  case accepted = 202
  
  /// 203, информация не авторитетна
  case nonAuthoritativeInformation = 203
  
  /// 204, нет содержимого
  case noContent = 204
  
  /// 205, сбросить содержимое
  case resetContent = 205
  
  /// 206, частичное содержимое
  case partialContent = 206
  
  /// 207, многостатусный
  case multiStatus = 207
  
  /// 208, уже сообщалось
  case alreadyReported = 208
  
  /// 226, использовано IM
  case imUsed = 226
}

/// 1xx (Informational): The request was received, continuing process
public enum Http1xxStatusCode: Int, HttpStatusCodeType, CaseIterable {
  public static let codesGroupRange = 100...199
  
  public var description: String { defaultCaseIterableStatusCodeDescription }
  
  /// 100, сервер удовлетворён начальными сведениями о запросе, клиент может продолжать пересылать заголовки
  case `continue` = 100
  
  /// 101, сервер выполняет требование клиента и переключает протоколы в соответствии с указанием, данным в поле заголовка Upgrade. Сервер отправляет
  /// заголовок ответа Upgrade, указывая протокол, на который он переключился
  case switching = 101
  
  /// 102, запрос принят, но на его обработку понадобится длительное время. Используется сервером, чтобы клиент не разорвал соединение из-за превышения
  /// времени ожидания. Клиент при получении такого ответа должен сбросить таймер и дожидаться следующей команды в обычном режиме
  case processing = 102
}
