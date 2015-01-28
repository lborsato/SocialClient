//
//  FacebookClient.h
//
//  Created by Larry Borsato on 2015-01-27.
//  Copyright (c) 2015 alchemii. All rights reserved.
//

#import "SocialClient.h"
#import <FacebookSDK/FacebookSDK.h>

@interface FacebookClient : SocialClient

{
	NSTimer	*timer;
	BOOL	publishAsked;
}

@property (strong, nonatomic)	FacebookClient	*facebookClient;
@property (strong, nonatomic)	NSDictionary 	*loginParams;
@property (strong, nonatomic)	NSString		*appId;
@property (nonatomic) 			ACAccountStore 	*accountStore;
@property (strong, nonatomic)	ACAccount		*facebookAccount;
@property (strong, nonatomic)	NSString		*facebookAppId;
@property (strong, nonatomic)	ACAccount		*account;
@property (strong, nonatomic)	NSString		*accountIdentifier;
@property (strong, nonatomic)	NSString		*consumerKey;
@property (strong, nonatomic)	NSString		*consumerSecret;

- (BOOL)			canUpdateStatus;
- (BOOL) 			loggedIn;
- (void)			login;
- (void) 			loginWithOAuth;
+ (id)				facebookClient;
- (void)			updateStatus:(NSString *)status;

@end
