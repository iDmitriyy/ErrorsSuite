//
//  FileLine.swift
//  errors-suite
//
//  Created by Dmitriy Ignatyev on 28/07/2025.
//

extension BaseErrorImpFunctions {
  /// - Parameters:
  ///   - fileId: #fileID
  ///   - line: #line
  ///   - domainShortCode: domainShortCode of BaseError
  /// - Returns: key-value tuple  for error info dict. Example:  -> (fileLineKey: "#BE_file_line", fileLineValue: "ModuleName.FileName, line: 4")
  public static func fileLine(fileId: StaticString,
                              line: UInt,
                              domainShortCode: String) -> (fileLineKey: String, fileLineValue: String) {
    let fileLineKey = "#" + domainShortCode + "_file_line"
    let fileLine = "\(fileId), line: \(line)"
    return (fileLineKey, fileLine)
  }
}
