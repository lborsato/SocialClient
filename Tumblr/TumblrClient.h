//
//  TumblrClient.h
//
//  Created by Larry Borsato on 2015-01-27.
//  Copyright (c) 2015 alchemii. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SocialClient.h"
#import "OAuthConsumer.h"

@interface TumblrClient : SocialClient <UIWebViewDelegate>

@property						UIView			*parentView;
@property (strong, nonatomic)	OAConsumer		*consumer;
@property (strong, nonatomic)	OAToken			*token;

@property (strong, nonatomic)	NSString		*consumerKey;
@property (strong, nonatomic)	NSString		*consumerSecret;
@property (strong, nonatomic)	NSString		*accessToken;
@property (strong, nonatomic)	NSString		*accessTokenSecret;
@property (strong, nonatomic)	NSString		*callback;
@property (strong, nonatomic)	NSMutableArray	*blognames;
@property (strong, nonatomic)	NSString		*blogname;


- (BOOL)	canUpdateStatus;
+ (id) 		tumblrClient;
- (void) 	getUserInfo;


@end
