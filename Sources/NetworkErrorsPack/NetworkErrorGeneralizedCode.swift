//
//  NetworkErrorGeneralizedCode.swift
//  swifty-kit
//
//  Created by Dmitriy Ignatyev on 15.12.2024.
//

/// Обобщение сетевых ошибок.
public enum NetworkErrorGeneralizedCode: Int, BaseErrorCode {
  // Ошибки упорядочены сверху вниз. Сверху более конкретные ошибки. Ниже расположены более обобщенные ошибки.
  
  case notConnectedToInternet = 0
  
  /// Невосстановимая ошибка клиента, связанная с обработкой полученных данных.
  case dataMapping = 1
  
  case requestCancelled = 6
  
  /// This is representation of 'userAuthenticationRequired' NSUrlError code or 403 http status code
  case authenticationRequired = 11
  
  /// Отключена загрузка данных в роуминге
  case internationalRoamingOff = 12
  
  case cellularLoadingNotAllowed = 13
  
  // MARK: Ошибки, означаюищие проблемы с сетью
  
  /// Сообщение про низкую скорость или плохой интернет. Кнопка "Повторить"
  case badNetworkAlwaysRetriable = 50
  
  /// Попробуйте ещё раз или подключитесь к другой сети. Если ошибка повторится - сообщите код...
  case badNetworkOnceRetriable = 51
  
  // MARK: Невосстановимые ошибки клиента / сервера (например некорректный URL)
  
  /// Какая-то невосстановимая ошибка клиента.
  case clientNotRecoverable = 60
  
  /// Какая-то невосстановимая ошибка из-за причин на стороне сервера
  case serverNotRecoverable = 70
  
  // MARK: Наиболее сильные обобщения
  
  /// Ошибки, при которых всегда имеет смысл потворить запрос ещё раз
  case alwaysRetriable = 80
  
  /// Ошибки, при которых пользователю имеет смысл 1 раз потворить запрос. Если снова неуспех - имеет смысл написать
  /// разработчикам. Тем не менее, пользователь должен иметь возможность повторять запрос сколько угодно раз.
  case onceRetriable = 81
  
  /// Ошибки, при возникновении которых не имеет смысла пытаться потворить запрос ещё раз.
  case notRecoverable = 82
}

extension NetworkErrorGeneralizedCode {
  /// У всех ошибок сетевого слоя тексты одинаковые. В этом extension общий для всех таких ошибок вспомогательный код.
  public var errorLocalizedMessage: String {
    switch self {
    case .notConnectedToInternet:
      "Кажется, у вас отключен интернет"
    case .dataMapping:
      "Произошла ошибка при обработке данных"
    case .requestCancelled:
      "Запрос был отменён"
    case .internationalRoamingOff:
      "Кажется, на вашем телефоне отключена передача данных в роуминге"
    case .cellularLoadingNotAllowed:
      "Кажется, у вас отключена передача данных по сотовой сети"
    case .authenticationRequired:
      "Авторизуйтесь для получения данных"
    case .badNetworkAlwaysRetriable:
      "Кажется, у вас плохое интернет-соединение. Попробуйте ещё раз"
    case .badNetworkOnceRetriable:
      "Кажется, у вас плохое интернет-соединение. Попробуйте ещё раз"
    case .clientNotRecoverable:
      "Произошла ошибка, мы работаем над этим"
    case .serverNotRecoverable:
      "Произошла ошибка, мы работаем над этим"
    case .alwaysRetriable:
      "Произошла ошибка при загрузке данных. Попробуйте ещё раз"
    case .onceRetriable:
      "Произошла ошибка при загрузке данных. Попробуйте ещё раз чуть позже"
    case .notRecoverable:
      "Произошла ошибка, мы работаем над этим"
    }
  }
  
  // ⚠️ @iDmitriyy
  // TODO: - need rethinked
  
  @available(*, deprecated, message: "need revision")
  public var shouldShowCodesChain: Bool {
    switch self {
    case .notConnectedToInternet: false
    case .internationalRoamingOff: false
    case .cellularLoadingNotAllowed: false
    case .dataMapping: true
    case .authenticationRequired: false
    case .badNetworkAlwaysRetriable: false
    case .badNetworkOnceRetriable: true
    case .clientNotRecoverable: true
    case .serverNotRecoverable: true
    case .alwaysRetriable: false
    case .onceRetriable: true
    case .notRecoverable: true
    case .requestCancelled: false
    }
  }
}
