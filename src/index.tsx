import { NativeModules } from 'react-native';

export type AlipayAuth2Result = {
  authCode: string;
};

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

type AlipayType = {
  auth2(params: AlipayAuthInfo): Promise<AlipayAuth2Result>;
};

const { Alipay } = NativeModules;

export default Alipay as AlipayType;
