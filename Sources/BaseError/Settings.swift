//
//  Settings.swift
//  errors-suite
//
//  Created by Dmitriy Ignatyev on 14.04.2025.
//

private import class Foundation.NSLock

public struct BaseErrorSettings: Sendable {
  public var errorInfoLimit: ErrorInfoLimit = .bytes(.max)
  
  public enum ErrorInfoLimit: Sendable {
    case bytes(UInt32)
  }
}

extension BaseErrorSettings {
  internal static let shared: Self = lock.withLock {
    mutableInitialConfig
  }
  
  private static let lock = NSLock()
  
  nonisolated(unsafe) // TODO: - wrap in Mutex
  private static var mutableInitialConfig = BaseErrorSettings()
  
  public func setup(_ configure: (inout Self) -> Void) {
    Self.lock.withLock { configure(&Self.mutableInitialConfig) }
  }
}
