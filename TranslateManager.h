#import <Foundation/Foundation.h>
@interface TranslateManager : NSObject
+ (instancetype)shared;
- (void)translateIfNeeded:(NSString *)text
               completion:(void(^)(NSString *result))completion;
@end
