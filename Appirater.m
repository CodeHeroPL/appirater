/*
 This file is part of Appirater.
 
 Copyright (c) 2010, Arash Payan
 All rights reserved.
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 */
/*
 * Appirater.m
 * appirater
 *
 * Created by Arash Payan on 9/5/09.
 * http://arashpayan.com
 * Copyright 2010 Arash Payan. All rights reserved.
 */

#import "Appirater.h"
#import <SystemConfiguration/SCNetworkReachability.h>
#include <netinet/in.h>

NSString *const kAppiraterLaunchDate				= @"kAppiraterLaunchDate";
NSString *const kAppiraterLaunchCount				= @"kAppiraterLaunchCount";
NSString *const kAppiraterLaunchReminderCount		= @"kAppiraterLaunchReminderCount";
NSString *const kAppiraterCurrentVersion			= @"kAppiraterCurrentVersion";
NSString *const kAppiraterRatedCurrentVersion		= @"kAppiraterRatedCurrentVersion";
NSString *const kAppiraterDeclinedToRate			= @"kAppiraterDeclinedToRate";
NSString *const kAppiraterReminderToRate			= @"kAppiraterReminderToRate";
NSString *const kAppiraterAppID						= @"kAppiraterAppID";
NSString *const kAppiraterTitleKey					= @"kAppiraterTitleKey";
NSString *const kAppiraterMessageKey				= @"kAppiraterMessageKey";
NSString *const kAppiraterYesTextKey				= @"kAppiraterYesTextKey";
NSString *const kAppiraterNoTextKey					= @"kAppiraterNoTextKey";
NSString *const kAppiraterReminderTextKey			= @"kAppiraterReminderTextKey";
NSString *const kCFBundleDisplayNameKey				= @"CFBundleDisplayName";
NSString *const kCFAppStoreDisplayNameKey			= @"CFAppStoreDisplayName";
NSString *const kCFBundleShortVersionStringKey      = @"CFBundleShortVersionString";

NSString *templateReviewURL = @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=APP_ID&onlyLatestVersion=true&pageNumber=0&sortOrdering=1";

@interface Appirater (hidden)
- (BOOL)connectedToNetwork;
- (NSString *)appName;
- (void)openAppStoreReviewPage;
- (void)addImageToAlertView:(UIAlertView *)alertView;
@end

@implementation Appirater (hidden)

- (BOOL)connectedToNetwork 
{
    // Create zero addy
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
	
    // Recover reachability flags
    SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
    SCNetworkReachabilityFlags flags;
	
    BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    CFRelease(defaultRouteReachability);
	
    if (!didRetrieveFlags)
    {
        NSLog(@"Error. Could not recover network reachability flags");
        return NO;
    }
	
    BOOL isReachable = flags & kSCNetworkFlagsReachable;
    BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;
	BOOL nonWiFi = flags & kSCNetworkReachabilityFlagsTransientConnection;
	
	NSURL *testURL = [NSURL URLWithString:@"http://www.apple.com/"];
	NSURLRequest *testRequest = [NSURLRequest requestWithURL:testURL  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20.0];
	NSURLConnection *testConnection = [NSURLConnection connectionWithRequest:testRequest delegate:self];
	
    return ((isReachable && !needsConnection) || nonWiFi) ? (testConnection ? YES : NO) : NO;
}

- (NSString *)appName
{
	NSString *candidate = nil;
	
//	candidate = [[[NSBundle mainBundle] infoDictionary] objectForKey:kCFAppStoreDisplayNameKey];
//	if (!candidate)
		candidate = [[[NSBundle mainBundle] infoDictionary] objectForKey:kCFBundleDisplayNameKey];

	return candidate ? candidate : [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
}

- (void)openAppStoreReviewPage
{
	NSInteger appID = [[NSUserDefaults standardUserDefaults] integerForKey:kAppiraterAppID];
	NSString *reviewURL = [templateReviewURL stringByReplacingOccurrencesOfString:@"APP_ID" withString:[NSString stringWithFormat:@"%d", appID]];
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:reviewURL]];
	
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:kAppiraterRatedCurrentVersion];
	[[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)addImageToAlertView:(UIAlertView *)alertView {
	NSArray *subViews = [alertView subviews];
	for (UIView *aView in subViews)
	{
		if ([aView isKindOfClass:[UILabel class]])
		{
			UILabel *aLabel = (UILabel *)aView;
			if ([aLabel.text isEqualToString:APPIRATER_MESSAGE])
			{
				/* Place the image centered at the very bottom of the message label.
				   This assumes that the message has at least 2 extra \n's at
				   the end of it to provide room for the image, otherwise the image
				   will obscure the text.
				*/
				UIImage *alertImage = [UIImage imageNamed:APPIRATER_IMAGE];
#ifdef DEBUG 
				NSAssert(alertImage, @"Unable to find APPIRATER_IMAGE to use in alertview. Did you set APPIRATER_IMAGE correctly?");
#endif
				UIImageView *alertImageView = [[UIImageView alloc] initWithImage:alertImage];
				CGRect imageFrame = alertImageView.frame;
				imageFrame.origin.y = aLabel.frame.origin.y + aLabel.frame.size.height - (imageFrame.size.height / 2);
				imageFrame.origin.x = aLabel.center.x - (imageFrame.size.width / 2);
				alertImageView.frame = imageFrame;
				[alertView addSubview:alertImageView];
				[alertImageView release];
			}
		}
	}
	
}

@end


@implementation Appirater


+ (Appirater *) shared {
	static Appirater *sSingleton;
	
	if (!sSingleton)
		sSingleton = [Appirater new];
	
	return sSingleton;
}

+ (void)openAppStoreReviewPage
{
	[[Appirater shared] openAppStoreReviewPage];
}

+ (void)appLaunchedWithID:(NSInteger)appID {
	[[NSUserDefaults standardUserDefaults] setInteger:appID forKey:kAppiraterAppID];
	
	[NSThread detachNewThreadSelector:@selector(_appLaunchedOrEnteredForeground) toTarget:[Appirater shared] withObject:nil];
}


+ (void)applicationWillEnterForeground {
	[NSThread detachNewThreadSelector:@selector(_appLaunchedOrEnteredForeground) toTarget:[Appirater shared] withObject:nil];
}


- (void)_appLaunchedOrEnteredForeground 
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// get the app's version
	NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleShortVersionStringKey];
	
	// get the version number that we've been tracking
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *trackingVersion = [userDefaults stringForKey:kAppiraterCurrentVersion];
	if (trackingVersion == nil)
	{
		trackingVersion = version;
		[userDefaults setObject:version forKey:kAppiraterCurrentVersion];
	}
	
	if (APPIRATER_DEBUG)
		NSLog(@"APPIRATER Tracking version: %@", trackingVersion);
	
	if ([trackingVersion isEqualToString:version])
	{
		// get the launch date
		NSTimeInterval timeInterval = [userDefaults doubleForKey:kAppiraterLaunchDate];
		if (timeInterval == 0)
		{
			timeInterval = [[NSDate date] timeIntervalSince1970];
			[userDefaults setDouble:timeInterval forKey:kAppiraterLaunchDate];
		}
		
		// get the launch count
		int launchCount = [userDefaults integerForKey:kAppiraterLaunchCount];
		launchCount++;
		[userDefaults setInteger:launchCount forKey:kAppiraterLaunchCount];
		if (APPIRATER_DEBUG)
			NSLog(@"APPIRATER Launch count: %d", launchCount);
		
		// have they previously asked to be reminded to rate?
		BOOL reminderToRate = [userDefaults boolForKey:kAppiraterReminderToRate];
		int launchReminderCount = 0;
		if (reminderToRate) 
		{
			launchReminderCount = [userDefaults integerForKey:kAppiraterLaunchReminderCount];
			launchReminderCount++;
			[userDefaults setInteger:launchReminderCount forKey:kAppiraterLaunchReminderCount];
		}
	}
	else
	{
		// it's a new version of the app, so restart tracking
		[userDefaults setObject:version forKey:kAppiraterCurrentVersion];
		[userDefaults setDouble:[[NSDate date] timeIntervalSince1970] forKey:kAppiraterLaunchDate];
		[userDefaults setInteger:1 forKey:kAppiraterLaunchCount];
		[userDefaults setInteger:0 forKey:kAppiraterLaunchReminderCount];
		[userDefaults setBool:NO forKey:kAppiraterRatedCurrentVersion];
		[userDefaults setBool:NO forKey:kAppiraterDeclinedToRate];
		[userDefaults setBool:NO forKey:kAppiraterReminderToRate];
	}

	
	[userDefaults synchronize];
	
	[pool drain];
}

- (void)showPromptIfNeeded {
    if (APPIRATER_DEBUG)
        [self performSelectorOnMainThread:@selector(showPrompt) withObject:nil waitUntilDone:NO];
    else 
    {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        BOOL ratedApp = [userDefaults boolForKey:kAppiraterRatedCurrentVersion];
        BOOL declinedToRate = [userDefaults boolForKey:kAppiraterDeclinedToRate];

        if (!declinedToRate && !ratedApp) { 
            NSTimeInterval timeInterval = [userDefaults doubleForKey:kAppiraterLaunchDate];
            NSTimeInterval secondsSinceLaunch = [[NSDate date] timeIntervalSinceDate:[NSDate dateWithTimeIntervalSince1970:timeInterval]];
            CGFloat secondsUntilPrompt = 60 * 60 * 24 * DAYS_UNTIL_PROMPT;
            NSInteger launchCount = [userDefaults integerForKey:kAppiraterLaunchCount];

            if (secondsSinceLaunch > secondsUntilPrompt && launchCount > LAUNCHES_UNTIL_PROMPT) {
                BOOL reminderToRate = [userDefaults boolForKey:kAppiraterReminderToRate];
                NSInteger launchReminderCount = 0;
                if (reminderToRate) 
                {
                    launchReminderCount = [userDefaults integerForKey:kAppiraterLaunchReminderCount];
                }

                if (!reminderToRate || launchReminderCount > LAUNCHES_UNTIL_REMINDER) {
                    if ([self connectedToNetwork])	{
                        [self performSelectorOnMainThread:@selector(showPrompt) withObject:nil waitUntilDone:NO];
                    }
                }
            }
        }
    }
}

- (void)showPrompt 
{
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:APPIRATER_MESSAGE_TITLE
														message:APPIRATER_MESSAGE
													   delegate:self
											  cancelButtonTitle:APPIRATER_CANCEL_BUTTON
											  otherButtonTitles:APPIRATER_RATE_BUTTON, APPIRATER_RATE_LATER, nil];
	
	
	[alertView show];
	if (APPIRATER_USE_IMAGE)
	{
		[self addImageToAlertView:alertView];
	}
	[alertView autorelease];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	switch (buttonIndex) {
		case kNoThanksButtonIndex :
		{
			// they don't want to rate it
			[userDefaults setBool:YES forKey:kAppiraterDeclinedToRate];
			[userDefaults setBool:NO forKey:kAppiraterReminderToRate];
			break;
		}
		case kYesButtonIndex :
		{
			// they want to rate it
			[self openAppStoreReviewPage];
			break;
		}
		case kReminderButtonIndex :
			// remind them later
			[userDefaults setBool:YES forKey:kAppiraterReminderToRate];
			[userDefaults setInteger:0 forKey:kAppiraterLaunchReminderCount];
			break;
		default:
			break;
	}
	
	[userDefaults synchronize];
}

@end
