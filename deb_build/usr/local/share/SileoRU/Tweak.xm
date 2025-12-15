#import <UIKit/UIKit.h>
#import "TranslateManager.h"

static BOOL IsSileo() {
    return [[[NSBundle mainBundle] bundleIdentifier]
            isEqualToString:@"org.coolstar.SileoStore"];
}

static BOOL IsPackageDescription(UITextView *tv) {
    return tv.scrollEnabled &&
           tv.text.length > 120 &&
           tv.frame.size.height > 100;
}

%hook UITextView
- (void)setText:(NSString *)text {
    if (IsSileo() && IsPackageDescription(self)) {
        [[TranslateManager shared] translateIfNeeded:text
         completion:^(NSString *t) {
            dispatch_async(dispatch_get_main_queue(), ^{
                %orig(t);
            });
        }];
        return;
    }
    %orig(text);
}
%end
