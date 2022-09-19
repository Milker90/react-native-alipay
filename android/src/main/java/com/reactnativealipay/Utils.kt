package com.reactnativealipay

import android.text.TextUtils
import android.util.Base64
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import java.io.UnsupportedEncodingException
import java.net.URLEncoder
import java.security.KeyFactory
import java.security.Signature
import java.security.spec.PKCS8EncodedKeySpec
import java.util.*
import kotlin.collections.HashMap

/**
 * 2.0 订单串本地签名逻辑
 * 注意：本 Demo 仅作为展示用途，实际项目中不能将 RSA_PRIVATE 和签名逻辑放在客户端进行！
 */
object Utils {

  private const val ALGORITHM = "RSA"

  private const val SIGN_ALGORITHMS = "SHA1WithRSA"

  private const val SIGN_SHA256RSA_ALGORITHMS = "SHA256WithRSA"

  private const val DEFAULT_CHARSET = "UTF-8"

  private fun getAlgorithms(rsa2: Boolean): String? {
    return if (rsa2) SIGN_SHA256RSA_ALGORITHMS else SIGN_ALGORITHMS
  }

  fun sign(content: String, privateKey: String?, rsa2: Boolean): String? {
    try {
      val priPKCS8 = PKCS8EncodedKeySpec(
        Base64.decode(privateKey, Base64.DEFAULT)
      )
      val keyf = KeyFactory.getInstance(ALGORITHM)
      val priKey = keyf.generatePrivate(priPKCS8)
      val signature = Signature
        .getInstance(getAlgorithms(rsa2))
      signature.initSign(priKey)
      signature.update(content.toByteArray(charset(DEFAULT_CHARSET)))
      val signed = signature.sign()
      return Base64.encodeToString(signed, Base64.DEFAULT)
    } catch (e: Exception) {
      e.printStackTrace()
      return null
    }
  }

  /**
   * 构造参数信息
   *
   * @param map
   * 支付宝请求参数
   * @return
   */
  fun buildParams(map: Map<String, String?>): String {
    val keys: List<String> = ArrayList(map.keys)
    val sb = StringBuilder()
    Collections.sort(keys)
    for (key in keys) {
      val value = map[key]
      sb.append(buildKeyValue(key, value, true))
      sb.append("&")
    }
    return sb.toString()
  }

  /**
   * 拼接键值对
   *
   * @param key
   * @param value
   * @param isEncode
   * @return
   */
  private fun buildKeyValue(key: String, value: String?, isEncode: Boolean): String {
    val sb = StringBuilder()
    sb.append(key)
    sb.append("=")
    if (isEncode) {
      try {
        sb.append(URLEncoder.encode(value, "UTF-8"))
      } catch (e: UnsupportedEncodingException) {
        sb.append(value)
      }
    } else {
      sb.append(value)
    }
    return sb.toString()
  }

  fun parseQueryString(queryStr: String?): HashMap<String, String>? {
    if (queryStr != null) {
      if (queryStr.isEmpty()) null
    }

    val strs: Array<String> = queryStr!!.split("&").toTypedArray()
    val keyValueMap = HashMap<String, String>()
    for (str in strs) {
      val arr: Array<String> = str.split("=").toTypedArray()
      if (arr.size == 2) {
        keyValueMap[arr[0]] = removeBrackets(arr[1]).toString()
      }
    }
    return keyValueMap
  }

  fun convertMapToWritableMap(map: Map<String, String?>) : WritableMap {
    val ret = Arguments.createMap()
    for ((key, value) in map) {
      ret.putString(key, value)
    }
    return ret
  }

  private fun removeBrackets(str: String): String? {
    var retStr = str
    if (!TextUtils.isEmpty(retStr)) {
      if (retStr.startsWith("\"")) {
        retStr = retStr.replaceFirst("\"".toRegex(), "")
      }
      if (retStr.endsWith("\"")) {
        retStr = retStr.substring(0, retStr.length - 1)
      }
    }
    return retStr
  }
}
