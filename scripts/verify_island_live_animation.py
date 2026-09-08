#!/usr/bin/env python3
"""Run production Island media functions against real UIKit/Core Animation.

Only the process transport is replaced by local Objective-C dispatch. This is
an iOS Simulator app; it cannot access SpringBoard or prepare kernel access.
"""
import argparse
from pathlib import Path
import plistlib
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument('simulator')
parser.add_argument('frames', type=Path)
args = parser.parse_args()
repo = Path(__file__).resolve().parents[1]
source = (repo / 'lara/kexploit/pe/rc.m').read_text()


def block(marker):
    start = source.index(marker)
    opening = source.index('{', start)
    end, depth = opening + 1, 1
    while depth:
        depth += (source[end] == '{') - (source[end] == '}')
        end += 1
    return source[start:end]


native = '\n'.join(block(marker) for marker in [
    'static bool eagle_verify_island_live_animation(',
    'static bool eagle_install_island_live_texture(',
])
prefix = r'''
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/message.h>
#include <pthread.h>
#include <stdarg.h>
@interface RemoteCall : NSObject
@property BOOL healthy;
@property BOOL lastCallTimedOut;
@end
@implementation RemoteCall
@end
static pthread_mutex_t eagle_island_live_lock = PTHREAD_MUTEX_INITIALIZER;
static char eagle_island_live_directory[4096];
static BOOL testReduceMotion = NO;
#define UIAccessibilityIsReduceMotionEnabled() testReduceMotion
static uint64_t eagle_cached_sel(RemoteCall *p, const char *name) { return (uint64_t)sel_registerName(name); }
static uint64_t eagle_cached_class(RemoteCall *p, const char *name) { return (uint64_t)objc_getClass(name); }
static uint64_t eagle_cached_NSString(RemoteCall *p, const char *s) { return (uint64_t)[NSString stringWithUTF8String:s]; }
static uint64_t remote_msg(RemoteCall *p,uint64_t obj,uint64_t sel,uint64_t a,uint64_t b,uint64_t c,uint64_t d) {
    return ((uint64_t(*)(id,SEL,uint64_t,uint64_t,uint64_t,uint64_t))objc_msgSend)((id)obj,(SEL)sel,a,b,c,d);
}
static uint64_t eagle_cached_safe_remote_msg(RemoteCall *p,uint64_t obj,const char *sel,uint64_t a,uint64_t b,uint64_t c,uint64_t d) {
    return remote_msg(p,obj,eagle_cached_sel(p,sel),a,b,c,d);
}
static uint64_t eagle_main_msg(RemoteCall *p,uint64_t obj,const char *sel,uint64_t a,uint64_t b,uint64_t c,uint64_t d) {
    NSCAssert(NSThread.isMainThread,@"UIKit must run on main");
    return eagle_cached_safe_remote_msg(p,obj,sel,a,b,c,d);
}
static bool eagle_main_send(RemoteCall *p,uint64_t obj,const char *sel,uint64_t a,uint64_t b,uint64_t c,uint64_t d) {
    eagle_main_msg(p,obj,sel,a,b,c,d); return true;
}
static uint64_t eagle_build_remote_image(RemoteCall *p,NSData *bytes,const char *label) {
    return (uint64_t)[[UIImage imageWithData:bytes] retain];
}
static bool eagle_set_remote_decimal_value(RemoteCall *p,uint64_t obj,const char *key,const char *value) {
    [(id)obj setValue:@(atof(value)) forKey:[NSString stringWithUTF8String:key]]; return true;
}
static void eagle_island_trace(const char *stage,const char *format,...) {
    printf("%s ",stage); va_list args; va_start(args,format); vprintf(format,args); va_end(args); puts("");
}
'''
main = r'''
static void require(BOOL good, NSString *message) {
    if (!good) { NSLog(@"FAIL: %@",message); exit(1); }
}
@interface TestApp : UIResponder <UIApplicationDelegate>
@property(nonatomic,retain) UIWindow *window;
@end
@implementation TestApp
- (BOOL)application:(UIApplication*)app didFinishLaunchingWithOptions:(NSDictionary*)options {
    self.window = [[[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds] autorelease];
    self.window.rootViewController = [[[UIViewController alloc] init] autorelease];
    self.window.rootViewController.view.backgroundColor = UIColor.blackColor;
    [self.window makeKeyAndVisible];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC/4),dispatch_get_main_queue(),^{ [self check]; });
    return YES;
}
- (void)check {
    NSString *frames = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"frames"];
    strlcpy(eagle_island_live_directory,frames.UTF8String,sizeof(eagle_island_live_directory));
    RemoteCall *proc = [RemoteCall new]; proc.healthy=YES;
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(114,100,174,67)];
    CGRect original = view.frame;
    require(eagle_install_island_live_texture(proc,(uint64_t)view.layer,false),@"Detached poster stage");
    require(view.layer.contents != nil,@"First frame present");
    CGImageRef poster = (CGImageRef)view.layer.contents;
    require(CGImageGetWidth(poster) == 600 && CGImageGetHeight(poster) == 250,
            @"Runtime texture has a bounded 600x250 memory footprint");
    require([view.layer animationForKey:@"eagle.islandGallery.live"] == nil,@"No animation on detached poster");
    require(!eagle_verify_island_live_animation(proc,(uint64_t)view.layer),@"Still is not verified as Live");
    [self.window.rootViewController.view addSubview:view];
    require(view.window != nil,@"Attached candidate has window");
    require(eagle_install_island_live_texture(proc,(uint64_t)view.layer,true),@"Attached Live installs");
    require(CGRectEqualToRect(original,view.frame),@"Vortex geometry unchanged");
    CAKeyframeAnimation *animation = (id)[view.layer animationForKey:@"eagle.islandGallery.live"];
    require(animation.values.count == 17 && fabs(animation.duration - 17.0/6.0)<0.00001,@"17 frames at 6 FPS");
    require([animation.keyPath isEqual:@"contents"] && [animation.calculationMode isEqual:kCAAnimationDiscrete],@"Discrete contents playback");
    require(animation.repeatCount>1000,@"Persistent looping");
    [CATransaction flush];
    NSMutableSet *seen = [NSMutableSet new];
    __block int samples = 0;
    [NSTimer scheduledTimerWithTimeInterval:0.2 repeats:YES block:^(NSTimer *timer) {
        CALayer *presentation = view.layer.presentationLayer;
        if (presentation.contents) {
            CGImageRef cg=(CGImageRef)presentation.contents;
            if (CFGetTypeID(cg)==CGImageGetTypeID()) {
                CFDataRef data=CGDataProviderCopyData(CGImageGetDataProvider(cg));
                if(data) { [seen addObject:(NSData*)data]; CFRelease(data); }
            }
        }
        require(eagle_verify_island_live_animation(proc,(uint64_t)view.layer),@"Live key remains installed across commits");
        if (++samples < 18) return;
        [timer invalidate];
        require(seen.count >= 3,[NSString stringWithFormat:@"Presentation must move; distinct frames=%lu",(unsigned long)seen.count]);
        [view.layer removeAnimationForKey:@"eagle.islandGallery.live"];
        require(!eagle_verify_island_live_animation(proc,(uint64_t)view.layer),@"Removed animation must fail verification");
        testReduceMotion=YES;
        require(eagle_install_island_live_texture(proc,(uint64_t)view.layer,true),@"Reduce Motion installs poster");
        require([view.layer animationForKey:@"eagle.islandGallery.live"]==nil,@"Reduce Motion has no animation");
        testReduceMotion=NO;
        eagle_island_live_directory[0]='\0';
        require(!eagle_install_island_live_texture(proc,(uint64_t)view.layer,false),@"Invalid media rejected");
        NSLog(@"PASS: production Island installer; detached poster, attached moving presentation (%lu distinct frames), loop survives commits, exact geometry, removed-key rejection, Reduce Motion, invalid media",(unsigned long)seen.count);
        exit(0);
    }];
}
@end
int main(int argc,char **argv) { @autoreleasepool { return UIApplicationMain(argc,argv,nil,@"TestApp"); } }
'''
work = Path(tempfile.mkdtemp(prefix='eagle-island-animation-qa-'))
app = work/'IslandAnimationTest.app'
app.mkdir()
(app/'Info.plist').write_bytes(plistlib.dumps({
    'CFBundleIdentifier':'local.eagle.island-animation-check', 'CFBundleExecutable':'IslandAnimationTest',
    'CFBundleName':'Island Animation Check', 'CFBundlePackageType':'APPL',
    'CFBundleVersion':'1','CFBundleShortVersionString':'1','MinimumOSVersion':'16.0',
    'UIDeviceFamily':[1], 'UILaunchScreen':{},
}))
(work/'Test.m').write_text(prefix+native+main)
subprocess.run(['cp','-R',str(args.frames),str(app/'frames')],check=True)
sdk = subprocess.check_output(['xcrun','--sdk','iphonesimulator','--show-sdk-path'],text=True).strip()
subprocess.run(['xcrun','--sdk','iphonesimulator','clang','-fno-objc-arc','-fmodules','-target',
    'arm64-apple-ios16.0-simulator','-isysroot',sdk,'-framework','UIKit','-framework','QuartzCore',
    str(work/'Test.m'),'-o',str(app/'IslandAnimationTest')],check=True)
subprocess.run(['codesign','--force','--sign','-',str(app)],check=True)
subprocess.run(['xcrun','simctl','install',args.simulator,str(app)],check=True)
subprocess.run(['xcrun','simctl','launch','--console','--terminate-running-process',args.simulator,
    'local.eagle.island-animation-check'],check=True)
print('Artifacts:',work)
