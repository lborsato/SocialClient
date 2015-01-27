//
//  SocialClient.h
//
//  Created by Larry Borsato on 2015-01-26.
//  Copyright (c) 2015 alchemii. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import "SocialClientDelegate.h"

#define	FacebookReadPermissions		@[@"public_profile", @"email"]
#define	FacebookWritePermissions	@[@"publish_actions"]

extern	NSInteger const SCLoginSuccessful;
extern	NSInteger const	SCLoginCancelled;
extern	NSInteger const	SCLoginFailed;
extern  NSInteger const	SCLoginFailedNoAccounts;
extern	NSInteger const	SCLoginFailedUnauthorized;
extern	NSInteger const	SCLoginFailedMissingParams;
extern	NSInteger const	SCUpdateSuccessful;
extern	NSInteger const	SCUpdateFailed;
extern	NSInteger const SCFacebookParamsMissing;
extern	NSInteger const SCTwitterParamsMissing;
extern	NSInteger const SCTumblrParamsMissing;

@interface SocialClient : NSObject

@property (strong, nonatomic)	id				<SocialClientDelegate>delegate;

- (BOOL) loggedIn;
- (void) loginCompleteWithStatus:(NSInteger)status data:(NSData *)data error:(NSError *)error;
- (void) loginWithParams:(NSDictionary *)params;
- (BOOL) updateStatus:(NSString *)status;
- (void) updateStatusCompleteWithStatus:(NSInteger)status data:(NSData *)data error:(NSError *)error;



@end
