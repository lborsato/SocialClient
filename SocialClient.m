//
//  SocialClient.m
//
//  Created by Larry Borsato on 2015-01-26.
//  Copyright (c) 2015 alchemii. All rights reserved.
//

#import "SocialClient.h"

@implementation SocialClient

//	Status return values
NSInteger const SCLoginSuccessful 			= 	0;
NSInteger const	SCLoginCancelled  			=	1;
NSInteger const	SCLoginFailed  				=	2;
NSInteger const	SCLoginFailedNoAccounts		=	3;
NSInteger const	SCLoginFailedUnauthorized	=	4;
NSInteger const	SCLoginFailedMissingParams	=	5;
NSInteger const	SCUpdateSuccessful			=	6;
NSInteger const	SCUpdateFailed				= 	7;
NSInteger const	SCFacebookParamsMissing		=	8;
NSInteger const SCTwitterParamsMissing		= 	9;
NSInteger const SCTumblrParamsMissing		= 	10;

//NSArray *const FacebookReadPermissions 	=	@[@"public_profile", @"email"];
//NSArray *const FacebookWritePermissions	=	@[@"publish_actions"];



- (void) loginWithParams:(NSDictionary *)params
{
	@throw [NSException exceptionWithName:NSInternalInconsistencyException
								   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)] userInfo:nil];
}


- (BOOL) loggedIn
{
	@throw [NSException exceptionWithName:NSInternalInconsistencyException
								   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)] userInfo:nil];
}


- (BOOL) updateStatus:(NSString *)status
{
	@throw [NSException exceptionWithName:NSInternalInconsistencyException
								   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)] userInfo:nil];
}


- (void) loginCompleteWithStatus:(NSInteger)status data:(NSData *)data error:(NSError *)error
{
	SEL selector = NSSelectorFromString(@"client:didLoginWithStatus:data:error:");
	if (self.delegate && [self.delegate respondsToSelector:selector] )
		[self.delegate client:self didLoginWithStatus:status data:data error:error];
}


- (void) updateStatusCompleteWithStatus:(NSInteger)status data:(NSData *)data error:(NSError *)error
{
	SEL selector = NSSelectorFromString(@"client:didUpdateWithStatus:data:error:");
	if (self.delegate && [self.delegate respondsToSelector:selector] )
		[self.delegate client:self didUpdateWithStatus:status data:data error:error];
}


@end
