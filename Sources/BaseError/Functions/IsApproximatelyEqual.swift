//
//  IsApproximatelyEqual.swift
//  errors-suite
//
//  Created by Dmitriy Ignatyev on 28/07/2025.
//

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
