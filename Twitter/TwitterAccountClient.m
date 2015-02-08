//
//  TwitterAccountClient.m
//
//  Created by Larry Borsato on 2015-01-26.
//  Copyright (c) 2015 alchemii. All rights reserved.
//

#import "TwitterAccountClient.h"

@implementation TwitterAccountClient

ACAccountStore	*accountStore;
NSArray			*accounts;
UIAlertView		*alertSelect;


+ (id)twitterClient
{
	return [[self alloc] init];
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
 *	Locate Twitter accounts in the account store
 *	If found, allow the user to choose from them
 *	If not, login via the REST API
 */
- (void) login
{
	accountStore = [[ACAccountStore alloc] init];
	
	ACAccountType *twitterAccountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
	
	[accountStore requestAccessToAccountsWithType:twitterAccountType
										  options:nil
									   completion:^(BOOL granted, NSError *error)
	 {
		 if (granted)
		 {
			 NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			 self.accountIdentifier = [defaults objectForKey:@"TwitterAccountIdentifier"];
			 if ( self.accountIdentifier )
			 {
				 self.account = [accountStore accountWithIdentifier:self.accountIdentifier];
				 self.accountLoggedIn = YES;
				 [self loginCompleteWithStatus:SCLoginSuccessful data:nil error:error];
			 }
			 else
			 {
				 accounts = [accountStore accountsWithAccountType:twitterAccountType];
				 if ( [accounts count] == 1 )
				 {
					 self.account = accounts[0];
					 [self saveAccountIdentifier:self.account.identifier];
					 
				 }
				 else if ( [accounts count] > 1 )
				 {
					 [self alertSelectAccount:accounts];
				 }
				 else
				 {
					 if ( self.loginParams )
						 [self loginWithOAuth];
					 else
						 [self loginCompleteWithStatus:SCLoginFailedNoAccounts data:nil error:error];
				 }
			 }
			 
		 }
		 else
		 {
			 if ( error.code == ACErrorAccountNotFound )
			 {
				 if ( self.loginParams )
					 [self loginWithOAuth];
				 else
					 [self loginCompleteWithStatus:SCLoginFailedNoAccounts data:nil error:error];
			 }
			 else
			 	[self loginCompleteWithStatus:SCLoginCancelled data:nil error:error];
		 }
	 }];
}



/**
 *	Select the desired Twitter account if the user has more than one
 *
 *	@param	NSArray*	accounts	the list of Twitter accounts
 */
- (void)alertSelectAccount:(NSArray *)accounts
{
	alertSelect = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Twitter Accounts", nil)
											 message:NSLocalizedString(@"Please select the correct Twitter account.", nil)
											delegate:self
								   cancelButtonTitle:nil
								   otherButtonTitles:nil];
	for ( ACAccount *account in accounts )
	{
		[alertSelect addButtonWithTitle:[account accountDescription]];
	}
	
	[alertSelect show];
}


/**
 *	Save the selected Twitter account
 */
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if ( alertView == alertSelect )
	{
		[alertView dismissWithClickedButtonIndex:buttonIndex animated:NO];
		self.account = accounts[buttonIndex];
		[self saveAccountIdentifier:self.account.identifier];
	}
}


/**
 *	Save the account indentifier to retrieve tha account later
 *
 *	@param	NSString*	identifier		the account identifier
 */
- (void) saveAccountIdentifier:(NSString *)identifier
{
	self.accountIdentifier = identifier;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:self.accountIdentifier forKey:@"TwitterAccountIdentifier"];
	[defaults synchronize];
	[self validate];
}


/**
 *	Validate the Twitter account
 *
 *	@param	ACAccount*	account		the account from the account store
 */
- (void)validate
{
	[self accountRequest:@"https://api.twitter.com/1.1/statuses/user_timeline.json"
				 account:self.account
				  method:SLRequestMethodGET
			  postParams:nil
				 handler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
					 if (error)
					 {
						 self.account = nil;
						 [self loginCompleteWithStatus:SCLoginFailedUnauthorized data:responseData error:nil];
					 }
					 else
					 {
						 self.accountLoggedIn = YES;
						 [self loginCompleteWithStatus:SCLoginSuccessful data:responseData error:nil];
					 }
				 }];
}


/**
 *	Is the user able to post a status update
 *
 *	@return	BOOL	YES if can post, NO if not
 */
- (BOOL)canUpdateStatus
{
	return [self loggedIn];
}

/**
 *	Post a status update via the account
 *
 *	@param	NSString*	status		status to post
 */
- (void)updateStatus:(NSString *)status
{
	[self accountRequest:@"https://api.twitter.com/1/statuses/update.json"
				 account:self.account
				  method:SLRequestMethodPOST
			  postParams:@{@"status": status }
				 handler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
					 if ( !error )
					 	[self updateStatusCompleteWithStatus:SCUpdateSuccessful data:responseData error:error];
					 else
					 	[self updateStatusCompleteWithStatus:SCUpdateFailed data:responseData error:error];
				 }];
}



#pragma mark - Helper method


- (void)accountRequest:(NSString *)urlString
			   account:(ACAccount *)account
				method:(SLRequestMethod)method
			postParams:(NSDictionary *)postParams
			   handler:(SLRequestHandler)handler
{
	// Create the parameters dictionary and the URL (!use HTTPS!)
	NSURL *URL = [NSURL URLWithString:urlString];
	
	// Create request
	SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
											requestMethod:method
													  URL:URL
											   parameters:postParams];
	
	// Since we are performing a method that requires authorization we can simply
	// add the ACAccount to the SLRequest
	[request setAccount:account];
	
	// Perform request
	[request performRequestWithHandler:handler];
}




@end
