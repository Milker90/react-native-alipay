import * as React from 'react';

import { StyleSheet, View, Text, TouchableOpacity } from 'react-native';
import Alipay, { AlipaySignType } from 'react-native-alipay';
import Config from 'react-native-config';

export default function App() {
  const onPressLogin = React.useCallback(async () => {
    try {
      const params = {
        pid: Config.ALIPAY_PID,
        appId: Config.ALIPAY_APPID,
        targetId: Config.ALIPAY_TARGET_ID,
        appScheme: Config.ALIPAY_APP_SCHEME_NAME,
        signType: AlipaySignType.RSA2,
        rsa2PrivateKey: Config.ALIPAY_RSA2_PRIVATE_KEY,
      };
      console.log(params);
      const ret = await Alipay.auth2(params);
      console.log(ret);
    } catch (error) {
      console.log(error.code, error.message);
    }
  }, []);

  return (
    <View style={styles.container}>
      <TouchableOpacity style={styles.loginBt} onPress={onPressLogin}>
        <Text style={styles.loginBtTitle}>Login to Alipay</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  loginBt: {
    width: 200,
    height: 50,
    marginVertical: 20,
    borderColor: 'gray',
    borderWidth: 1,
    backgroundColor: '#208990',
    justifyContent: 'center',
    alignItems: 'center',
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
  loginBtTitle: {
    color: 'white',
    fontSize: 18,
  },
});
