    #import <Cocoa/Cocoa.h>

    @interface AppDelegate : NSObject <NSApplicationDelegate,NSWindowDelegate>

    - ( void ) addLog : ( NSString* ) string;

    @end

    @interface MyWindow : NSWindow
    
    @end

    @interface MyTextView : NSTextView
    
    @end
