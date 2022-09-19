//
//  AlipayManager.m
//  react-native-alipay
//
//  Created by milker90 on 2022/9/16.
//

#import "AlipayManager.h"
#import <AlipaySDK/AlipaySDK.h>
#import "AlipayAuthInfo.h"
#import "APRSASigner.h"
#import "Utils.h"

@interface AlipayManager ()

@property (nonatomic, copy) RCTPromiseResolveBlock authResolve;
@property (nonatomic, copy) RCTPromiseRejectBlock authReject;

@end

@implementation AlipayManager

+ (instancetype)shareInstance {
    static AlipayManager *_instance = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
      _instance = [[self alloc] init];
    });
    return _instance;
}

- (void)auth2:(NSDictionary *)params
      resolve:(RCTPromiseResolveBlock)resolve
       reject:(RCTPromiseRejectBlock)reject {
    NSString *pid = [params objectForKey:@"pid"];
    NSString *appID = [params objectForKey:@"appId"];
    NSString *targetId = [params objectForKey:@"targetId"];

    // 应用注册scheme, 在Info.plist定义URL types
    NSString *appScheme = [params objectForKey:@"appScheme"];
    
    // 如下私钥，rsa2PrivateKey 或者 rsaPrivateKey 只需要填入一个
    // 如果商户两个都设置了，优先使用 rsa2PrivateKey
    // rsa2PrivateKey 可以保证商户交易在更加安全的环境下进行，建议使用 rsa2PrivateKey
    // 获取 rsa2PrivateKey，建议使用支付宝提供的公私钥生成工具生成，
    // 工具地址：https://doc.open.alipay.com/docs/doc.htm?treeId=291&articleId=106097&docType=1
    NSString *signType = [params objectForKey:@"signType"];
    NSString *rsa2PrivateKey = [params objectForKey:@"rsa2PrivateKey"];
    NSString *rsaPrivateKey = [params objectForKey:@"rsaPrivateKey"];
    NSString *serverSignedString = [params objectForKey:@"serverSignedString"];
    
    if (([signType isEqualToString:@"SERVER_RSA"] && ![Utils isValidString:serverSignedString] && ![Utils isValidString:appScheme]) &&
        (![Utils isValidString:pid] ||
         ![Utils isValidString:appID] ||
         ![Utils isValidString:targetId] ||
         ![Utils isValidString:appScheme] ||
         ([signType isEqualToString:@"RSA2"] && ![Utils isValidString:rsa2PrivateKey]) ||
         ([signType isEqualToString:@"RSA"] && ![Utils isValidString:rsaPrivateKey]))) {
        NSString *message = [NSString stringWithFormat:@"缺少必要参数，检查后再调用\npid:%@\nappID:%@\ntargetId:%@\nappScheme:%@\nsignType:%@\nrsa2PrivateKey:%@\nrsaPrivateKey:%@\nserverSignedString:%@\n", pid, appID, targetId, appScheme,signType, rsa2PrivateKey, rsaPrivateKey, serverSignedString];
        NSError *error = nil;
        reject(@"miss_params", message, error);
        return;
    }

    NSString *authInfoStr = nil;
    if ([signType isEqualToString:@"SERVER_RSA"]) {
        authInfoStr = [NSString stringWithString:serverSignedString];
    } else {
        //生成 auth info 对象
        AlipayAuthInfo *authInfo = [AlipayAuthInfo new];
        authInfo.pid = pid;
        authInfo.appID = appID;
        authInfo.targetID = targetId;

        //auth type
        NSString *authType = [[NSUserDefaults standardUserDefaults] objectForKey:@"authType"];
        if (authType) {
            authInfo.authType = authType;
        }

        // 将授权信息拼接成字符串
        NSString *authInfoStr = [authInfo description];
        NSLog(@"authInfoStr = %@",authInfoStr);
        if (![Utils isValidString:authInfoStr]) {
            NSError *error = nil;
            reject(@"invalid_params", [NSString stringWithFormat:@"参数无效，检查后再调用\npid:%@\nappID:%@\nappScheme:%@\nsignType:%@\nrsa2PrivateKey:%@\nrsaPrivateKey:%@\nserverSignedString:%@\n", pid, appID, appScheme,signType, rsaPrivateKey, rsa2PrivateKey, serverSignedString], error);
            return;
        }
            
        // 获取私钥并将商户信息签名,外部商户可以根据情况存放私钥和签名,只需要遵循RSA签名规范,并将签名字符串base64编码和UrlEncode
        NSString *signedString = nil;
        APRSASigner* signer = [[APRSASigner alloc] initWithPrivateKey:((rsa2PrivateKey.length > 1)?rsa2PrivateKey:rsaPrivateKey)];
        if ((rsa2PrivateKey.length > 1)) {
            signedString = [signer signString:authInfoStr withRSA2:YES];
        } else {
            signedString = [signer signString:authInfoStr withRSA2:NO];
        }

        if (![Utils isValidString:signedString]) {
            NSError *error = nil;
            reject(@"signed_failed", @"RSA签名结果为空", error);
            return;
        }
        
        // 将签名成功字符串格式化为订单字符串,请严格按照该格式
        authInfoStr = [NSString stringWithFormat:@"%@&sign=%@&sign_type=%@", authInfoStr, signedString, signType];
    }
   
    self.authReject = reject;
    self.authResolve = resolve;

    __weak typeof(self) weakSelf = self;
    [[AlipaySDK defaultService] auth_V2WithInfo:authInfoStr
                                     fromScheme:appScheme
                                       callback:^(NSDictionary *resultDic) {
//        NSLog(@"auth_V2WithInfo result = %@",resultDic);
        [weakSelf handleAuthResult: resultDic];
    }];
}

- (void)handleOpenURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options {
    if ([url.host isEqualToString:@"safepay"]) {
        // 授权跳转支付宝钱包进行支付，处理支付结果
        __weak typeof(self) weakSelf = self;
        [[AlipaySDK defaultService] processAuth_V2Result:url standbyCallback:^(NSDictionary *resultDic) {
//            NSLog(@"processAuth_V2Result result = %@",resultDic);
            [weakSelf handleAuthResult: resultDic];
        }];
    }
}

- (void)handleAuthResult:(NSDictionary *)resultDic {
    NSDictionary *ret = [self parseAuthResult:resultDic];
    NSString *status = [ret objectForKey:@"status"];
    if ([status isEqualToString:@"success"]) {
        if (self.authResolve) {
            self.authResolve([ret objectForKey:@"data"]);
        }
    } else {
        NSError *error = nil;
        self.authReject(status, [ret objectForKey:@"message"], error);
    }
    
    self.authResolve = nil;
    self.authReject = nil;
}

- (NSDictionary *)parseAuthResult:(NSDictionary *)resultDic {
    if ((!resultDic && ![resultDic isKindOfClass:[NSDictionary class]]) ||
        ![Utils isValidString:[resultDic objectForKey:@"resultStatus"]]) {
        return @{@"status": @"response_error", @"message": @"支付宝SDK返回错误response"};
    }
    
    NSString *resultStatus = [resultDic objectForKey:@"resultStatus"];
    if ([resultStatus isEqualToString:@"9000"]) {
        // 请求处理成功
        NSString *result = [resultDic objectForKey:@"result"];
        NSDictionary *parseResult = [Utils parseQueryString:result];
        NSString *resultCode = [parseResult objectForKey:@"result_code"];
        if ([resultCode isEqualToString:@"200"]) {
            return @{@"status": @"success", @"data": parseResult};
        } else if ([resultCode isEqualToString:@"1005"]) {
            return @{@"status": @"account_error", @"message": @"账户已冻结，如有疑问，请联系支付宝技术支持"};
        } else if ([resultCode isEqualToString:@"202"]) {
            return @{@"status": @"system_error", @"message": @"系统异常，请稍后再试或联系支付宝技术支持"};
        } else {
            return @{@"status": @"unknow", @"message": @"未知错误"};
        }
    } else if ([resultStatus isEqualToString:@"4000"]) {
        return @{@"status": @"system_error", @"message": @"支付宝系统异常"};
    } else if ([resultStatus isEqualToString:@"6001"]) {
        return @{@"status": @"user_cancel", @"message": @"用户中途取消"};
    } else if ([resultStatus isEqualToString:@"6002"]) {
        return @{@"status": @"network_error", @"message": @"网络连接出错"};
    } else {
        return @{@"status": @"unknow", @"message": @"未知错误"};
    }
}

@end
