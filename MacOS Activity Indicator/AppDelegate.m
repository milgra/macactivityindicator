
    #import "AppDelegate.h"


    @interface AppDelegate ()
    {
        char flag;
        NSWindow *window;
        NSTextView *textview;
        NSScrollView *scrollview;
        NSMutableArray* logs;
        NSStatusItem* statusItem;
        NSString* imageName;
        NSDate* lastLog;
        BOOL isLit;
        BOOL newLog;
    }

    @end

    FSEventStreamRef _eventStream;
    FSEventStreamContext callbackCtx;

    static void CDEventsCallback(
    
        ConstFSEventStreamRef streamRef,
        void *callbackCtxInfo,
        size_t numEvents,
        void *eventPaths, // CFArrayRef
        const FSEventStreamEventFlags eventFlags[],
        const FSEventStreamEventId eventIds[])
    {
        AppDelegate * delegate		= (__bridge AppDelegate *)callbackCtxInfo;
        NSArray *eventPathsArray	= (__bridge NSArray *)eventPaths;
        
        for (NSUInteger i = 0; i < numEvents; ++i)
        {
            NSString* path = [eventPathsArray objectAtIndex:i];
            [delegate addLog: path ];
        }
    }

    @implementation AppDelegate

    - (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

        logs = [ [ NSMutableArray alloc ] init ];
        flag = 0;
        isLit = NO;

        // Version string
        NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
        NSString *versionString = [NSString stringWithFormat:@"Version %@ (build %@)",
                                   bundleInfo[@"CFBundleShortVersionString"],
                                   bundleInfo[@"CFBundleVersion"]
                                   ];
        
        NSMenu *menu = [ [ NSMenu alloc ] init ];

        [ menu addItemWithTitle : @"Show Changes" action : @selector(show) keyEquivalent : @"" ];

        [ menu addItem : [ NSMenuItem separatorItem ] ]; // A thin grey line
        [ menu addItemWithTitle : versionString action : nil keyEquivalent : @"" ];
        [ menu addItem : [ NSMenuItem separatorItem ] ]; // A thin grey line

        [ menu addItemWithTitle : @"Donate if you like the app" action : @selector(support) keyEquivalent : @"" ];
        [ menu addItemWithTitle : @"Check for updates" action : @selector(update) keyEquivalent : @"" ];
        [ menu addItemWithTitle : @"Quit" action : @selector(terminate) keyEquivalent : @"" ];

        statusItem = [ [ [ NSStatusBar systemStatusBar ] statusItemWithLength : NSVariableStatusItemLength ] retain ];
        [statusItem setHighlightMode : NO ];
        [statusItem setToolTip : @"MacOS File Activity Indicator" ];
        [statusItem setImage : [NSImage imageNamed:@"switchIcon.png"] ];
        [statusItem setMenu: menu ];
        [statusItem.image setTemplate:NO];
        
        callbackCtx.version			= 0;
        callbackCtx.info			= (__bridge void *)self;
        callbackCtx.retain			= NULL;
        callbackCtx.release			= NULL;
        callbackCtx.copyDescription	= NULL;

        NSArray *watchedPaths = [ NSArray arrayWithObject : [ NSString stringWithCString: "/" encoding:NSUTF8StringEncoding ] ];
        FSEventStreamCreateFlags creationFlags = kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagWatchRoot | kFSEventStreamCreateFlagIgnoreSelf | kFSEventStreamCreateFlagFileEvents;
        
        _eventStream = FSEventStreamCreate(kCFAllocatorDefault,
                                           &CDEventsCallback,
                                           &callbackCtx,
                                           (__bridge CFArrayRef)watchedPaths,
                                           kFSEventStreamEventIdSinceNow,
                                           (NSTimeInterval)1.0,
                                           (uint) creationFlags);

        FSEventStreamScheduleWithRunLoop(_eventStream,
                                         [[NSRunLoop currentRunLoop] getCFRunLoop],
                                         kCFRunLoopDefaultMode);
        
        if ( !FSEventStreamStart( _eventStream ) )
        {
            [NSException raise:@"CDEventsEventStreamCreationFailureException"
                        format:@"Failed to create event stream."];
        }
        
        [ NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer* timer)
        {
            if ( newLog )
            {
                newLog = NO;
                isLit = !isLit;
                if ( isLit ) imageName = @"iconlit";
                else imageName = @"icondim";
                [self performSelectorOnMainThread:@selector(setImage) withObject:nil waitUntilDone:NO];
            }
        }];
    }

    - ( void ) addLog : ( NSString* ) string
    {
        [ logs insertObject : string atIndex : 0 ];
        if ( [ logs count ] > 100 ) [ logs removeLastObject ];
        
        if ( window != nil && [ window isVisible ] )
        {
            [ [ [ textview textStorage ] mutableString ] setString:[logs componentsJoinedByString: @"\n" ] ];
            [textview setTextColor:[NSColor greenColor]];
            [textview setBackgroundColor:[NSColor blackColor]];
            [textview setFont:[NSFont fontWithName:@"Courier New" size:13]];
        }
        
        [ lastLog release ];
        lastLog = [ [ NSDate alloc ] init ];
        
        newLog = YES;
    }

    - ( void ) setImage
    {
        [statusItem setImage : [NSImage imageNamed:imageName] ];
    }

    - ( void ) windowWillClose:(NSNotification *)notification
    {
        window = nil;
        textview = nil;
        scrollview = nil;
    }

    - (void)show
    {
        if ( window == nil )
        {
            float wth = 900;
            float hth = 600;

            NSRect screenRect = [ [ NSScreen mainScreen ] frame ];
            NSRect windowRect = NSMakeRect( 
                ( screenRect.size.width - wth ) / 2 , 
                ( screenRect.size.height  - hth ) / 2 , 
                wth , 
                hth );
            
            window = [ [ MyWindow alloc ]
                initWithContentRect : windowRect
                styleMask           : NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable
                backing             : NSBackingStoreBuffered
                defer               : YES ];
            
            window.releasedWhenClosed = YES;
            
            scrollview = [ [ NSScrollView alloc ] initWithFrame : NSMakeRect(0, 0, wth, hth) ];
            [scrollview setBorderType : NSNoBorder];
            [scrollview setHasVerticalScroller : YES];
            [scrollview setHasHorizontalScroller : NO];
            [scrollview setAutoresizingMask : NSViewWidthSizable | NSViewHeightSizable ];
            
            NSSize contentSize = [ scrollview contentSize ];

            textview = [[MyTextView alloc] initWithFrame:NSMakeRect(0, 0, contentSize.width, contentSize.height)];
            [textview setMinSize:NSMakeSize(0.0, contentSize.height)];
            [textview setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
            [textview setVerticallyResizable:YES];
            [textview setHorizontallyResizable:NO];
            [textview setAutoresizingMask:NSViewWidthSizable];
            [textview setEditable:NO];
            [textview setSelectable:YES];
            [[textview textContainer] setContainerSize:NSMakeSize(contentSize.width, FLT_MAX)];
            [[textview textContainer] setWidthTracksTextView:YES];
            
            [scrollview setDocumentView:textview];

            [ window setTitle:@"Activity Indicator - Files"];
            [ window setLevel : NSNormalWindowLevel ];
            [ window setDelegate : self ];
            [ window setHasShadow : YES ];
            [ window setContentView : scrollview ];
            [ window setAcceptsMouseMovedEvents : YES ];
            [ window setMinSize: NSMakeSize( 200, 300 ) ];
                
            [ window makeKeyAndOrderFront : self ];
            [ window makeFirstResponder : textview ];
            [ window makeMainWindow ];
            
            [NSApp activateIgnoringOtherApps:YES];

            [ [ [ textview textStorage ] mutableString ] setString:[logs componentsJoinedByString: @"\n" ] ];
            [textview setTextColor:[NSColor greenColor]];
            [textview setBackgroundColor:[NSColor blackColor]];
            [textview setFont:[NSFont fontWithName:@"Courier New" size:13]];
        }
        else
        {
            [ window setContentView : nil ];
            [ scrollview setDocumentView : nil ];
            [ window close ];
        }
    }

    - ( void ) terminate
    {
        [ NSApp terminate : nil ];
    }

    - ( void ) support
    {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString: @"https://paypal.me/milgra"]];
    }

    - ( void ) update
    {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString: @"http://milgra.com/macos-activity-indicator.html"]];
    }

    @end


    @implementation MyWindow

    - ( BOOL ) canBecomeKeyWindow {	return YES; }
    - ( BOOL ) canBecomeMainWindow { return YES; }

    @end

    @implementation MyTextView

    - ( void ) mouseDown:(NSEvent *)event
    {
        if ( [self selectedRange].length == 0 )
        {
            [self selectAll:self];
            [[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
            [[NSPasteboard generalPasteboard] setString:[[self textStorage] mutableString] forType:NSStringPboardType];
        }
        else [self setSelectedRange: NSMakeRange(0, 0)];
    }

    @end
