package com.reactnativealipay

import java.io.UnsupportedEncodingException
import java.net.URLEncoder

object AuthUtil {
  private fun generateBuildMap(): MutableMap<String, String> {
    val keyValues: MutableMap<String, String> = HashMap()
    // 服务接口名称， 固定值
    keyValues["apiname"] = "com.alipay.account.auth"

    // 服务接口名称， 固定值
    keyValues["method"] = "alipay.open.auth.sdk.code.get"

    // 商户类型标识， 固定值
    keyValues["app_name"] = "mc"

    // 业务类型， 固定值
    keyValues["biz_type"] = "openservice"

    // 产品码， 固定值
    keyValues["product_id"] = "APP_FAST_LOGIN"

    // 授权范围， 固定值
    keyValues["scope"] = "kuaijie"

    // 授权类型， 固定值
    keyValues["auth_type"] = "AUTHACCOUNT"

    return keyValues
  }

  fun buildAuthInfoString(authInfo: AlipayAuthInfo): String? {
    val keyValues = generateBuildMap()

    // 商户签约拿到的pid，如：2088102123816631
    keyValues["pid"] = authInfo.pid

    // 商户签约拿到的app_id，如：2013081700024223
    keyValues["app_id"] = authInfo.appId

    // 商户唯一标识，如：kkkkk091125
    keyValues["target_id"] = authInfo.targetId

    val signTypeStr = if (authInfo.signType == AuthSignType.RSA2) "RSA2" else "RSA"
    keyValues["sign_type"] = signTypeStr

    var authInfoString = Utils.buildParams(keyValues)
    val rsa2 = authInfo.signType == AuthSignType.RSA2
    val privateKey = if (authInfo.signType == AuthSignType.RSA2) authInfo.rsa2PrivateKey else authInfo.rsaPrivateKey

    val signStr = Utils.sign(authInfoString, privateKey, rsa2)
    val encodedSign = URLEncoder.encode(signStr, "UTF-8")
    if (encodedSign == null) null

    authInfoString = "${authInfoString}sign=$encodedSign"

    return authInfoString
  }

  fun convertSignType(typeString: String): AuthSignType {
    return when(typeString) {
      "RSA" -> AuthSignType.RSA
      "RSA2" -> AuthSignType.RSA2
      "SERVER_RSA" -> AuthSignType.SERVER_RSA
      else -> {
        return AuthSignType.RSA2
      }
    }
  }

  fun handleAuthResult(resultDic: Map<String, String>): Map<String, Any> {
    val resultStatus = resultDic["resultStatus"]
    if (resultStatus == "9000") {
      val result = resultDic["result"]
      val parseResult = Utils.parseQueryString(result);
      val resultCode = parseResult?.get("result_code")
      if (resultCode == "200") {
        return mapOf("status" to "success", "data" to parseResult)
      } else if (resultCode == "1005") {
        return mapOf("status" to "account_error", "message" to "账户已冻结，如有疑问，请联系支付宝技术支持")
      } else if (resultCode == "202") {
        return mapOf("status" to "system_error", "message" to "系统异常，请稍后再试或联系支付宝技术支持")
      } else {
        return mapOf("status" to "unknow", "message" to "未知错误")
      }
    } else if (resultStatus == "4000") {
      return mapOf("status" to "system_error", "message" to "支付宝系统异常")
    }  else if (resultStatus == "6001") {
      return mapOf("status" to "user_cancel", "message" to "用户中途取消")
    } else if (resultStatus == "6002") {
      return mapOf("status" to "network_error", "message" to "网络连接出错")
    } else {
      return mapOf("status" to "unknow", "message" to "未知错误")
    }
  }
}
