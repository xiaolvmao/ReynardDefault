// ReynardDefault — redirects http(s) opens that target Safari to Reynard.
//
// A plain Objective-C tweak: MSHookMessageEx instead of Logos, so Apelin's
// toolchain can build it on the device. There is no switch: any open aimed at
// a browser in the whitelist is redirected.
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <os/log.h>

// Passed in by apelin/build.sh as a quoted string; the load marker below is
// what apelin_package_confirm_loaded looks for.
#ifndef APELIN_BUILD_ID
#define APELIN_BUILD_ID "unknown"
#endif

// FBSystemServiceOpenApplicationRequest is a private FrontBoardServices class:
// only the property the hook touches is declared, and the class is looked up
// at run time instead of linking the private framework.
@interface FBSystemServiceOpenApplicationRequest : NSObject
@property (nonatomic, copy) NSURL *URL;
@end

static NSString *const kReynardBundleID = @"com.minh-ton.Reynard";
static NSString *const kReynardURLScheme = @"reynard";

static NSArray<NSString *> *RDBrowserBundleIDs(void) {
    static NSArray<NSString *> *bundleIDs;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        bundleIDs = @[
            @"com.apple.mobilesafari",
            @"org.mozilla.ios.Firefox",
            @"com.google.chrome.ios",
            @"com.brave.ios.browser"
        ];
    });
    return bundleIDs;
}

static os_log_t RDLog(void) {
    static os_log_t log;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        log = os_log_create("com.guacforlife.reynarddefault", "tweak");
    });
    return log;
}

// Wrap http(s) URLs as reynard://open?url=<encoded> so iOS routes them via
// the scheme Reynard actually claims. Reynard's SceneDelegate decodes this
// form back to the original URL. Without this, iOS 14 LaunchServices drops
// the http(s) URL after ReynardDefault swaps the bundle ID, because Reynard
// doesn't register http/https handlers in its Info.plist.
//
// The encoding is RFC 3986 unreserved-only: URLQueryAllowedCharacterSet keeps
// & = # ; + % as they are, and the first of them would end the query value
// inside reynard://open?url=….
static NSURL *wrapHTTPURLForReynard(NSURL *original) {
    NSString *scheme = original.scheme.lowercaseString;
    if (![scheme isEqualToString:@"http"] && ![scheme isEqualToString:@"https"]) {
        return nil;
    }
    static NSCharacterSet *unreserved;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        unreserved = [NSCharacterSet
            characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                                              "abcdefghijklmnopqrstuvwxyz"
                                              "0123456789-._~"];
    });
    NSString *encoded = [original.absoluteString
        stringByAddingPercentEncodingWithAllowedCharacters:unreserved];
    if (!encoded) return nil;
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@://open?url=%@",
                                                           kReynardURLScheme, encoded]];
}

static void (*original_setBundleIdentifier)(id, SEL, NSString *);

static void hooked_setBundleIdentifier(id self, SEL _cmd, NSString *bundleIdentifier) {
    if ([RDBrowserBundleIDs() containsObject:bundleIdentifier]) {
        if ([self respondsToSelector:@selector(URL)] &&
            [self respondsToSelector:@selector(setURL:)]) {
            NSURL *wrapped = wrapHTTPURLForReynard(((FBSystemServiceOpenApplicationRequest *)self).URL);
            if (wrapped) ((FBSystemServiceOpenApplicationRequest *)self).URL = wrapped;
        }
        original_setBundleIdentifier(self, _cmd, kReynardBundleID);
    } else {
        original_setBundleIdentifier(self, _cmd, bundleIdentifier);
    }
}

// MSHookMessageEx comes from the injection library loaded in the process
// (ElleKit provides the Substrate API). It is looked up at run time rather than
// linked: -undefined dynamic_lookup would bind the arm64e slice without
// pointer authentication, so the dylib must have no unresolved symbol at all.
typedef void (*RDMSHookMessageExFunc)(Class, SEL, IMP, IMP *);

static RDMSHookMessageExFunc RDMSHookMessageEx(void) {
    static RDMSHookMessageExFunc hook;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        hook = (RDMSHookMessageExFunc)dlsym(RTLD_DEFAULT, "MSHookMessageEx");
    });
    return hook;
}

__attribute__((constructor)) static void RDInitialize(void) {
    os_log(RDLog(), "ApelinLoaded %{public}s", APELIN_BUILD_ID);

    RDMSHookMessageExFunc hook = RDMSHookMessageEx();
    if (hook == NULL) {
        os_log_error(RDLog(), "MSHookMessageEx is missing; no hooks installed");
        return;
    }

    Class requestClass = objc_getClass("FBSystemServiceOpenApplicationRequest");
    if (requestClass == Nil) {
        os_log_error(RDLog(), "FBSystemServiceOpenApplicationRequest is missing; no hooks installed");
        return;
    }

    hook(requestClass, @selector(setBundleIdentifier:),
         (IMP)hooked_setBundleIdentifier, (IMP *)&original_setBundleIdentifier);
    os_log(RDLog(), "hooked -[FBSystemServiceOpenApplicationRequest setBundleIdentifier:]");
}
