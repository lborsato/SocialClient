//
//  TwitterClient.h
//
//  Created by Larry Borsato on 2015-01-26.
//  Copyright (c) 2015 alchemii. All rights reserved.
//

#import "SocialClient.h"

@interface TwitterClient : SocialClient <UIWebViewDelegate>

@property (strong, nonatomic)	TwitterClient	*client;
@property (strong, nonatomic)	TwitterClient	*twitterAccountClient;
@property (strong, nonatomic)	TwitterClient	*twitterOAuthClient;
@property (strong, nonatomic)	NSDictionary 	*loginParams;
@property (strong, nonatomic)	UIView		 	*parentView;
@property (strong, nonatomic)	ACAccount		*account;
@property (strong, nonatomic)	NSString		*accountIdentifier;
@property (strong, nonatomic)	NSString		*consumerKey;
@property (strong, nonatomic)	NSString		*consumerSecret;
@property (strong, nonatomic)	NSString		*accessToken;
@property (strong, nonatomic)	NSString		*accessTokenSecret;
@property (strong, nonatomic)	NSString		*callback;
@property						BOOL			accountLoggedIn;

- (BOOL)			canUpdateStatus;
- (BOOL) 			loggedIn;
- (void)			login;
- (void) 			loginWithOAuth;
+ (id)				twitterClient;
- (void)			updateStatus:(NSString *)status;


@end
