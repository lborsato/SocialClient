//
//  FacebookOAuthClient.m
//  Trendi.li
//
//  Created by Larry Borsato on 2015-01-27.
//  Copyright (c) 2015 MoGroups. All rights reserved.
//

#import "FacebookOAuthClient.h"

@implementation FacebookOAuthClient

- (void)loginWithSdk
{
	if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
		[self openSessionWithUI:NO];
	}
	// If the session state is any of the two "open" states when the button is clicked
	else if (FBSession.activeSession.state == FBSessionStateOpen ||
			 FBSession.activeSession.state == FBSessionStateOpenTokenExtended)
	{
		// Close the session and remove the access token from the cache
		// The session state handler (in the app delegate) will be called automatically
		//[FBSession.activeSession closeAndClearTokenInformation];
		// If the session state is not any of the two "open" states when the button is clicked
	}
	else
	{
		// Open a session showing the user the login UI
		// You must ALWAYS ask for public_profile permissions when opening a session
		[self openSessionWithUI:YES];
	}
}


/**
 *	Open the Facebook session showing the Login UI or not as necessary
 *
 *	@param	BOOL	allowUI		allow the UI if YES or not if NO
 */
- (void)openSessionWithUI:(BOOL)allowUI
{
	[FBSession openActiveSessionWithReadPermissions:FacebookReadPermissions
									   allowLoginUI:allowUI
								  completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
									  // Handler for session state changes
									  // This method will be called EACH time the session state changes,
									  // also for intermediate states and NOT just when the session open
									  [self sessionStateChanged:session state:state error:error];
								  }];
}


/**
 *	Handle Facebook session state change
 *
 *	@param	FBSession*		session		Facebook session
 *	@param	FBSessionState*	state		Facebook session state
 *	@param	NSError*		error		error return
 */
- (void) sessionStateChanged:(FBSession *)session state:(FBSessionState)state error:(NSError *)error
{
	if (!error && state == FBSessionStateOpen){
		[self loginCompleteWithStatus:SCLoginSuccessful data:nil error:error];
		[self askForWritePermissions:FacebookWritePermissions];
		return;
	}
}


/**
 *	Check for desired permissions
 *
 *	@param	NSArray*	permissions		desired permissions
 *
 *	@return	YES is permissions available, NO if not
 */
- (BOOL)hasPermissions:(NSArray *)permissions
{
	BOOL hasPermissions = YES;
	for ( NSString *permission in permissions )
	{
		if ( ![FBSession.activeSession.permissions containsObject:permission] )
			hasPermissions = NO;
	}
	return hasPermissions;
}


/**
 *	Ask for permission to post to Facebook stream
 *
 *	@param	NSArray*	permissions		the desired write permissions
 */
- (void)askForWritePermissions:(NSArray *)permissions
{
	if ( ![self hasPermissions:permissions] )
	{
		[[FBSession activeSession] requestNewPublishPermissions:permissions
												defaultAudience:FBSessionDefaultAudienceFriends
											  completionHandler:^(FBSession *session, NSError *error)
		 {
			 if ( error == nil )
				 [self loginCompleteWithStatus:SCLoginSuccessful data:nil error:error];
		 }];
	}
}



/**
 *	Determine if user is logged in to Facebook
 *
 *	@param	FBSessionState state	the current session state
 *
 *	@return	YES if logged in, NO if not
 */
- (BOOL)isSessionStateEffectivelyLoggedIn:(FBSessionState)state {
	BOOL effectivelyLoggedIn;
 
	switch (state) {
		case FBSessionStateOpen:
			effectivelyLoggedIn = YES;
			break;
		case FBSessionStateCreatedTokenLoaded:
			effectivelyLoggedIn = YES;
			break;
		case FBSessionStateOpenTokenExtended:
			effectivelyLoggedIn = YES;
			break;
		default:
			effectivelyLoggedIn = NO;
			break;
	}
 
	return effectivelyLoggedIn;
}


#pragma mark - Status update methods

/**
 *	Is the user able to post a status update
 *
 *	@return	BOOL	YES if can post, NO if not
 */
- (BOOL)canUpdateStatus
{
	if ( self.account )
		return YES;
	
	if ( ![self isSessionStateEffectivelyLoggedIn:FBSession.activeSession.state] )
		return NO;
	
	if ( ![self hasPermissions:FacebookWritePermissions] )
		return NO;
	
	return YES;
}


/**
 *	Post a status update using the SDK
 *
 *	@param	NSString*	status		status to post
 */
- (void)updateStatus:(NSString *)status
{
	/*[FBRequestConnection startForPostOpenGraphObjectWithType:<#(NSString *)#> title:<#(NSString *)#> image:<#(id)#> url:<#(id)#> description:<#(NSString *)#> objectProperties:<#(NSDictionary *)#> completionHandler:<#^(FBRequestConnection *connection, id result, NSError *error)handler#>]*/
	[FBRequestConnection startForPostStatusUpdate:status
								completionHandler:^(FBRequestConnection *connection, id result, NSError *error)
		{
			if (!error) {
				// Status update posted successfully to Facebook
				NSLog(@"result: %@", result);
				[self updateStatusCompleteWithStatus:SCUpdateSuccessful data:nil error:error];
			} else {
				// An error occurred, we need to handle the error
				// See: https://developers.facebook.com/docs/ios/errors
				NSLog(@"%@", error.description);
				[self updateStatusCompleteWithStatus:SCUpdateFailed data:nil error:error];
			}
		}];
}


- (void) postViaSdkToWallWithStatus:(NSString *)status
{
	// NOTE: pre-filling fields associated with Facebook posts,
	// unless the user manually generated the content earlier in the workflow of your app,
	// can be against the Platform policies: https://developers.facebook.com/policy
	
	// Put together the dialog parameters
	NSDictionary *params = @{@"name": 			status,
							 @"caption": 		@"",
							 @"description":	@"",
							 @"link": 			@"",
							 @"picture": 		@""};
	
	// Make the request
	[FBRequestConnection startWithGraphPath:@"/me/feed"
								 parameters:params
								 HTTPMethod:@"POST"
						  completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
							  if (!error) {
								  // Link posted successfully to Facebook
								  NSLog(@"result: %@", result);
								  [self updateStatusCompleteWithStatus:SCUpdateSuccessful data:nil error:error];
							  } else {
								  // An error occurred, we need to handle the error
								  // See: https://developers.facebook.com/docs/ios/errors
								  NSLog(@"%@", error.description);
								  [self updateStatusCompleteWithStatus:SCUpdateFailed data:nil error:error];
							  }
						  }];
	
}


@end
