//
//  NetworkErrorDTO.swift
//  swifty-kit
//
//  Created by Dmitriy Ignatyev on 15.12.2024.
//

/// Модель данных, которые приходят от бэкэнда в случае ошибок для статус кодов 400 / 500
public struct NetworkErrorDTO: Decodable {
  /// Код ошибки предметной области. Если поле 'code' содержит значение, то поле 'message' по контракту обязательно содержит значение.
  /// Пример: у пользователя есть бонусы на карте, но они не могут быть списаны, потому что он не заполнил анкету. В этом случае при получении
  /// определённого кода приложение может открыть экран ввода данных анкеты, и после сохранения этих данных спишутся балы.
  public let code: String?
  
  /// Сообщение, которое нужно показать пользователю на уровне UI. Кишки логов и стек трэйсы это сообщение содержать не должно.
  public let message: String?
  
  /// Системное сообщение / внутренняя ошибка бэкнэда.
  public let systemMessage: String
}
