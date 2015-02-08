//
//  TwitterOAuthClient.m
//
//  Created by Larry Borsato on 2015-01-26.
//  Copyright (c) 2015 alchemii. All rights reserved.
//

#import "TwitterOAuthClient.h"

@implementation TwitterOAuthClient

OAConsumer			*consumer;
OAToken				*requestToken;
OAToken				*token;
UIWebView 			*webview;


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
 *	Login using the Twitter API
 *
 *	@param	NSDictionary*	params		the Twitter consumer key, secret, and callback
 */
- (void)login
{
	if ( self.loginParams )
	{
		self.consumerKey 	= [self.loginParams objectForKey:@"TwitterConsumerKey"];
		self.consumerSecret = [self.loginParams objectForKey:@"TwitterConsumerSecret"];
		self.callback 	    = [self.loginParams objectForKey:@"TwitterCallback"];
		if ( !self.consumerKey || !self.consumerSecret || !self.callback )
			[self loginCompleteWithStatus:SCLoginFailedMissingParams data:nil error:nil];
		
		consumer = [[OAConsumer alloc] initWithKey:self.consumerKey secret:self.consumerSecret];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[self requestToken];
		});
	}
	else
		[self loginCompleteWithStatus:SCLoginFailedMissingParams data:nil error:nil];
}




#pragma mark - OAuth authentication methods

- (void) requestToken
{
	NSURL* requestTokenUrl = [NSURL URLWithString:@"https://api.twitter.com/oauth/request_token"];
	OAMutableURLRequest* requestTokenRequest = [[OAMutableURLRequest alloc] initWithURL:requestTokenUrl
																			   consumer:consumer
																				  token:nil
																				  realm:nil
																	  signatureProvider:nil];
	OARequestParameter* callbackParam = [[OARequestParameter alloc] initWithName:@"oauth_callback" value:self.callback];
	[requestTokenRequest setHTTPMethod:@"POST"];
	[requestTokenRequest setParameters:[NSArray arrayWithObject:callbackParam]];
	OADataFetcher* dataFetcher = [[OADataFetcher alloc] init];
	[dataFetcher fetchDataWithRequest:requestTokenRequest
							 delegate:self
					didFinishSelector:@selector(didReceiveRequestToken:data:)
					  didFailSelector:@selector(didFailOAuth:error:)];
}


- (void)didReceiveRequestToken:(OAServiceTicket*)ticket data:(NSData*)data {
	NSString* httpBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	requestToken = [[OAToken alloc] initWithHTTPResponseBody:httpBody];
 
	NSURL* authorizeUrl = [NSURL URLWithString:@"https://api.twitter.com/oauth/authorize"];
	OAMutableURLRequest* authorizeRequest = [[OAMutableURLRequest alloc] initWithURL:authorizeUrl
																			consumer:nil
																			   token:nil
																			   realm:nil
																   signatureProvider:nil];
	NSString* oauthToken = requestToken.key;
	OARequestParameter* oauthTokenParam = [[OARequestParameter alloc] initWithName:@"oauth_token" value:oauthToken];
	[authorizeRequest setParameters:[NSArray arrayWithObject:oauthTokenParam]];
	
	webview = [[UIWebView alloc] initWithFrame:self.parentView.frame];
	webview.delegate = self;
	[self.parentView addSubview:webview];
	[webview loadRequest:authorizeRequest];
}


- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
	NSString *temp = [NSString stringWithFormat:@"%@",request];
	NSRange textRange = [[temp lowercaseString] rangeOfString:[self.callback lowercaseString]];
	NSRange errorRange = [[temp lowercaseString] rangeOfString:@"/login/error"];
 
	if (textRange.location != NSNotFound){
		
		// Extract oauth_verifier from URL query
		NSString* verifier = nil;
		NSArray* urlParams = [[[request URL] query] componentsSeparatedByString:@"&"];
		for (NSString* param in urlParams) {
			NSArray* keyValue = [param componentsSeparatedByString:@"="];
			NSString* key = [keyValue objectAtIndex:0];
			if ([key isEqualToString:@"oauth_verifier"]) {
				verifier = [keyValue objectAtIndex:1];
				break;
			}
		}
		
		if (verifier) {
			NSURL* accessTokenUrl = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
			OAMutableURLRequest* accessTokenRequest = [[OAMutableURLRequest alloc] initWithURL:accessTokenUrl
																					  consumer:consumer
																						 token:requestToken
																						 realm:nil
																			 signatureProvider:nil];
			OARequestParameter* verifierParam = [[OARequestParameter alloc] initWithName:@"oauth_verifier" value:verifier];
			[accessTokenRequest setHTTPMethod:@"POST"];
			[accessTokenRequest setParameters:[NSArray arrayWithObject:verifierParam]];
			OADataFetcher* dataFetcher = [[OADataFetcher alloc] init];
			[dataFetcher fetchDataWithRequest:accessTokenRequest
									 delegate:self
							didFinishSelector:@selector(didReceiveAccessToken:data:)
							  didFailSelector:@selector(didFailOAuth:error:)];
		} else {
			// ERROR!
		}
		
		[webView removeFromSuperview];
		
		return NO;
	}
	else if ( errorRange.location != NSNotFound )
	{
		[webView removeFromSuperview];
		[self loginCompleteWithStatus:SCLoginFailedUnauthorized data:nil error:nil];
		return NO;
	}
 
	return YES;
}

- (void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error {
	// ERROR!
}


- (void)webViewDidFinishLoad:(UIWebView *)webView{
	// [indicator stopAnimating];
	TrendiliNSLog(@"");
}


- (void)didReceiveAccessToken:(OAServiceTicket*)ticket data:(NSData*)data {
	NSString* httpBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	token = [[OAToken alloc] initWithHTTPResponseBody:httpBody];
	self.accessToken  		= token.key;
	self.accessTokenSecret 	= token.secret;
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:self.consumerKey    	forKey:@"TwitterConsumerKey"];
	[defaults setObject:self.consumerSecret 	forKey:@"TwitterConsumerSecret"];
	[defaults setObject:self.callback       	forKey:@"TwitterCallback"];
	[defaults setObject:self.accessToken 		forKey:@"TwitterAccessToken"];
	[defaults setObject:self.accessTokenSecret  forKey:@"TwitterAccessTokenSecret"];
	[defaults synchronize];
	
	[self loginCompleteWithStatus:SCLoginSuccessful data:data error:nil];
}

- (void)didFailOAuth:(OAServiceTicket*)ticket error:(NSError*)error {
	// ERROR!
	TrendiliNSLog(@"");
	[self loginCompleteWithStatus:SCLoginCancelled data:nil error:error];
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


- (void) updateStatus:(NSString *)status
{
	[self oauthRequest:@"https://api.twitter.com/1.1/statuses/update.json"
				method:@"POST"
			postParams:@{@"status" : status}
			   handler:^(OAServiceTicket *ticket, NSData *data, NSError *error) {
				   if ( !error ) {
					   NSLog(@"didPost:=%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
					   [self updateStatusCompleteWithStatus:SCUpdateSuccessful data:data error:nil];
				   }
				   else
				   {
					   [self updateStatusCompleteWithStatus:SCUpdateFailed data:data error:error];
				   }
			   }];
}



#pragma mark - Helper method

- (void) oauthRequest:(NSString *)urlString
			   method:(NSString *)method
		   postParams:(NSDictionary *)postParams
			  handler:(OADataFetcherCompletedHandler)handler
{
	
	OAConsumer *consumer = [[OAConsumer alloc] initWithKey:self.consumerKey secret:self.consumerSecret];
	OAToken *token = [[OAToken alloc] initWithKey:self.accessToken secret:self.accessTokenSecret];
	NSURL* url = [NSURL URLWithString:urlString];
	OAMutableURLRequest* request = [[OAMutableURLRequest alloc] initWithURL:url
																   consumer:consumer
																	  token:token
																	  realm:nil
														  signatureProvider:nil];
	[request setHTTPMethod:@"POST"];
	NSMutableArray *params = [[NSMutableArray alloc] init];
	for ( NSString *key in [postParams allKeys] )
	{
		OARequestParameter* param = [[OARequestParameter alloc] initWithName:key value:postParams[key]];
		[params addObject:param];
	}
	if ( [params count] > 0 )
		[request setParameters:params];
	OADataFetcher* dataFetcher = [[OADataFetcher alloc] init];
	[dataFetcher performRequest:request
					withHandler:handler];
}




@end
