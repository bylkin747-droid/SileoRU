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

    NSLog(@"SileoRU: translateIfNeeded called enabled=%d wifiOnly=%d length=%lu", (int)self.enabled, (int)self.wifiOnly, (unsigned long)text.length);

    if (!self.enabled || text.length < 120 || [self isRussian:text]) {
        NSLog(@"SileoRU: skipping translate (disabled/short/russian)");
        cb(text); return;
    }

    NSString *cached = [self.disk stringForKey:text];
    if (cached) { NSLog(@"SileoRU: cache hit"); cb(cached); return; }

    if (self.wifiOnly && ![NetworkUtil isOnWiFi]) {
        NSLog(@"SileoRU: wifi-only enabled and not on WiFi");
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
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];

    NSLog(@"SileoRU: sending request to %@ (body length=%lu)", url.absoluteString, (unsigned long)req.HTTPBody.length);

    [[NSURLSession.sharedSession dataTaskWithRequest:req
    completionHandler:^(NSData *data, NSURLResponse *r, NSError *e) {
        if (!data || e) { NSLog(@"SileoRU: request error: %@", e); cb(text); return; }
        NSError *jsonErr = nil;
        id parsed = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonErr];
        if (jsonErr) {
            NSLog(@"SileoRU: json parse error: %@", jsonErr);
            cb(text); return;
        }

        // Try LibreTranslate style response: { "translatedText": "..." }
        if ([parsed isKindOfClass:[NSDictionary class]]) {
            NSString *tr = parsed[@"translatedText"];
            NSLog(@"SileoRU: response translatedText length=%lu", (unsigned long)(tr ? tr.length : 0));
            if (tr.length) {
                [self.disk setObject:tr forKey:text];
                [self.disk synchronize];
                cb(tr); return;
            }
        }

        // Try Google unofficial format: [["...", "..."] , ...]
        if ([parsed isKindOfClass:[NSArray class]]) {
            NSArray *a = (NSArray *)parsed;
            if (a.count > 0 && [a[0] isKindOfClass:[NSArray class]]) {
                NSArray *first = (NSArray *)a[0];
                if (first.count > 0 && [first[0] isKindOfClass:[NSArray class]]) {
                    NSArray *inner = (NSArray *)first[0];
                    if (inner.count > 0 && [inner[0] isKindOfClass:[NSString class]]) {
                        NSString *tr = inner[0];
                        if (tr.length) {
                            NSLog(@"SileoRU: google-format translation length=%lu", (unsigned long)tr.length);
                            [self.disk setObject:tr forKey:text];
                            [self.disk synchronize];
                            cb(tr); return;
                        }
                    }
                }
            }
        }

        NSLog(@"SileoRU: no usable translation in response, returning original");
        cb(text);
    }] resume];
}
@end
