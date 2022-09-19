import { NativeModules } from 'react-native';

export enum AlipaySignType {
  RSA = 'RSA',
  RSA2 = 'RSA2',
  SERVER_RSA = 'SERVER_RSA',
}

export type AlipayAuthInfo = {
  pid: string;
  appId: string;
  targetId: string;
  signType: AlipaySignType;
  appScheme?: string | null;
  rsaPrivateKey?: string | null;
  rsa2PrivateKey?: string | null;
  serverSignedString?: string | null;
};

// 返回结果
// {
//   "alipay_open_id": "xxx",
//   "app_id": "xxx",
//   "auth_code": "xxx",
//   "result_code": "200",
//   "scope": "kuaijie",
//   "success": "true",
//   "target_id": "xxx",
//   "user_id": "xxx"
// }
type AlipayType = {
  auth2(params: AlipayAuthInfo): Promise<any>;
};

const { Alipay } = NativeModules;

export default Alipay as AlipayType;
