//
//  Never+BaseError.swift
//  swifty-kit
//
//  Created by Dmitriy Ignatyev on 14.12.2024.
//

extension Never: @retroactive CustomDebugStringConvertible {}
extension Never: @retroactive CustomStringConvertible {}
extension Never: @retroactive CustomNSError {}
extension Never: @retroactive LocalizedError {}

extension Swift.Never: BaseError {
  public var fullName: String {
    switch self {}
  }
  
  public var intCode: Int {
    switch self {}
  }
  
  public var domainShortCode: String {
    switch self {}
  }
  
  public var underlying: (any BaseError)? {
    switch self {}
  }
  
  public var primaryInfo: ErrorInfo {
    switch self {}
  }
  
  public var info: ErrorInfo {
    switch self {}
  }
  
  public var localizedMessage: String {
    switch self {}
  }
  
  public var providesCodeChain: Bool {
    switch self {}
  }
}
