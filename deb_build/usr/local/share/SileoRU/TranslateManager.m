#import "TranslateManager.h"
#import "NetworkUtil.h"

#define PREFS @"com.yourname.sileoru"

@interface TranslateManager ()
@property NSUserDefaults *disk;
@property NSCache *memory;
@end

@implementation TranslateManager

+ (instancetype)shared {
    static TranslateManager *m;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        m = [TranslateManager new];
        m.disk = [[NSUserDefaults alloc] initWithSuiteName:PREFS];
        m.memory = [NSCache new];
    });
    return m;
}

- (BOOL)enabled {
    return ![self.disk objectForKey:@"Enabled"] ||
           [self.disk boolForKey:@"Enabled"];
}

- (BOOL)wifiOnly {
    return ![self.disk objectForKey:@"WifiOnly"] ||
           [self.disk boolForKey:@"WifiOnly"];
}

- (BOOL)isRussian:(NSString *)text {
    NSRegularExpression *re =
    [NSRegularExpression regularExpressionWithPattern:@"[А-Яа-я]"
                                             options:0 error:nil];
    return [re numberOfMatchesInString:text options:0
                                 range:NSMakeRange(0, text.length)] > 5;
}

- (void)translateIfNeeded:(NSString *)text
               completion:(void(^)(NSString *))cb {

    if (!self.enabled || text.length < 120 || [self isRussian:text]) {
        cb(text); return;
    }

    NSString *cached = [self.disk stringForKey:text];
    if (cached) { cb(cached); return; }

    if (self.wifiOnly && ![NetworkUtil isOnWiFi]) {
        cb(text); return;
    }

    NSURL *url = [NSURL URLWithString:@"https://libretranslate.com/translate"];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = @"POST";
    req.timeoutInterval = 8.0;

    NSString *body =
    [NSString stringWithFormat:
     @"q=%@&source=auto&target=ru&format=text",
     [text stringByAddingPercentEncodingWithAllowedCharacters:
      NSCharacterSet.URLQueryAllowedCharacterSet]];

    req.HTTPBody = [body dataUsingEncoding:NSUTF8StringEncoding];

    [[NSURLSession.sharedSession dataTaskWithRequest:req
    completionHandler:^(NSData *data, NSURLResponse *r, NSError *e) {
        if (!data || e) { cb(text); return; }
        NSDictionary *json =
        [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSString *tr = json[@"translatedText"];
        if (tr.length) {
            [self.disk setObject:tr forKey:text];
            cb(tr);
        } else cb(text);
    }] resume];
}
@end
