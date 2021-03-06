#import "Tweak.h"
#import <MediaRemote/MediaRemote.h>
#import <notify.h>

static MSHFConfig *config = NULL;

%group MitsuhaVisualsNotification

%hook SBMediaController

-(void)setNowPlayingInfo:(id)arg1 {
    %orig;
    MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef information) {
        NSDictionary *dict = (__bridge NSDictionary *)information;

        if (dict && dict[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtworkData]) {
            [config colorizeView:[UIImage imageWithData:[dict objectForKey:(__bridge NSString*)kMRMediaRemoteNowPlayingInfoArtworkData]]];
        }
    });
}

%end

%end

%group ios13

%hook CSFixedFooterViewController

%property (strong,nonatomic) MSHFView *mshfview;

-(void)loadView{
    %orig;
    config.waveOffsetOffset = self.view.bounds.size.height - 200;

    if (![config view]) [config initializeViewWithFrame:self.view.bounds];
    self.mshfview = [config view];
    
    [self.view addSubview:self.mshfview];
    [self.view bringSubviewToFront:self.mshfview];
}

-(void)viewWillAppear:(BOOL)animated{
    %orig;
    if([config view] && [[%c(SBMediaController) sharedInstance] isPlaying]) {
        [self.mshfview start];
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    %orig;
    if([config view]) {
        [self.mshfview stop];
    }
}

%end

%end

%group old

%hook SBDashBoardFixedFooterViewController

%property (strong,nonatomic) MSHFView *mshfview;

-(void)loadView{
    %orig;
    config.waveOffsetOffset = self.view.bounds.size.height - 200;

    if (![config view]) [config initializeViewWithFrame:self.view.bounds];
    self.mshfview = [config view];
    
    [self.view addSubview:self.mshfview];
    [self.view bringSubviewToFront:self.mshfview];
}

-(void)viewWillAppear:(BOOL)animated{
    %orig;
    if([config view] && [[%c(SBMediaController) sharedInstance] isPlaying]) {
        [self.mshfview start];
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    %orig;
    if([config view]) {
        [self.mshfview stop];
    }
}

%end

%end

static void screenDisplayStatus(CFNotificationCenterRef center, void* o, CFStringRef name, const void* object, CFDictionaryRef userInfo) {
    if ([[%c(SBMediaController) sharedInstance] isPlaying]) {
        uint64_t state;
        int token;
        notify_register_check("com.apple.iokit.hid.displayStatus", &token);
        notify_get_state(token, &state);
        notify_cancel(token);
        if ([config view]) {
            if (state) {
                    [[config view] start];
            } else {
                [[config view] stop];
            }
        }
    } else {
        [[config view] stop];
    }
}

%ctor {
    config = [MSHFConfig loadConfigForApplication:@"LockScreen"];

    if(config.enabled){
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)screenDisplayStatus, (CFStringRef)@"com.apple.iokit.hid.displayStatus", NULL, (CFNotificationSuspensionBehavior)kNilOptions);
        if(@available(iOS 13.0, *)) {
		    %init(ios13)
	    } else {
            %init(old)
        }

        %init(MitsuhaVisualsNotification);
    }
}