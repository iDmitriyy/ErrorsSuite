//
//  PutDataAsString.swift
//  errors-suite
//
//  Created by Dmitriy Ignatyev on 28/07/2025.
//

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
