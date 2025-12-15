%config(generator=internal)

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static NSMutableDictionary *translationCache;

__attribute__((constructor))
static void initCache() {
    translationCache = [NSMutableDictionary dictionary];
}

static BOOL IsInSileoPackageContext(UIView *view) {
    UIResponder *responder = view.nextResponder;
    while (responder) {
        if ([responder isKindOfClass:UIViewController.class]) {
            NSString *cls = NSStringFromClass(responder.class);
            if ([cls containsString:@"Package"]) return YES;
        }
        responder = [responder nextResponder];
    }
    return NO;
}

static BOOL LooksLikePlainBodyText(NSString *s) {
    if (!s || s.length == 0) return NO;
    if ([s hasPrefix:@"#"] || [s containsString:@"```"] || [s containsString:@"http://"] || [s containsString:@"https://"])
        return NO;
    return s.length > 10 && [s containsString:@" "];
}

static NSString* TranslateENtoRU(NSString *src) {
    if (!src) return src;

    // Кэш: если уже переводили — вернуть
    NSString *cached = translationCache[src];
    if (cached) return cached;

    NSCharacterSet *cyrillic = [NSCharacterSet characterSetWithRange:NSMakeRange(0x0400, 0x0500 - 0x0400)];
    if ([src rangeOfCharacterFromSet:cyrillic].location != NSNotFound) {
        translationCache[src] = src;
        return src;
    }

    NSMutableString *out = [src mutableCopy];

    NSDictionary *glossEN = @{
        @"compatibility": @"совместимость",
        @"incompatible": @"несовместимо",
        @"bug fixes": @"исправления ошибок",
        @"fixes": @"исправления",
        @"improvements": @"улучшения",
        @"features": @"функции",
        @"description": @"описание",
        @"support": @"поддержка",
        @"requires": @"требуется",
        @"rootless": @"rootless",
        @"dopamine": @"Dopamine",
        @"tested": @"протестировано",
        @"uninstall": @"удалите",
        @"issues": @"проблемы",
        @"click to add source": @"нажмите, чтобы добавить источник",
        @"free download": @"бесплатная загрузка",
        @"theme": @"тема",
        @"fonts": @"шрифты",
        @"mask": @"маска"
    };

    NSDictionary *glossCN = @{
        @"不兼容": @"несовместимо",
        @"您的系统": @"ваша система",
        @"点击添加主题源": @"нажмите, чтобы добавить источник тем",
        @"免费下载": @"бесплатно",
        @"有问题请卸载": @"при проблемах удалите",
        @"支持多巴胺越狱": @"поддержка джейлбрейка Dopamine"
    };

    [glossEN enumerateKeysAndObjectsUsingBlock:^(NSString *en, NSString *ru, BOOL *stop) {
        [out replaceOccurrencesOfString:en withString:ru options:NSCaseInsensitiveSearch range:NSMakeRange(0, out.length)];
    }];
    [glossCN enumerateKeysAndObjectsUsingBlock:^(NSString *cn, NSString *ru, BOOL *stop) {
        [out replaceOccurrencesOfString:cn withString:ru options:0 range:NSMakeRange(0, out.length)];
    }];

    [out replaceOccurrencesOfString:@"Not compatible" withString:@"Не совместимо" options:NSCaseInsensitiveSearch range:NSMakeRange(0, out.length)];
    [out replaceOccurrencesOfString:@"System Info" withString:@"Системная информация" options:NSCaseInsensitiveSearch range:NSMakeRange(0, out.length)];
    [out replaceOccurrencesOfString:@"Package" withString:@"Пакет" options:NSCaseInsensitiveSearch range:NSMakeRange(0, out.length)];

    translationCache[src] = out;
    return out;
}

%hook UILabel
- (void)setText:(NSString *)text {
    if (text && IsInSileoPackageContext(self) && LooksLikePlainBodyText(text)) {
        NSString *ru = TranslateENtoRU(text);
        %orig(ru ?: text);
        return;
    }
    %orig(text);
}
%end

%hook UILabel
- (void)setAttributedText:(NSAttributedString *)text {
    if (text && IsInSileoPackageContext(self)) {
        NSString *plain = text.string;
        if (LooksLikePlainBodyText(plain)) {
            NSString *ru = TranslateENtoRU(plain);
            if (ru && ![ru isEqualToString:plain]) {
                NSMutableAttributedString *mut = [text mutableCopy];
                [mut replaceCharactersInRange:NSMakeRange(0, mut.length) withString:ru];
                %orig(mut);
                return;
            }
        }
    }
    %orig(text);
}
%end
