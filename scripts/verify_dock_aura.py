#!/usr/bin/env python3
"""Run production Dock palette and overlay on real UIKit simulator views.

Only RemoteCall transport is substituted with local Objective-C dispatch.
No kernel or physical SpringBoard access is performed.
"""
import argparse
import ast
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

# Reuse the isolated transport definitions, not the executable Island test.
tree = ast.parse((root / "scripts/verify_island_pulse.py").read_text())
prefix = next(ast.literal_eval(node.value) for node in tree.body
              if isinstance(node, ast.Assign) and any(isinstance(t, ast.Name) and t.id == "prefix" for t in node.targets))
prefix += r'''
static struct { bool budgetExceeded; } gEagleRuntimeCache;
static void eagle_aura_trace(const char *stage,const char *format,...) {}
static bool eagle_main_send(RemoteCall *p,uint64_t o,const char *s,uint64_t a,uint64_t b,uint64_t c,uint64_t d) {
    if (!p.healthy || p.lastCallTimedOut) return false;
    eagle_main_msg(p,o,s,a,b,c,d); return p.healthy && !p.lastCallTimedOut;
}
static bool eagle_main_set_rect(RemoteCall *p,uint64_t o,const char *s,CGRect frame) {
    [(UIView*)o setFrame:frame]; return true;
}
static bool eagle_main_set_size(RemoteCall *p,uint64_t o,const char *s,CGSize size) {
    [(CALayer*)o setShadowOffset:size]; return true;
}
static bool eagle_dock_set_decimal(RemoteCall *p,uint64_t o,const char *k,const char *v) {
    return eagle_set_remote_decimal_value(p,o,k,v);
}
#define RemoteArbCall(p, f, v) ([(id)(v) release], 0)
'''
native = "\n".join(block(marker) for marker in [
    "static uint64_t eagle_dock_palette_color(",
    "static void eagle_add_island_pulse(",
    "static bool eagle_verify_island_pulse(",
    "static void eagle_aura_remove_dock_overlay(",
    "static bool eagle_aura_install_working_dock_overlay(",
])
main = r'''
static void check(BOOL ok,NSString *message) { if(!ok) { NSLog(@"FAIL: %@",message); exit(1); } }
@interface TestApp : UIResponder <UIApplicationDelegate>
@property(nonatomic,retain) UIWindow *window;
@end
@implementation TestApp
- (BOOL)application:(UIApplication*)app didFinishLaunchingWithOptions:(NSDictionary*)options {
    self.window = [[[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds] autorelease];
    self.window.rootViewController = [[[UIViewController alloc] init] autorelease];
    [self.window makeKeyAndVisible];
    dispatch_async(dispatch_get_main_queue(),^{ [self run]; });
    return YES;
}
- (void)run {
    RemoteCall *p=[RemoteCall new]; p.healthy=YES;
    UIView *dock=[[UIView alloc] initWithFrame:CGRectMake(0,300,393,110)];
    [self.window.rootViewController.view addSubview:dock];
    // All shipped presets plus representative custom color families.
    const int rgb[][3]={{26,199,255},{158,64,255},{255,41,158},{107,255,61},{255,0,0},{0,0,255},{255,255,0},{255,165,0}};
    NSArray *expected=@[UIColor.systemCyanColor,UIColor.systemPurpleColor,UIColor.systemPinkColor,UIColor.systemGreenColor,
        UIColor.systemRedColor,UIColor.systemBlueColor,UIColor.systemYellowColor,UIColor.systemOrangeColor];
    CGRect frame=CGRectMake(18,3,357,90);
    for(int index=0;index<8;index++) {
        uint64_t color=eagle_dock_palette_color(p,rgb[index][0],rgb[index][1],rgb[index][2]);
        check([(UIColor*)color isEqual:expected[index]],[NSString stringWithFormat:@"Palette family %d",index]);
        for(int mode=1;mode<=2;mode++) {
            check(eagle_aura_install_working_dock_overlay(p,(uint64_t)dock,123,frame,color,color,mode,"27","0.8","26",false,"qa"),@"Overlay applied");
            UIView *view=[dock viewWithTag:123];
            check(dock.subviews.count==1,@"Reapply leaves one overlay");
            check(CGColorEqualToColor(view.layer.borderColor,[(UIColor*)color CGColor]),@"Border retains selected color");
            check(CGColorEqualToColor(view.layer.shadowColor,[(UIColor*)color CGColor]),@"Glow retains selected color");
            check(CGRectEqualToRect(view.frame,frame),@"Geometry preserved");
            check(!view.userInteractionEnabled && !view.clipsToBounds && !view.layer.masksToBounds,@"No touch interception or local shadow clipping");
            check((view.layer.animationKeys.count>0)==(mode==2),@"Pulse present / Glow static");
        }
    }
    CALayer *pulse=[dock viewWithTag:123].layer;
    [CATransaction flush];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,200*NSEC_PER_MSEC),dispatch_get_main_queue(),^{
        float first=pulse.presentationLayer.shadowOpacity;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,250*NSEC_PER_MSEC),dispatch_get_main_queue(),^{
            check(fabsf(first-pulse.presentationLayer.shadowOpacity)>.01,@"Pulse actually progresses between rendered frames");
            uint64_t purple=(uint64_t)UIColor.systemPurpleColor;
            dropAnimation=YES;
            check(!eagle_aura_install_working_dock_overlay(p,(uint64_t)dock,123,frame,purple,purple,2,"27","0.8","26",false,"qa"),@"Missing Pulse cannot report success");
            check([dock viewWithTag:123]==nil,@"Failed candidate removed");
            dropAnimation=NO;
            check(eagle_aura_install_working_dock_overlay(p,(uint64_t)dock,123,frame,purple,purple,1,"27","0.8","26",false,"qa"),@"Static retry succeeds");
            eagle_aura_remove_dock_overlay(p,(uint64_t)dock,123);
            check(dock.subviews.count==0,@"Remove cleans overlay");
            puts("PASS: Dock palette/color changes, real Pulse progression, static Glow, geometry, reapply, removal and rejected missing animation");
            fflush(stdout); exit(0);
        });
    });
}
@end
int main(int argc,char **argv) { @autoreleasepool { return UIApplicationMain(argc,argv,nil,@"TestApp"); } }
'''
with tempfile.TemporaryDirectory(prefix="eagle-dock-aura-qa-") as directory:
    directory = Path(directory)
    app = directory / "DockQA.app"
    app.mkdir()
    code = directory / "main.m"
    code.write_text(prefix + native + main)
    (app / "Info.plist").write_bytes(plistlib.dumps({
        "CFBundleIdentifier": "local.eagle.dock-aura-qa", "CFBundleExecutable": "DockQA",
        "CFBundleName": "DockQA", "CFBundlePackageType": "APPL", "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1", "MinimumOSVersion": "16.0", "UIDeviceFamily": [1], "UILaunchScreen": {},
    }))
    sdk = subprocess.check_output(["xcrun", "--sdk", "iphonesimulator", "--show-sdk-path"], text=True).strip()
    subprocess.run(["xcrun", "clang", "-target", "arm64-apple-ios16.0-simulator", "-isysroot", sdk,
                    "-fno-objc-arc", "-fblocks", str(code), "-framework", "UIKit", "-framework", "QuartzCore",
                    "-framework", "Foundation", "-framework", "CoreGraphics", "-lobjc", "-o", str(app / "DockQA")], check=True)
    subprocess.run(["codesign", "--force", "--sign", "-", str(app)], check=True)
    subprocess.run(["xcrun", "simctl", "install", args.simulator, str(app)], check=True)
    result = subprocess.run(["xcrun", "simctl", "launch", "--console", args.simulator, "local.eagle.dock-aura-qa"],
                            capture_output=True, text=True, timeout=45)
    print(result.stdout)
    if "PASS: Dock palette" not in result.stdout:
        raise RuntimeError(result.stderr + result.stdout)
