# react-native-alipay

alipay sdk for react native

## Installation

```sh
npm install react-native-alipay
```

## Usage

### 支付宝App授权登录

```js
import Alipay from "react-native-alipay";

// 本地rsa签名
const result = await Alipay.auth2({
  pid: "",
  appId: "",
  targetId: "",
  appScheme: "",
  signType: AlipaySignType.RSA2,
  rsa2PrivateKey: "",
});

// 服务器rsa签名
const result = await Alipay.auth2({
  signType: AlipaySignType.SERVER_RSA,
  serverSignedString: "服务器签名后拼接的字符串, eg: app_id=xxx&pid=xxx&sign_type=RSA2&sign=xxxx",
});

```

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT
