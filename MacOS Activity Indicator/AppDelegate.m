
    #import "AppDelegate.h"


    @interface AppDelegate ()
    {
        char flag;
        NSWindow *window;
        NSTextView *textview;
        NSScrollView *scrollview;
        NSMutableArray* logs;
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

        self.statusItem = [ [ NSStatusBar systemStatusBar ] statusItemWithLength : NSVariableStatusItemLength ];
        [_statusItem setHighlightMode : NO ];
        [_statusItem setToolTip : @"MacOS File Activity Indicator" ];
        [_statusItem setAction : @selector(itemClicked:) ];

        if ( [ [ NSScreen mainScreen ] backingScaleFactor ] == 1.0 ) [_statusItem setImage : [NSImage imageNamed:@"switchIcon.png"] ];
        else _statusItem.image = [NSImage imageNamed:@"switchIcon2x.png"];
        [_statusItem.image setTemplate:NO];
        
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
                                           (NSTimeInterval)3.0,
                                           (uint) creationFlags);

        FSEventStreamScheduleWithRunLoop(_eventStream,
                                         [[NSRunLoop currentRunLoop] getCFRunLoop],
                                         kCFRunLoopDefaultMode);
        
        if ( !FSEventStreamStart( _eventStream ) )
        {
            [NSException raise:@"CDEventsEventStreamCreationFailureException"
                        format:@"Failed to create event stream."];
        }
        
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
        
        flag = 1 - flag;
        if ( flag == 1 )
        {
            if ( [ [ NSScreen mainScreen ] backingScaleFactor ] == 1.0 ) [_statusItem setImage : [NSImage imageNamed:@"switchIconinv.png"] ];
            else _statusItem.image = [NSImage imageNamed:@"switchIconinv2x.png"];
        }
        else
        {
            if ( [ [ NSScreen mainScreen ] backingScaleFactor ] == 1.0 ) [_statusItem setImage : [NSImage imageNamed:@"switchIcon.png"] ];
            else _statusItem.image = [NSImage imageNamed:@"switchIcon2x.png"];
        }
    }

    - ( void ) windowWillClose:(NSNotification *)notification
    {
        [textview release];
        [scrollview release];
        
        window = nil;
        textview = nil;
        scrollview = nil;
    }

    - (BOOL)windowShouldClose:(id)sender
    {
        [NSApp terminate:self];
        return NO;
    }

    - (void)itemClicked:(id)sender
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

            textview = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, contentSize.width, contentSize.height)];
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

            [ window setLevel : NSNormalWindowLevel ];
            [ window setDelegate : self ];
            [ window setHasShadow : YES ];
            [ window setContentView : scrollview ];
            [ window setAcceptsMouseMovedEvents : YES ];
            [ window setMinSize: NSMakeSize( 200, 300 ) ];
                
            [ window makeKeyAndOrderFront : self ];
            [ window makeFirstResponder : scrollview ];
            [ window makeMainWindow ];

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

    @end


    @implementation MyWindow

    - ( BOOL ) canBecomeKeyWindow {	return YES; }
    - ( BOOL ) canBecomeMainWindow { return YES; }

    @end
