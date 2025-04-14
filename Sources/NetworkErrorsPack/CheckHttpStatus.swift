//
//  CheckHttpStatus.swift
//  swifty-kit
//
//  Created by Dmitriy Ignatyev on 15.12.2024.
//

import HttpStatus

extension NetworkErrorGeneric {
  public func isCode(equalToHttpStatus statusCode: HttpStatusCode) -> Bool {
    switch self {
    case .httpStatusError(let httpError, _): httpError.isCode(equalToHttpStatus: statusCode)
    default: false
    }
  }
  
  public func isCode(equalToStatus5xx code: Http5xxStatusCode) -> Bool {
    isCode(equalToHttpStatus: .status5xx(code))
  }
  
  public func isCode(equalToStatus4xx code: Http4xxStatusCode) -> Bool {
    isCode(equalToHttpStatus: .status4xx(code))
  }
}

extension NetworkErrorGeneric {
  public func hasHttpStatusAny4xx() -> Bool {
    hasHttpStatus(ofStatusGroup: Http4xxStatusCode.self)
  }
  
  public func hasHttpStatusAny5xx() -> Bool {
    hasHttpStatus(ofStatusGroup: Http5xxStatusCode.self)
  }
  
  public func hasHttpStatus<T: HttpStatusCodeType>(ofStatusGroup statusCodesGroup: T.Type) -> Bool {
    switch self {
    case .httpStatusError(let httpError, _): httpError.hasHttpStatus(ofStatusGroup: statusCodesGroup)
    default: false
    }
  }
}

extension HttpStatusError {
  public func isCode(equalToHttpStatus code: HttpStatusCode) -> Bool {
    self.errorCode == code
  }
  
  public func isCode(equalToStatus5xx code: Http5xxStatusCode) -> Bool {
    isCode(equalToHttpStatus: .status5xx(code))
  }
  
  public func isCode(equalToStatus4xx code: Http4xxStatusCode) -> Bool {
    isCode(equalToHttpStatus: .status4xx(code))
  }
}

extension HttpStatusError {
  public func hasHttpStatusAny4xx() -> Bool {
    hasHttpStatus(ofStatusGroup: Http4xxStatusCode.self)
  }
  
  public func hasHttpStatusAny5xx() -> Bool {
    hasHttpStatus(ofStatusGroup: Http5xxStatusCode.self)
  }
  
  public func hasHttpStatus<T: HttpStatusCodeType>(ofStatusGroup statusCodesGroup: T.Type) -> Bool {
    let httpStatusCode: HttpStatusCode = self.errorCode
    return statusCodesGroup.codesGroupRange.contains(httpStatusCode.rawValue)
  }
  
  // ⚠️ @iDmitriyy
  // TODO: - 
//  > need to workaround generic overload resoultion for preventing recursive call
//  @available(*, deprecated, message: "comparing to `HttpStatusCode`-superType will always return true which is meaningless")
//  public func hasHttpStatus(ofStatusGroup statusCodesGroup: HttpStatusCode.Type) -> Bool {
//    hasHttpStatus(ofStatusGroup: statusCodesGroup as some HttpStatusCodeType)
//  }
}
