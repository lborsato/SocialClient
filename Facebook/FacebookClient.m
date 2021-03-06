//
//  FacebookClient.m
//
//  Created by Larry Borsato on 2015-01-27.
//  Copyright (c) 2015 alchemii. All rights reserved.
//

#import "FacebookClient.h"
#import "FacebookAccountClient.h"
#import "FacebookOAuthClient.h"

@implementation FacebookClient

/**
 *	Factory method for TwitterClient base class
 *
 *	@return	id		the base class
 */
+ (id)facebookClient
{
	FacebookClient *client = [[self alloc] init];
	NSUserDefaults *defaults	= [NSUserDefaults standardUserDefaults];
	NSString *consumerKey       = [defaults objectForKey:@"FacebookConsumerKey"];
	NSString *consumerSecret    = [defaults objectForKey:@"FacebookConsumerSecret"];
	if ( consumerKey && consumerSecret )
	{
		client = [FacebookOAuthClient facebookClient];
		client.consumerKey 			= consumerKey;
		client.consumerSecret 		= consumerSecret;
	}
	else
	{
		client = [FacebookAccountClient facebookClient];
	}
	return client;
}


- (id)init
{
	self = [super init];
	if (self)
	{
	}
	return self;
}



/**
 *	Log in to Twitter
 *
 *	@param	NSDictionary*	key			Twitter OAuth params
 */
- (void) loginWithParams:(NSDictionary *)params
{
	self.loginParams = params;
	self.client = [FacebookAccountClient facebookClient];
	self.client.delegate    = self.delegate;
	self.client.loginParams = self.loginParams;
	self.client.facebookAppId = params[@"FacebookAppId"];
	[self.client login];
}


- (void) loginWithOAuth
{
	self.client = [FacebookOAuthClient facebookClient];
	self.client.delegate    = self.delegate;
	self.client.loginParams = self.loginParams;
	[self.client login];
}



/**
 *	Is the user logged in
 *
 *	@return	BOOL	YES if logged in, NO if not
 */
- (BOOL) loggedIn
{
	return YES; //self.accountLoggedIn;
}

/**
 *	Is the user able to post a status update
 *
 *	@return	BOOL	YES if can post, NO if not
 */
- (BOOL)canUpdateStatus
{
	return YES;
}



- (void) updateStatus:(NSString *)status
{
	[self.client updateStatus:status];
}


@end
