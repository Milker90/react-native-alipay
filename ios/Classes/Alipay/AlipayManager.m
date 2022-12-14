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

@property (nonatomic, assign) UIBackgroundTaskIdentifier bgTaskToken;

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

- (instancetype)init {
    if (self = [super init]) {
    // https://developer.apple.com/library/archive/qa/qa1941/_index.html#//apple_ref/doc/uid/DTS40017602
        // https://github.com/AFNetworking/AFNetworking/issues/4279#issuecomment-447108981
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return  self;
}

- (void)applicationDidEnterBackground {
    [self finishBackgroundTask];
    __weak typeof(self) weakSelf = self;
    _bgTaskToken = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"react-native-alipay-background" expirationHandler:^{
        [weakSelf finishBackgroundTask];
    }];
}

- (void)applicationWillEnterForeground {
    [self finishBackgroundTask];
}

- (void)finishBackgroundTask {
    if (_bgTaskToken != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:_bgTaskToken];
        _bgTaskToken = UIBackgroundTaskInvalid;
    }
}

- (void)auth2:(NSDictionary *)params
      resolve:(RCTPromiseResolveBlock)resolve
       reject:(RCTPromiseRejectBlock)reject {
    NSString *pid = [params objectForKey:@"pid"];
    NSString *appID = [params objectForKey:@"appId"];
    NSString *targetId = [params objectForKey:@"targetId"];

    // ????????????scheme, ???Info.plist??????URL types
    NSString *appScheme = [params objectForKey:@"appScheme"];
    
    // ???????????????rsa2PrivateKey ?????? rsaPrivateKey ?????????????????????
    // ????????????????????????????????????????????? rsa2PrivateKey
    // rsa2PrivateKey ???????????????????????????????????????????????????????????????????????? rsa2PrivateKey
    // ?????? rsa2PrivateKey???????????????????????????????????????????????????????????????
    // ???????????????https://doc.open.alipay.com/docs/doc.htm?treeId=291&articleId=106097&docType=1
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
        NSString *message = [NSString stringWithFormat:@"???????????????????????????????????????\npid:%@\nappID:%@\ntargetId:%@\nappScheme:%@\nsignType:%@\nrsa2PrivateKey:%@\nrsaPrivateKey:%@\nserverSignedString:%@\n", pid, appID, targetId, appScheme,signType, rsa2PrivateKey, rsaPrivateKey, serverSignedString];
        NSError *error = nil;
        reject(@"miss_params", message, error);
        return;
    }

    NSString *authInfoStr = nil;
    if ([signType isEqualToString:@"SERVER_RSA"]) {
        authInfoStr = [NSString stringWithString:serverSignedString];
    } else {
        //?????? auth info ??????
        AlipayAuthInfo *authInfo = [AlipayAuthInfo new];
        authInfo.pid = pid;
        authInfo.appID = appID;
        authInfo.targetID = targetId;

        //auth type
        NSString *authType = [[NSUserDefaults standardUserDefaults] objectForKey:@"authType"];
        if (authType) {
            authInfo.authType = authType;
        }

        // ?????????????????????????????????
        NSString *authInfoStr = [authInfo description];
        NSLog(@"authInfoStr = %@",authInfoStr);
        if (![Utils isValidString:authInfoStr]) {
            NSError *error = nil;
            reject(@"invalid_params", [NSString stringWithFormat:@"?????????????????????????????????\npid:%@\nappID:%@\nappScheme:%@\nsignType:%@\nrsa2PrivateKey:%@\nrsaPrivateKey:%@\nserverSignedString:%@\n", pid, appID, appScheme,signType, rsaPrivateKey, rsa2PrivateKey, serverSignedString], error);
            return;
        }
            
        // ????????????????????????????????????,???????????????????????????????????????????????????,???????????????RSA????????????,?????????????????????base64?????????UrlEncode
        NSString *signedString = nil;
        APRSASigner* signer = [[APRSASigner alloc] initWithPrivateKey:((rsa2PrivateKey.length > 1)?rsa2PrivateKey:rsaPrivateKey)];
        if ((rsa2PrivateKey.length > 1)) {
            signedString = [signer signString:authInfoStr withRSA2:YES];
        } else {
            signedString = [signer signString:authInfoStr withRSA2:NO];
        }

        if (![Utils isValidString:signedString]) {
            NSError *error = nil;
            reject(@"signed_failed", @"RSA??????????????????", error);
            return;
        }
        
        // ???????????????????????????????????????????????????,????????????????????????
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
        // ????????????????????????????????????????????????????????????
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
        return @{@"status": @"response_error", @"message": @"?????????SDK????????????response"};
    }
    
    NSString *resultStatus = [resultDic objectForKey:@"resultStatus"];
    if ([resultStatus isEqualToString:@"9000"]) {
        // ??????????????????
        NSString *result = [resultDic objectForKey:@"result"];
        NSDictionary *parseResult = [Utils parseQueryString:result];
        NSString *resultCode = [parseResult objectForKey:@"result_code"];
        if ([resultCode isEqualToString:@"200"]) {
            return @{@"status": @"success", @"data": parseResult};
        } else if ([resultCode isEqualToString:@"1005"]) {
            return @{@"status": @"account_error", @"message": @"???????????????????????????????????????????????????????????????"};
        } else if ([resultCode isEqualToString:@"202"]) {
            return @{@"status": @"system_error", @"message": @"????????????????????????????????????????????????????????????"};
        } else {
            return @{@"status": @"unknow", @"message": @"????????????"};
        }
    } else if ([resultStatus isEqualToString:@"4000"]) {
        return @{@"status": @"system_error", @"message": @"?????????????????????"};
    } else if ([resultStatus isEqualToString:@"6001"]) {
        return @{@"status": @"user_cancel", @"message": @"??????????????????"};
    } else if ([resultStatus isEqualToString:@"6002"]) {
        return @{@"status": @"network_error", @"message": @"??????????????????"};
    } else {
        return @{@"status": @"unknow", @"message": @"????????????"};
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
