#import "Alipay.h"
#import "AlipayManager.h"

@implementation Alipay

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(auth2:(NSDictionary *)params
                 resolve:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[AlipayManager shareInstance] auth2:params resolve:resolve reject:reject];
    });
}

@end
