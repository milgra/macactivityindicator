    #import <Cocoa/Cocoa.h>

    @interface AppDelegate : NSObject <NSApplicationDelegate,NSWindowDelegate>

    @property (strong, nonatomic) NSStatusItem *statusItem;

    - ( void ) addLog : ( NSString* ) string;

    @end

    @interface MyWindow : NSWindow
    
    @end
