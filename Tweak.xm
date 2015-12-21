#import "../PS.h"

NSString *const PREF_PATH = @"/var/mobile/Library/Preferences/com.PS.NoPhotoGestures.plist";
CFStringRef const PreferencesNotification = CFSTR("com.PS.NoPhotoGestures.prefs");

NSString *const maxKey = @"maximizeEnabled";
NSString *const minKey = @"minimizeEnabled";

BOOL maximizeEnabled;
BOOL minimizeEnabled;

%hook PUPhotosGridViewController

// maximize
- (void)_handlePhotoOrStackPinchGestureRecognizer:(id)arg1
{
	if (maximizeEnabled)
		return;
	%orig;
}

%end

%hook PUPhotoBrowserController

// minimize
- (void)_handlePhotoPinchGestureRecognizer:(id)arg1
{
	if (minimizeEnabled)
		return;
	%orig;
}

%end

%group iOS9Up

%hook PUInteractivePinchDismissalController

// minimize
- (void)_handlePinchGestureRecognizer:(id)arg1
{
	if (minimizeEnabled)
		return;
	%orig;
}

%end

%end

%group iOS8Up

%hook PUZoomableGridViewController

// maximize
- (void)_handleGridPinchGestureRecognizer:(id)arg1
{
	if (maximizeEnabled)
		return;
	%orig;
}

%end

%end

%group iOS7

%hook PUAbstractAlbumListViewController

- (void)_handlePhotoPinchGestureRecognizer:(id)arg1
{
	if (minimizeEnabled)
		return;
	%orig;
}

%end

%end

/*%hook PUAlbumListViewController (iOS 8)

- (void)_handlePhotoPinchGestureRecognizer:(id)arg1
{
	if (minimizeEnabled)
		return;
	%orig;
}

%end*/

static void reloadSettings(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	CFPreferencesAppSynchronize(CFSTR("com.PS.NoPhotoGesturess"));
	NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	maximizeEnabled = [prefs[maxKey] boolValue];
	minimizeEnabled = prefs[minKey] ? [prefs[minKey] boolValue] : YES;
}

%ctor
{
	BOOL isPhotoApp = [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.mobileslideshow"];
	if (isiOS8Up && !isPhotoApp)
		return;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &reloadSettings, PreferencesNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
	reloadSettings(NULL, NULL, NULL, NULL, NULL);
	if (isiOS8Up) {
		if (isiOS9Up) {
			%init(iOS9Up);
		}
		%init(iOS8Up);
	}
	else if (isiOS7) {
		if (!isPhotoApp)
			dlopen("/System/Library/PrivateFrameworks/PhotosUI.framework/PhotosUI", RTLD_LAZY);
		%init(iOS7);
	}
	%init();
  	[pool drain];
}