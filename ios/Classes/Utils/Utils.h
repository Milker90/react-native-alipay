//
//  Utils.h
//  react-native-alipay
//
//  Created by milker90 on 2022/9/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Utils : NSObject

+ (BOOL)isValidString:(NSString *)str;
+ (NSDictionary *)parseQueryString:(NSString *)queryStr;

@end

NS_ASSUME_NONNULL_END
