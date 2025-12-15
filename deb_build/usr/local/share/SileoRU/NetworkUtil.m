#import "NetworkUtil.h"
#import <SystemConfiguration/SystemConfiguration.h>

@implementation NetworkUtil
+ (BOOL)isOnWiFi {
    SCNetworkReachabilityRef ref =
    SCNetworkReachabilityCreateWithName(NULL, "apple.com");
    SCNetworkReachabilityFlags flags;
    BOOL ok = SCNetworkReachabilityGetFlags(ref, &flags);
    CFRelease(ref);
    return ok && (flags & kSCNetworkReachabilityFlagsIsWWAN) == 0;
}
@end
