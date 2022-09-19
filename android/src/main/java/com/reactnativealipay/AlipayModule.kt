package com.reactnativealipay

import android.util.Log
import com.alipay.sdk.app.AuthTask
import com.facebook.react.bridge.*

class AlipayModule(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {

  private val TAG = "AlipayModule"

  override fun getName(): String {
    return "Alipay"
  }

  @ReactMethod
  fun auth2(params: ReadableMap, promise: Promise) {
    val signType = AuthUtil.convertSignType(params.getString("signType").toString())
    val authInfo = AlipayAuthInfo(
      pid = params.getString("pid").toString(),
      appId = params.getString("appId").toString(),
      targetId = params.getString("targetId").toString(),
      signType = signType,
      rsaPrivateKey = params.getString("rsaPrivateKey").toString(),
      rsa2PrivateKey = params.getString("rsa2PrivateKey").toString(),
      serverSignedString = params.getString("serverSignedString").toString())

    if (!authInfo.isValid()) {
      promise.reject("miss_params", "缺少必要参数，检查参数后再调用\n${authInfo.toString()}")
      return
    }

    val authInfoString = if (signType == AuthSignType.SERVER_RSA) {
      authInfo.serverSignedString.toString()
    } else {
      AuthUtil.buildAuthInfoString(authInfo)
    }
    Log.d(TAG, "authInfoString: $authInfoString")
    if (authInfoString == null) promise.reject("sign_error", "签名失败，检查参数后再调用\n${authInfo.toString()}")

    Thread {
      val authTask = AuthTask(currentActivity)
      val resultDic = authTask.authV2(authInfoString, true)
      Log.d(TAG, "auth2 result: $resultDic")
      val ret = AuthUtil.handleAuthResult(resultDic)
      val status = ret["status"]

      if (status == "success") {
        val writableMap = Utils.convertMapToWritableMap(ret["data"] as Map<String, String?>)
        promise.resolve(writableMap)
      } else {
        promise.reject(status.toString(), ret["message"].toString())
      }
    }.start()
  }

}
