//
//  TwitterClient.m
//
//  Created by Larry Borsato on 2015-01-26.
//  Copyright (c) 2015 alchemii. All rights reserved.
//

#import "TwitterClient.h"
#import "TwitterAccountClient.h"
#import "TwitterOAuthClient.h"

@implementation TwitterClient


/**
 *	Factory method for TwitterClient base class
 *
 *	@return	id		the base class
 */
+ (id)twitterClient
{
	TwitterClient *client = [[self alloc] init];
	NSUserDefaults *defaults	= [NSUserDefaults standardUserDefaults];
	NSString *accountIdentifier	= [defaults objectForKey:@"TwitterAccountIdentifier"];
	NSString *consumerKey       = [defaults objectForKey:@"TwitterConsumerKey"];
	NSString *consumerSecret    = [defaults objectForKey:@"TwitterConsumerSecret"];
	NSString *accessToken 		= [defaults objectForKey:@"TwitterAccessToken"];
	NSString *accessTokenSecret = [defaults objectForKey:@"TwitterAccessTokenSecret"];
	if ( accountIdentifier )
	{
		client = [TwitterAccountClient twitterClient];
		client.accountIdentifier 	= accountIdentifier;
	}
	else if ( consumerKey && consumerSecret && accessToken && accessTokenSecret )
	{
		client = [TwitterOAuthClient twitterClient];
		client.consumerKey 			= consumerKey;
		client.consumerSecret 		= consumerSecret;
		client.accessToken 			= accessToken;
		client.accessTokenSecret 	= accessTokenSecret;
		client.accountLoggedIn		= YES;
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
	self.twitterClient = [TwitterAccountClient twitterClient];
	self.twitterClient.delegate    = self.delegate;
	self.twitterClient.loginParams = self.loginParams;
	self.twitterClient.parentView  = self.parentView;
	[self.twitterClient login];
}


- (void) loginWithOAuth
{
	self.twitterClient = [TwitterOAuthClient twitterClient];
	self.twitterClient.delegate    = self.delegate;
	self.twitterClient.loginParams = self.loginParams;
	self.twitterClient.parentView  = self.parentView;
	[self.twitterClient login];
}



/**
 *	Is the user logged in
 *
 *	@return	BOOL	YES if logged in, NO if not
 */
- (BOOL) loggedIn
{
	return self.accountLoggedIn;
}

/**
 *	Is the user able to post a status update
 *
 *	@return	BOOL	YES if can post, NO if not
 */
- (BOOL)canUpdateStatus
{
	return [self.twitterClient canUpdateStatus];
}



- (void) updateStatus:(NSString *)status
{
	[self.twitterClient updateStatus:status];
}


@end
