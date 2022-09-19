//
//  AlipayManager.h
//  react-native-alipay
//
//  Created by milker90 on 2022/9/16.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>

NS_ASSUME_NONNULL_BEGIN

@interface AlipayManager : NSObject

+ (instancetype)shareInstance;

- (void)auth2:(NSDictionary *)params
      resolve:(RCTPromiseResolveBlock)resolve
       reject:(RCTPromiseRejectBlock)reject;
- (void)handleOpenURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options;

@end

NS_ASSUME_NONNULL_END
