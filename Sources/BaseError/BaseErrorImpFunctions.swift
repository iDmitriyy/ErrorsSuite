//
//  BaseErrorImpFunctions.swift
//  swifty-kit
//
//  Created by Dmitriy Ignatyev on 14.12.2024.
//

private import struct Foundation.Data
private import struct Foundation.Date
private import struct Foundation.TimeZone
private import struct Foundation.Calendar
private import class Foundation.DateFormatter
private import FoundationExtensions

extension BaseErrorImpFunctions {
  /// 512
  public static let stringValMaxLength: Int = 512
  /// 50
  public static let dictKeyMaxLength: Int = 50
  
  /// Date.now() in `yyyyMMddTHHmmssxxx` format with .current timeZone
  public static var dateWithTimeZone: String {
    Date.now.string(withFormat: "yyyy-MM-dd'T'HH:mm:ssxxx", timeZone: .current, calendar: .current)
  }
}

extension Date {
  fileprivate func string(withFormat format: String, timeZone: TimeZone, calendar _: Calendar) -> String {
    var calendar = Calendar(identifier: .gregorian) // LocalDateGregorian.calendarIdentifier
    calendar.timeZone = timeZone
    
    let formatter = DateFormatter()
    formatter.dateFormat = format
    formatter.calendar = calendar
    formatter.timeZone = timeZone
    
    return formatter.string(from: self)
  }
}

extension BaseErrorImpFunctions {
  /// - Parameters:
  ///   - fileId: #fileID
  ///   - line: #line
  ///   - domainShortCode: domainShortCode of BaseError
  /// - Returns: key-value tuple  for error info dict. Example: fileLineKey – "#BE_file_line", fileLineValue – "ModuleName.FileName, line: 4"
  public static func fileLine(fileId: StaticString,
                              line: UInt,
                              domainShortCode: String) -> (fileLineKey: String, fileLineValue: String) {
    let fileLineKey = "#" + domainShortCode + "_file_line"
    let fileLine = "\(fileId), line: \(line)"
    return (fileLineKey, fileLine)
  }
}

// MARK: - Approximately Equal

extension BaseErrorImpFunctions {
  /// Позволяет сравнивать 2 instance'a Типа Any, когда не нужно заниматься приведением Типов.
  /// Изначально сделан для сравнения значений в словарях Типа [String: Any].
  public static func isApproximatelyEqual<T>(_ lhs: T, _ rhs: T) -> Bool {
    if let lhs = lhs as? (any Hashable), let rhs = rhs as? (any Hashable) {
      // Используем AnyHashable для сравнения, т.к. внутри него уже нужный алгоритм сравнения разных значений и Типов
      // Достаточно было бы AnyEquatable, но такого нет
      AnyHashable(lhs) == AnyHashable(rhs)
    } else {
      String(describing: lhs) == String(describing: rhs)
    }
  }
  // ⚠️ @iDmitriyy
  // TODO: - check Numerics library imp
}

// MARK: - BaseError Identity suffix

extension BaseErrorImpFunctions {
  private static let shortCodeStub = "???"
  
  private static let identityPriorityCharset = CharacterSet.englishAlphabetUppercased.union(.arabicNumerals)
  private static let identityAltCharset = CharacterSet.englishAlphabetLowercased
  
  /// 3х буквенный код
  public static func shortCodeOf(identity: String) -> String {
    guard identity.isNotEmpty else { return shortCodeStub }
    
    let uppercased = identity.removingCharacters(except: identityPriorityCharset)
    let limit: Int = 3
    let shortCodeUpper = uppercased.prefix(limit).apply(String.init)
    
    func getChar(of string: String, withIndex index: Int) -> String {
      guard string.isNotEmpty else { return "" }
      let charIndex = string.index(string.startIndex, offsetBy: index, limitedBy: string.endIndex)
      guard let charIndex, string.indices.contains(charIndex) else { return "" }
      return String(string[charIndex])
    }
    
    lazy var notUppercased = identity.removingCharacters(except: identityAltCharset)
    
    let shortCode: String = switch shortCodeUpper.count {
    case 3: shortCodeUpper
    case 2: shortCodeUpper + getChar(of: notUppercased, withIndex: 0)
    case 1: shortCodeUpper + getChar(of: notUppercased, withIndex: 0) + getChar(of: notUppercased, withIndex: 1)
    default: getChar(of: notUppercased, withIndex: 0) + getChar(of: notUppercased, withIndex: 1)
      + getChar(of: notUppercased, withIndex: 2)
    }
    return shortCode.isNotEmpty ? shortCode : shortCodeStub
  }
  
  public static func shortCodeOf(fileId: StaticString) -> String {
    let fileNameSubstring = "\(fileId)".split(separator: "/").last
    let fileNameWithoutExtension = fileNameSubstring?.split(separator: ".").first ?? fileNameSubstring
    guard let fileName = fileNameWithoutExtension.map({ String($0) }) else { return shortCodeStub }
    return _shortCode(for: fileName, maxLength: 3)
  }
}

extension BaseErrorImpFunctions {
  /// Returns short code (short identity) for error/warning logs. Max length is equal to 3 symbols (unicode scalars).
  /// Expected input is file name / #fileID, Type name, event name, screen name, component / service name or other name meaningful as as place where error did happen.
  /// This method better reflects source name  than `shortCodeOf(identity:)` (e.g. for for "SearchResponse" output is SeR instead of "SRe")
  /// and is better optimized for both memory and speed.
  /// Examples:
  ///
  /// Camel Case:
  /// - First uppercased:
  ///   - "OFS" <- "OrderFinishSuccess"
  ///   - "OFS" <- "OrderFinishSuccessAgain"
  ///   - "ABT" <- "ABTestActivationEvent"
  ///
  ///   - "CoR" <- "ConfigReceived"
  ///   - "UpF" <- "UploadFile"
  ///
  ///   - "Sea" <- "Search"
  ///   - "Boo" <- "Booking"
  ///
  /// - First lowercased:
  ///   - "rPF" <- "removeProductFromCart"
  ///   - "aPT" <- "addProductToCart"
  ///   - "iPN" <- "inputPhoneNumber"
  ///   - "vPD" <- "viewProductDetails"
  ///   - "opS" <- "openScreen"
  ///   - "acE" <- "actionEvent"
  ///   - "pur" <- "purchase"
  ///   - "log" <- "login"
  ///
  /// Snake Case:
  /// - "ofs" <- "order_finish_success"
  /// - "ofs" <- "order_finish_success_again"
  /// - "Ofs" <- "Order_finish_success"
  /// - "OFS" <- "Order_Finish_Success"
  /// - "upf" <- "upload_file"
  /// - "upF" <- "upload_File"
  /// - "UpF" <- "Upload_File"
  /// - "Upf" <- "Upload_file"
  public static func shortCode(for keyWord: String) -> String {
    _shortCode(for: keyWord, maxLength: 3)
  }
  
  // swiftlint:disable:next function_body_length
  internal static func _shortCode(for keyWord: String, maxLength _maxLength: Int) -> String {
    let maxLength = _maxLength.boundedWith(2, 10)
    let scalars = keyWord.unicodeScalars
    
    // with maxLength = 3 for keyWord = "removeProductFromCart" primary scalars are: `r`, `P`, `F`. No room for alt scalars here.
    // with maxLength = 10 primary scalars are: `r`, `P`, `F`, `C`. Additionally two groups of alt scalars appear:
    // `emove` and `r`. The output will be "removePrFC".
    
    // with maxLength = 3 for keyWord = "viewExitFailed" primary scalars are: `v`, `E`, `F`. No room for alt scalars here.
    // with maxLength = 10 primary scalars are: `r`, `P`, `F`, `C`. Additionally two groups of alt scalars appear:
    // `emove` and `r`. The output will be "removePrFC".
    
    let primaryScalarIndices: ContiguousArray<String.UnicodeScalarView.Index>
    let primaryScalarsCount: Int
    do {
      var _primaryScalarIndices = ContiguousArray<String.UnicodeScalarView.Index>() // ContiguousArray vs Array is 3.5% faster
      _primaryScalarIndices.reserveCapacity(maxLength) // with reserveCapacity func is 3% faster primaryScalarIndices.count
      var _primaryScalarsCount: Int = 0 // using this var is 5% faster than call
      var shouldTreatAnyValidAsPrimary: Bool = true // first valid symbol is always primary
      loop: for index in scalars.indices {
        let scalar = scalars[index]
        
        // switch primaryScalarsCount { // switch is 38% slower than if-else
        // case 0:
        // case 1..<maxLength:
        
        if shouldTreatAnyValidAsPrimary { // `primaryScalarsCount == 0 or if previously a separator was found`
          if CharacterSet.shortCodeAll.contains(scalar) {
            _primaryScalarIndices.append(index)
            _primaryScalarsCount += 1
            shouldTreatAnyValidAsPrimary = false
          }
        } else if _primaryScalarsCount < maxLength {
          if CharacterSet.shortCodePrimary.contains(scalar) {
            _primaryScalarIndices.append(index)
            _primaryScalarsCount += 1
          } else if CharacterSet.shortCodeSeparators.contains(scalar) {
            shouldTreatAnyValidAsPrimary = true // remember that separator was found so next symbol should be treated as primary
          }
        } else {
          break loop
        }
      }
      (primaryScalarIndices, primaryScalarsCount) = (_primaryScalarIndices, _primaryScalarsCount)
    }
    
    // firstPrimaryScalarIndex is a guarantee that primaryScalarIndices not empty
    guard let firstPrimaryScalarIndex = primaryScalarIndices.first, let lastPrimaryScalarIndex = primaryScalarIndices.last else {
      // no valid scalars were found
      return shortCodeStub
    }
    
    var result = String.UnicodeScalarView()
    result.reserveCapacity(maxLength)
    if primaryScalarsCount >= maxLength {
      // this is usual case in practice.
      // With default maxLength = 3 primary scalars will occupy all capacity (maxLength) for many filenames.
      // e.g. "CartScreenViewController" => "CSV" , "SearchScreenPresenter" => "SSP"
      primaryScalarIndices.forEach { index in result.append(scalars[index]) }
    } else { // 1..<maxLength
      // https://forums.swift.org/t/performance-of-removefirst-vs-removefirst-1/37712
      let endIndex = scalars.endIndex
      
      let altScalarsCountLimit = maxLength - primaryScalarsCount
      var altScalarsCount: Int = 0
      
      /// there is no no guarantee these scalars are from 'alt scalars allowed charset'. Here is an assumption made that all are.
      let altScalarsUnverifiedTotalCount: Int = scalars.count - primaryScalarsCount
      // sparse alt scalars give more diversity in output. "CartScreenViewController"
      // CatScenViwC
      let canSparseAltScalars: Bool = (altScalarsUnverifiedTotalCount / altScalarsCountLimit) > 1
      
      if firstPrimaryScalarIndex == lastPrimaryScalarIndex {
        // single primary scalar, it is effectively the first and the only one meaningful symbol
        // this path make function 3.5% faster
        // можно было бы оставить только код из else {} ветвления – он универсальный, однако работает чуть дольше
        _append(primaryScalarWithIndex: firstPrimaryScalarIndex,
                andAltScalarsBeforeIndex: endIndex,
                from: scalars,
                to: &result,
                appendedAltScalarsCount: &altScalarsCount,
                altScalarsMaxCount: altScalarsCountLimit,
                canSparseAltScalars: canSparseAltScalars)
      } else {
        for indexOfScalarIndex in primaryScalarIndices.indices {
          let primaryScalarIndex = primaryScalarIndices[indexOfScalarIndex]
          let limitingIndex = primaryScalarIndices[at: indexOfScalarIndex + 1] ?? endIndex
          
          _append(primaryScalarWithIndex: primaryScalarIndex,
                  andAltScalarsBeforeIndex: limitingIndex,
                  from: scalars,
                  to: &result,
                  appendedAltScalarsCount: &altScalarsCount,
                  altScalarsMaxCount: altScalarsCountLimit,
                  canSparseAltScalars: canSparseAltScalars)
        }
      }
    }
    
    return String(result)
  }
  
  /// sub procedure of `func _shortCode(for keyWord: String, length: Int) -> String`
  /// No preconditions and args checks are made here – it is caller responsibility to ensure that all values are valid.
  private static func _append(primaryScalarWithIndex primaryScalarIndex: String.UnicodeScalarView.Index,
                              andAltScalarsBeforeIndex endIndex: String.UnicodeScalarView.Index,
                              from scalars: String.UnicodeScalarView,
                              to result: inout String.UnicodeScalarView,
                              appendedAltScalarsCount: inout Int,
                              altScalarsMaxCount: Int,
                              canSparseAltScalars: Bool) {
    result.append(scalars[primaryScalarIndex])
    
    let altScalarsMaxCount_local = altScalarsMaxCount - appendedAltScalarsCount
    
    guard altScalarsMaxCount_local > 0 else { return }
    
    var insertedAltScalarsCount_local = 0
    defer { appendedAltScalarsCount += insertedAltScalarsCount_local }
    
    var altScalarIndex = scalars.index(after: primaryScalarIndex)
    while insertedAltScalarsCount_local < altScalarsMaxCount_local, altScalarIndex < endIndex {
      let altScalar = scalars[altScalarIndex]
      if CharacterSet.shortCodeAll.contains(altScalar) {
        result.append(altScalar)
        insertedAltScalarsCount_local += 1
      }
      
      let nextIndex: String.UnicodeScalarView.Index // can be out of scalars bounds, check is made on next loop iteration
        = if canSparseAltScalars, let idx = scalars.index(altScalarIndex, offsetBy: 2, limitedBy: endIndex) {
        idx
      } else {
        scalars.index(after: altScalarIndex)
      }
      altScalarIndex = nextIndex
    }
  }
}

extension CharacterSet {
  internal static let shortCodeSeparatorsCharsetString: String = #"_-.– /|\"#
  fileprivate static let shortCodeSeparators = CharacterSet(charactersIn: shortCodeSeparatorsCharsetString)
  
  fileprivate static let shortCodePrimary = CharacterSet.uppercaseLetters.union(.decimalDigits)
  fileprivate static let shortCodeAll = shortCodePrimary.union(.lowercaseLetters)
}

// MARK: - put Data as String

extension BaseErrorImpFunctions {
  /// Добавляет data в словарь, расценивая её как UTF8. Если размер data == 0, добавит сообщение о нулевом размере.
  /// Если данные превышают размер, который можно отправить в нонфаталы, будут отправлены первые и последние 512 символов.
  /// В ином случае отправит полностью.
  public static func putDataAsString(_ data: Data, to errorInfo: inout ErrorInfo) {
    // В случае .dataCorrupted отправляем кусок ответа, чтоб было понятно что там приходит. Часто бэк отправляет html
    // вместо json'a при 500 ответах.
    guard !data.isEmpty else {
      errorInfo["dataString"] = "`Data has zero bytes length`"
      return
    }
    // ⚠️ @iDmitriyy
    // TODO: - make ErrorInfo protocol extensions
    // make this func package ACL, errorInfo: inout shpuld be generic (aka DictUnifying protocol)
    let stringMaxLength = Self.stringValMaxLength
    // (префикс + суффикс) + (небольшой запас для символов > 1 байта)
    let dataMaxLength = (stringMaxLength * 2) + (stringMaxLength / 16)
    
    let dataString = String(decoding: data, as: UTF8.self)
    if data.count <= dataMaxLength, dataString.count <= stringMaxLength {
      // проверяем data.count < maxLength, т.к. Character'ов может быт немного, а байтах это большой объём.
      // кол-во символов в строке будет <= кол-ву байт, т.к. Character занимает минимум 1 байт
      errorInfo["dataString"] = dataString
    } else {
      errorInfo["data bytes count"] = data.count
      errorInfo["dataString first \(stringMaxLength) chars"] = dataString.prefix(stringMaxLength).apply(String.init)
      errorInfo["dataString last \(stringMaxLength) chars"] = dataString.suffix(stringMaxLength).apply(String.init)
    }
  }
}

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
    
    func getCodableErrorInfo() -> ErrorInfo { ErrorInfo(legacyUserInfo: codableError._userInfo as? [String: Any] ?? [:]) }
    
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

// ⚠️ @iDmitriyy
// TODO: - ADD compile flag for configuration of constants either with default values nor some other mechanism –
// complie string-flag, conformance for special type, etc.
