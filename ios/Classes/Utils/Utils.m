//
//  Utils.m
//  react-native-alipay
//
//  Created by milker90 on 2022/9/16.
//

#import "Utils.h"

@implementation Utils

+ (BOOL)isValidString:(NSString *)str {
    if (!str || ![str isKindOfClass:[NSString class]] || str.length == 0) {
        return NO;
    }
    return YES;
}

+ (NSDictionary *)parseQueryString:(NSString *)queryStr {
    if (![Utils isValidString:queryStr]) {
        return nil;
    }
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    NSArray *strs = [queryStr componentsSeparatedByString:@"&"];
    for (NSString *str in strs) {
        NSArray *arr = [str componentsSeparatedByString:@"="];
        if (arr.count == 2) {
            [dic setObject:arr[1] forKey:arr[0]];
        }
    }
    
    return dic;
}

@end
