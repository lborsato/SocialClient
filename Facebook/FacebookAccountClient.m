//
//  FacebookAccountClient.m
//  Trendi.li
//
//  Created by Larry Borsato on 2015-01-27.
//  Copyright (c) 2015 MoGroups. All rights reserved.
//

#import "FacebookAccountClient.h"

@implementation FacebookAccountClient

ACAccountStore	*accountStore;
NSArray			*accounts;

+ (id)facebookClient
{
	return [[self alloc] init];
}


- (void) login
{
	accountStore = [[ACAccountStore alloc] init];
	
	ACAccountType *FBaccountType= [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
	
	NSDictionary *options = @{ACFacebookAppIdKey: 		self.facebookAppId,
							  ACFacebookPermissionsKey: FacebookWritePermissions,
							  ACFacebookAudienceKey:	ACFacebookAudienceFriends};
	
	
	[accountStore requestAccessToAccountsWithType:FBaccountType
											   options:options
											completion:^(BOOL granted, NSError *error) {
												dispatch_async(dispatch_get_main_queue(), ^{
													if (granted)
													{
														NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
														self.accountIdentifier = [defaults objectForKey:@"FacebookAccountIdentifier"];
														if ( self.accountIdentifier )
														{
															self.account = [accountStore accountWithIdentifier:self.accountIdentifier];
															[self loginCompleteWithStatus:SCLoginSuccessful data:nil error:error];
														}
														else
														{
															NSArray *accounts = [accountStore accountsWithAccountType:FBaccountType];
															if ( [accounts count] > 0 )
															{
																//it will always be the last object with single sign on
																self.account = [accounts lastObject];
																[self saveAccountIdentifier:self.account.identifier];
																
																//i Want to get the Facebook UID and log it here
																
																[self loginCompleteWithStatus:SCLoginSuccessful data:nil error:error];
															}
															else
															{
																[self loginWithOAuth];
															}
														}
													}
													else
													{
														//Fail gracefully...
														//NSLog(@"error getting permission %@",e);
														if ( error.code == ACErrorAccountNotFound )
															[self loginWithOAuth];
														else
															[self loginCompleteWithStatus:SCLoginCancelled data:nil error:error];
													}
												});
											}];
}


- (void) saveAccountIdentifier:(NSString *)identifier
{
	self.accountIdentifier = identifier;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:self.accountIdentifier forKey:@"FacebookAccountIdentifier"];
	[defaults synchronize];
}


/**
 *	Is the user able to post a status update
 *
 *	@return	BOOL	YES if can post, NO if not
 */
- (BOOL)canUpdateStatus
{
	if ( self.account )
		return YES;
	
	return NO;
}


/**
 *	Post a status update via the account
 *
 *	@param	NSString*	status		status to post
 */
- (void)updateStatus:(NSString *)status
{
	// Create the parameters dictionary and the URL (!use HTTPS!)
	NSDictionary *parameters = @{@"message": status, };
	NSURL *URL = [NSURL URLWithString:@"https://graph.facebook.com/me/feed"];
	
	// Create request
	SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook
											requestMethod:SLRequestMethodPOST
													  URL:URL
											   parameters:parameters];
	
	// Since we are performing a method that requires authorization we can simply
	// add the ACAccount to the SLRequest
	[request setAccount:self.account];
	
	// Perform request
	[request performRequestWithHandler:^(NSData *respData, NSHTTPURLResponse *urlResp, NSError *error)
	 {
		 // Check for errors in the responseDictionary
		 if ( !error )
			 [self updateStatusCompleteWithStatus:SCUpdateSuccessful data:respData error:error];
		 else
			 [self updateStatusCompleteWithStatus:SCUpdateFailed data:respData error:error];
	 }];
}


@end
