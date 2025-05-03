//
//  BaseError.swift
//  swifty-kit
//
//  Created by Dmitriy Ignatyev on 14.12.2024.
//

internal import protocol SwiftyKit.DictionaryUnifyingProtocol
internal import protocol SwiftyKit.Namespacing
internal import protocol SwiftyKit.InformativeError
private import struct Collections.OrderedDictionary
private import FoundationExtensions
import Algorithms

/// Base error provide detailed information in comparison with Swift.Error.
/// Base errors can be chained with each other.
///
/// The most top error provide localized message, details and errors chain, such as JM16-ME15@FCA-AL4@CUR or NE2-NM10. These chains consists from short codes
/// of each underlying error.
/// If error can not be handled in a layer, it is propagated to a higher level where it is possible to handle it.
/// If error can not be handled In a higher level then it can be wrapped by another error, which on its own can be enriched with more context information and details and finaly
/// loged.
public protocol BaseError: LocalizedError, InformativeError, CustomNSError, CustomStringConvertible, CustomDebugStringConvertible {
  // MARK: - Properties that must be implemented:
  
  /// Двухбуквенный код домена. Example: AE
  var domainShortCode: String { get }
  
  /// Underlying error
  var underlying: (any BaseError)? { get }
  
  /// Словарь с дополнительной информацией. Здесь содержится важная информация, которую нужно видеть в DEBUG сборках
  /// при показе ошибок. Например URL запроса или название проперти, которую не удалось замапить.
  var primaryInfo: ErrorInfo { get }
  
  /// [String: Any].Type has one benefit prior to Ordered / Sorted Dictionary – keys have different order.
  /// if logging system has strong limit on number of key-value pairs can be logged and drops ones that out of limit, it is not so big problem when keys have different order.
  /// Each log in such situation will have different key-value pairs,  though not full. From this mosaic full picture can be restored.
  var info: ErrorInfo { get }
  
  /// The same as Localized Description
  var localizedMessage: String { get }
  
  /// Признак, будет ли текст ошибки содержать цепочку кодов. Например: NE0-ME12-JM3
  var providesCodeChain: Bool { get }
  
  // MARK: - Properties that have default Imp (but can be reimplemented):
  
  /// Числовой код ошибки. Нужен и используется для логирования. Название сделано таким же, как и у нативной NSError.
  /// Реализовывать какое-либо поведение, основываясь на значении этой проперти не следует, т.к
  /// одно и то же значение (например 2) у разных ошибок имеет разные смыслы.
  var code: Int { get }
    
  /// Некоторые ошибки могут иметь значение в этой проперти. Это имеет смысл, однако, не для всех Типов ошибок.
  ///
  /// Например, ошибка маппинга с определённым кодом может встречаться весьма часто.
  /// В нонфаталах может быть проблематично вычленить все места где она встретилась.  В таком случае имеет смысл разделить её по названию
  ///
  /// Ещё пример: для ошибок ConditionalError 2 букв домена недостаточно, чтоб с достаточной точностью дифференцировать ошибки в логах.
  /// ConditionalError – наиболее часто используемая ошибка. Её коды не означают что-то конкретное, как например коды HttpStatusError.
  /// Эти коды можно рассматривать как группы типичных проблем, которые возникают. Поэтому добавляем короткий код файла.
  var identitySuffix: String? { get }
  
  /// Human readable debug details
  /// Дополнительная информация для разработки, которая не будет отображаться пользователю.
  var debugDetails: String? { get }
  
  /// В большинстве случаев нужна именно дефолтная имплементация.
  /// Однако бывают случаи, когда полная цепочка кодов не подходит для логирования и мониторинга в нонфаталах.
  ///
  /// Рассмотрим на примере ошибки оплаты. Ошибка оплаты может в качестве underlying ошибки иметь NetworkError со всевозможными статус кодами.
  /// Получится большое кол-во цепочек вроде PE14-NE0-NU999, PE14-NE1-HT503, PE14-NE2-ME14 ...
  /// В таких случаях можно переопределить shortCodesChain, чтобы в нонфаталах отображался только `PE14`
  var shortCodesChain: String { get }
}

// MARK: - CustomNSError Default Imp

// Для случаев, когда ошибка передаётся как Error, делаем дефолтную реализацию, чтоб нативные _domain и _code возвращали
// корректное значение. Аналогично и с полями NSError.code, NSError.domain, NSError.userInfo

extension BaseError {
  public static var errorDomain: String { "\(Self.self)" }
  
  /// The error code within the given domain.
  public var errorCode: Int { code }
  
  public var errorUserInfo: [String: Any] { summaryErrorInfo.asStringDict } // TODO: StringDict or raw errorInfo.storage?
  
  public var domain: String { Self.errorDomain }
}

// MARK: - LocalizedError Default Imp

extension BaseError {
  /// Default implementation, returns localizedMessage.
  public var errorDescription: String? {
    description(showShortChain: providesCodeChain)
  }
}

// MARK: - CustomStringConvertible & CustomDebugStringConvertible

extension BaseError {
  public var description: String {
    description(showShortChain: providesCodeChain)
  }

  public var debugDescription: String {
    #if DEBUG
      return description(showShortChain: true) + "  " + techInfo
    #else
      // Для подстраховки на случай, если сломается логика показа в UI, в релизных сборках не добавляем techInfo
      return description(showShortChain: true) + "\n" + "#"
    #endif
  }
}

// MARK: - extension Imps (то что не объявлено в протоколе, и будет всегда иметь единую стандартную имплементацию)

extension BaseError {
  /// Короткий код ошибки. Является склейкой из domainShortCode и code.
  /// Can not be overriden
  ///
  /// Example: AE14
  public var shortCode: String {
    let shortCode = [domainShortCode, "\(code)", identitySuffix.map { "@" + $0 }].compacted().joined()
    return code >= 0 ? shortCode : "`\(shortCode)`"
  }
  
  /// Example: ApiServiceError.unretriable
  public var fullName: String {
    Self.errorDomain + "." + ((self as? any ConcreteBaseError)?.errorCode.codeName ?? "\(code)")
  }
  
  public var fullNamesChain: String {
    fullName + (underlying.map { " - " + $0.fullNamesChain } ?? "")
  }
}

// MARK: - Protocol Requirements Default Imps

extension BaseError { // MARK: Logging
  public var shortCodesChain: String { Self.shortCodesChain(for: self) }
  
  public static func shortCodesChain(for error: some BaseError) -> String {
    // Рекурсивно вызывает сам себя
    error.shortCode + (error.underlying.map { "-" + shortCodesChain(for: $0) } ?? "")
  }
}

extension BaseError { // MARK: optional fields that can be implemented, but are omited by default
  public var identitySuffix: String? { nil }
  
  public var debugDetails: String? { nil }
}

// MARK: - Private helper methods

extension BaseError {
  /// Текст ошибки + цепочка кодов, если она должна быть показана
  private func description(showShortChain: Bool) -> String {
    let text: String = if showShortChain {
      localizedMessage + "\n\n" + "Код ошибки:" + "\n" + Self.shortCodesChain(for: self)
    } else {
      localizedMessage
    }
    return text
  }
  
  /// Полная цепочка + версия приложения + номер билда
  private var techInfo: String {
    let appVersion = Bundle.mainAppVersionString
    let buildNumber = Bundle.mainAppBuildNumberString
    let version = "Версия: " + appVersion + "(" + buildNumber + ")"
    let rootError = rootError
    
    let deepestMessage: String = if localizedMessage != rootError.localizedMessage {
      "(" + rootError.localizedMessage + ")"
    } else {
      ""
    }
    
    let debugDetails = rootError.debugDetails ?? debugDetails
    
    let infoDescription: String
    do {
      let primaryInfoDict = _summaryPrimaryInfo
      let components = primaryInfoDict.map { key, value -> String in "\"\(key)\": \(value)" }
      infoDescription = "[" + components.joined(separator: ", ") + "]"
    }
    
    let debugDetailsString = (debugDetails.map { "\n\($0)" } ?? "")
    let userInfoString = (!infoDescription.isEmpty ? "\n" + infoDescription : "")
    let deepestMessageString = !deepestMessage.isEmpty ? deepestMessage : ""
    let fullNamesChainString = "\n" + fullNamesChain
    
    let info = [version, debugDetailsString, userInfoString, deepestMessageString, fullNamesChainString].joined()
    
    return info
  }
  
  /// Самая глубокая ошибка.
  /// self is returned when underlying is nil
  private var rootError: any BaseError {
    underlying?.rootError ?? self
  }
}

// MARK: - Summary Error Info

extension BaseError {
  /// У самой глубокой ошибки будет индекс 0.
  private var depthIndex: UInt {
    if let underlyingIndex = underlying?.depthIndex {
      underlyingIndex + 1
    } else {
      0
    }
  }
  
  /// userInfo, собранный из всей цепочки ошибок
  private var _summaryInfo: [String: any ErrorInfo.ValueType] {
    var info = info
    info.add(key: "\(shortCode)_debugDetails", optionalValue: debugDetails)
    
    let underlyingInfo = (underlying?._summaryInfo ?? [:])
    
    lazy var depthIndex = depthIndex
//    let summary = Self.impFuncs.mergeInfo(info.storage,
//                                          onDepthWithIndex: depthIndex,
//                                          errorDomainShortCode: domainShortCode,
//                                          errorCode: code,
//                                          withUnderlying: underlyingInfo)
//    return summary
    // TODO: - .
    fatalError()
  }
  
  /// primaryUserInfo, собранный из всей цепочки ошибок
  private var _summaryPrimaryInfo: OrderedDictionary<String, any ErrorInfo.ValueType> {
    let underlyingInfo = (underlying?._summaryPrimaryInfo ?? [:])
    
    lazy var depthIndex = depthIndex
//    let summary = Self.impFuncs.mergeInfo(primaryInfo.storage,
//                                          onDepthWithIndex: depthIndex,
//                                          errorDomainShortCode: domainShortCode,
//                                          errorCode: code,
//                                          withUnderlying: underlyingInfo)
//    return summary
    // TODO: - .
    fatalError()
  }
  
  /// userInfo + primaryUserInfo, собранные из всей цепочки ошибок
  public var summaryErrorInfo: ErrorInfo { // TODO: - ? make opaque type
//    let summary = Self.impFuncs.mergeSummaryErrorInfo(summaryPrimaryInfo: _summaryPrimaryInfo,
//                                                      summarySecondaryInfo: _summaryInfo)
//    return ErrorInfo(storage: summary)
    // TODO: - .
    fatalError()
  }
}

// MARK: - Concrete BaseError

public protocol BaseErrorCode: RawRepresentable, Sendable where RawValue == Int {}

extension BaseErrorCode {
  /// Example: "secureConnectionFailed"
  fileprivate var codeName: String {
    String(describing: self)
  }
}

/// ConcreteBaseError is protocol which concrete Type conforms to.
public protocol ConcreteBaseError: BaseError {
  associatedtype ErrorCode: BaseErrorCode
  
  var errorCode: ErrorCode { get }
}

extension ConcreteBaseError {
  // MARK: Default Imp
  
  public var code: Int { errorCode.rawValue }
}

extension KeyPath {
  /// https://github.com/apple/swift-evolution/blob/main/proposals/0369-add-customdebugdescription-conformance-to-anykeypath.md
  @inlinable
  internal func asErrorInfoKeyString() -> String {
    String(reflecting: self)
  }
}

// MARK: - Helper Methods (вспомогательные методы для имплементации конкретных типов)

extension BaseError {
  public static var infoKeys: BaseErrorUserInfoKey.Type { BaseErrorUserInfoKey.self }
  
  public static var impFuncs: BaseErrorImpFunctions.Type { BaseErrorImpFunctions.self }
}

// MARK: - Reusable Keys

public enum BaseErrorUserInfoKey: Namespacing { // TODO: - use ErrroInfoKey instead
  public static let requestURLKey = "requestURL"
  
  public static let decodingDateKey = "decodingDate"
  
  public static let typeTKey = "T.Type"
}

// MARK: - Reusable Functions

public enum BaseErrorImpFunctions: Namespacing {}

// MARK: Merge UserInfo

extension BaseErrorImpFunctions { // MARK: fileprivate usage only
  /// Для summaryUserInfo и summaryPrimaryUserInfo
  fileprivate static func mergeInfo<Dict, V>(_ lhs: Dict,
                                             onDepthWithIndex depthIndex: @autoclosure () -> UInt,
                                             errorDomainShortCode: String,
                                             errorCode: Int,
                                             withUnderlying rhs: Dict) -> Dict
    where Dict: DictionaryUnifyingProtocol<String, V> {
    var info = rhs
    
    keyValueLoop: for (key, value) in lhs {
      if let existingValue = info[key] {
        guard !Self.isApproximatelyEqual(existingValue, value) else {
          continue keyValueLoop // если значения равны, оставляем в userInfo значение которое уже в нём есть
        }
        
        // Возникновение коллизий маловероятно. Если оно всё же произошло - меняем ключ,
        // чтобы понять на каком участке цепочки возникла коллизия.
        // Например, если возникла коллизия по ключу "decodingDate", получится такой порядок модификации ключа:
        // decodingDate ->
        var modifiedKey = errorDomainShortCode + "\(errorCode)_" + key // JM16_decodingDate
        var collisionsCounter: Int = 0
        while let existingValue2 = info[modifiedKey] {
          if Self.isApproximatelyEqual(existingValue2, value) {
            // если по измененному ключу снова коллизия но значения равны, оставляем в userInfo значение которое уже в нём есть
            continue keyValueLoop
          } else {
            switch collisionsCounter {
            case 0: modifiedKey += "^idx\(depthIndex())" // JM16_decodingDate^idx1
            default: modifiedKey += "_\(depthIndex())" // JM16_decodingDate^idx1_1  JM16_decodingDate^idx1_1_1 ...
            }
            collisionsCounter += 1
          }
        }
      
        info[modifiedKey] = value
      } else {
        info[key] = value
      }
    } // end keyValueLoop
    
    return info
  }
  
  /// Сделана для использования в одном месте – при создании summaryErrorInfo,
  /// когда мёржатся 2 ранее смёрженных словаря: summaryPrimaryUserInfo и summarySecondaryUserInfo
  fileprivate static func mergeSummaryErrorInfo(summaryPrimaryInfo: OrderedDictionary<String, any ErrorInfo.ValueType>,
                                                summarySecondaryInfo: [String: any ErrorInfo.ValueType])
    -> [String: any ErrorInfo.ValueType] {
    var info = summarySecondaryInfo
    
//    for (key, value) in summaryPrimaryInfo {
//      _addResolvingKeyCollisions(key: key,
//                                 value: value,
//                                 firstSuffix: { "_r" + BaseErrorImpFunctions.randomSuffix() },
//                                 otherSuffix: BaseErrorImpFunctions.randomSuffix,
//                                 to: &info)
//    } // end keyValueLoop
      // TODO: - .
    
    return info
  }
  
  /// Рандомный 3 значный суффикс из 2 заглавных букв английского алфавита и 3 цифр.
  /// В сумме это 6760 комбинаций.
  internal static func randomSuffix() -> String {
    String([String.englishAlphabetUppercasedString.randomElement(),
            String.englishAlphabetUppercasedString.randomElement()]) + "\(UInt.random(in: 1...9))"
  }
}
