package com.reactnativealipay

enum class AuthSignType {
  // 本地RSA签名
  RSA,
  // 本地RSA2签名
  RSA2,
  // 由服务器RSA签名
  SERVER_RSA,
}

data class AlipayAuthInfo(
  // 签约的支付宝账号对应的支付宝唯一用户号，以 2088 开头的 16 位纯数字组成，如：2088102123816631
  var pid: String,
  // 支付宝分配给开发者的应用 ID，如：2013081700024223
  var appId: String,
  // 商户标识该次用户授权请求的 ID，该值在商户端应保持唯一  示例值：kkkkk091125
  var targetId: String,
  // 签名方式类型, 选择其中一种方式
  var signType: AuthSignType,
  // 本地RSA私钥
  var rsaPrivateKey: String?,
  // 本地RSA2私钥
  var rsa2PrivateKey: String?,
  // 服务器签名后的字符串
  var serverSignedString: String?
) {
  fun isValid(): Boolean {
    if ((signType == AuthSignType.SERVER_RSA && serverSignedString?.isEmpty() == true) &&
      (pid.isEmpty() ||
        appId.isEmpty() ||
        targetId.isEmpty() ||
        (signType == AuthSignType.RSA && rsaPrivateKey?.isEmpty() == true) ||
        (signType == AuthSignType.RSA2 && rsa2PrivateKey?.isEmpty() == true)
        )) {
      return false
    }
    return true
  }

  override fun toString(): String {
    return "pid:${pid}\nappID:${appId}\nsignType:${signType}\nrsa2PrivateKey:${rsa2PrivateKey}\nrsaPrivateKey:${rsaPrivateKey}\nrsaPrivateKey:${serverSignedString}"
  }
}
