#!/usr/bin/env python3
"""Run production Pulse functions on real simulator CALayers with local transport."""
import argparse
from pathlib import Path
import plistlib
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument("simulator")
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
source = (root / "lara/kexploit/pe/rc.m").read_text()

def block(marker):
    start = source.index(marker)
    end = source.index("{", start) + 1
    depth = 1
    while depth:
        depth += (source[end] == "{") - (source[end] == "}")
        end += 1
    return source[start:end]

# Check the actual transaction uses the helper before promoting the candidate.
install = block("static bool eagle_install_island_fallback(")
assert install.index("if (!geometryVerified)") < install.index("eagle_start_verified_island_pulse(") < install.index("bool promoted")
assert "eagle_add_island_pulse" not in block("static bool eagle_style_island_fallback_view(")
native = "\n".join(block(name) for name in [
    "static void eagle_add_island_pulse(",
    "static bool eagle_verify_island_pulse(",
    "static bool eagle_start_verified_island_pulse(",
])
prefix = r'''
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/message.h>
#include <unistd.h>
@interface RemoteCall : NSObject
@property BOOL healthy;
@property BOOL lastCallTimedOut;
@end
@implementation RemoteCall
@end
static BOOL dropAnimation = NO;
static int rc_runtime_ios_major_version(void) { return 18; }
static uint64_t eagle_cached_class(RemoteCall *p,const char *s) { return (uint64_t)objc_getClass(s); }
static uint64_t eagle_cached_sel(RemoteCall *p,const char *s) { return (uint64_t)sel_registerName(s); }
static uint64_t eagle_cached_NSString(RemoteCall *p,const char *s) { return (uint64_t)[NSString stringWithUTF8String:s]; }
static uint64_t eagle_remote_decimal(RemoteCall *p,const char *s) { return (uint64_t)[NSDecimalNumber decimalNumberWithString:[NSString stringWithUTF8String:s]]; }
static uint64_t remote_msg(RemoteCall *p,uint64_t o,uint64_t s,uint64_t a,uint64_t b,uint64_t c,uint64_t d) {
    return ((uint64_t(*)(id,SEL,uint64_t,uint64_t,uint64_t,uint64_t))objc_msgSend)((id)o,(SEL)s,a,b,c,d);
}
static uint64_t eagle_cached_safe_remote_msg(RemoteCall *p,uint64_t o,const char *s,uint64_t a,uint64_t b,uint64_t c,uint64_t d) {
    return remote_msg(p,o,eagle_cached_sel(p,s),a,b,c,d);
}
static uint64_t eagle_main_msg(RemoteCall *p,uint64_t o,const char *s,uint64_t a,uint64_t b,uint64_t c,uint64_t d) {
    NSCAssert(NSThread.isMainThread,@"Must remain on main");
    if (dropAnimation && strcmp(s,"addAnimation:forKey:")==0) return 0;
    return eagle_cached_safe_remote_msg(p,o,s,a,b,c,d);
}
static bool eagle_cached_remote_responds(RemoteCall *p,uint64_t o,const char *s) { return [(id)o respondsToSelector:sel_registerName(s)]; }
static bool eagle_set_remote_decimal_value(RemoteCall *p,uint64_t o,const char *k,const char *v) {
    [(id)o setValue:@(atof(v)) forKey:[NSString stringWithUTF8String:k]]; return true;
}
'''
main = r'''
static void check(BOOL value, NSString *message) {
    if (!value) { NSLog(@"FAIL: %@",message); exit(1); }
}
@interface TestApp : UIResponder <UIApplicationDelegate>
@property(nonatomic,retain) UIWindow *window;
@end
@implementation TestApp
- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)options {
    self.window = [[[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds] autorelease];
    self.window.rootViewController = [[[UIViewController alloc] init] autorelease];
    [self.window makeKeyAndVisible];
    dispatch_async(dispatch_get_main_queue(),^{ [self run]; });
    return YES;
}
- (void)run {
    RemoteCall *p = [RemoteCall new]; p.healthy = YES;
    UIView *candidate = [[UIView alloc] initWithFrame:CGRectMake(120,13,134,39)];
    candidate.layer.shadowOpacity = 1;
    candidate.layer.borderWidth = 2;
    CGRect frame = candidate.frame;
    check(!eagle_start_verified_island_pulse(p,(uint64_t)candidate,(uint64_t)candidate.layer),@"Reject detached candidate");
    check(candidate.layer.animationKeys.count==0,@"Detached candidate unmodified");
    [self.window.rootViewController.view addSubview:candidate];
    check(eagle_start_verified_island_pulse(p,(uint64_t)candidate,(uint64_t)candidate.layer),@"Attached pulse verified");
    CABasicAnimation *animation = (id)[candidate.layer animationForKey:@"eagle.islandAura.pulse"];
    check([animation.keyPath isEqualToString:@"shadowOpacity"],@"Only shadow animates");
    check(fabs(animation.duration-1.15)<0.0001 && animation.autoreverses,@"Timing preserved");
    check(fabs([animation.fromValue doubleValue]-.35)<.0001 && fabs([animation.toValue doubleValue]-.95)<.0001,@"Amplitude preserved");
    check(CGRectEqualToRect(frame,candidate.frame) && candidate.layer.borderWidth==2,@"Geometry and border preserved");
    [CATransaction flush];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,150*NSEC_PER_MSEC),dispatch_get_main_queue(),^{
        check(eagle_verify_island_pulse(p,(uint64_t)candidate.layer),@"Survives rendering commit");
        [candidate.layer removeAllAnimations];
        dropAnimation=YES;
        check(!eagle_start_verified_island_pulse(p,(uint64_t)candidate,(uint64_t)candidate.layer),@"Silent add failure must not report success");
        dropAnimation=NO; p.lastCallTimedOut=YES;
        check(!eagle_start_verified_island_pulse(p,(uint64_t)candidate,(uint64_t)candidate.layer),@"Timeout rejected");
        p.lastCallTimedOut=NO; p.healthy=NO;
        check(!eagle_start_verified_island_pulse(p,(uint64_t)candidate,(uint64_t)candidate.layer),@"Unhealthy channel rejected");
        puts("PASS: attached Pulse survives commit; timing/geometry preserved; detached, dropped, timed-out and unhealthy cases rejected");
        fflush(stdout); exit(0);
    });
}
@end
int main(int argc,char **argv) { @autoreleasepool { return UIApplicationMain(argc,argv,nil,@"TestApp"); } }
'''
with tempfile.TemporaryDirectory(prefix="eagle-pulse-qa-") as work:
    work = Path(work)
    app = work / "PulseQA.app"
    app.mkdir()
    code = work / "main.m"
    code.write_text(prefix + native + main)
    (app / "Info.plist").write_bytes(plistlib.dumps({
        "CFBundleIdentifier": "local.eagle.pulse-qa", "CFBundleExecutable": "PulseQA",
        "CFBundleName": "PulseQA", "CFBundlePackageType": "APPL", "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1", "MinimumOSVersion": "16.0", "UIDeviceFamily": [1], "UILaunchScreen": {},
    }))
    sdk = subprocess.check_output(["xcrun", "--sdk", "iphonesimulator", "--show-sdk-path"], text=True).strip()
    subprocess.run(["xcrun", "clang", "-target", "arm64-apple-ios16.0-simulator", "-isysroot", sdk,
                    "-fno-objc-arc", "-fblocks", str(code), "-framework", "UIKit", "-framework", "QuartzCore",
                    "-framework", "Foundation", "-framework", "CoreGraphics", "-lobjc",
                    "-o", str(app / "PulseQA")], check=True)
    subprocess.run(["codesign", "--force", "--sign", "-", str(app)], check=True)
    subprocess.run(["xcrun", "simctl", "install", args.simulator, str(app)], check=True)
    result = subprocess.run(["xcrun", "simctl", "launch", "--console", args.simulator, "local.eagle.pulse-qa"],
                            capture_output=True, text=True, timeout=45)
    print(result.stdout)
    if "PASS: attached Pulse" not in result.stdout:
        raise RuntimeError(result.stderr + result.stdout)
