//
//  TumblrClient.m
//
//  Created by Larry Borsato on 2015-01-27.
//  Copyright (c) 2015 alchemii. All rights reserved.
//

#import "TumblrClient.h"

@implementation TumblrClient


UIWebView 	*webview;
OAToken		*requestToken;
OAToken		*accessToken;
UIAlertView	*alertSelect;



+ (id) tumblrClient
{
	return [[self alloc] init];
}


- (TumblrClient *)init
{
	self = [super init];
	if (self) {
		self.delegate = nil;
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		
		self.accessToken 		= [defaults objectForKey:@"TumblrAccessToken"];
		self.accessTokenSecret 	= [defaults objectForKey:@"TumblrAccessTokenSecret"];
	}
	return self;
}


#pragma mark - Login methods

- (void) loginWithParams:(NSDictionary *)params
{
	self.consumerKey 	= [params objectForKey:@"TumblrConsumerKey"];
	self.consumerSecret = [params objectForKey:@"TumblrConsumerSecret"];
	self.callback 	    = [params objectForKey:@"TumblrCallback"];
	if ( !self.consumerKey || !self.consumerSecret || !self.callback )
		[self loginCompleteWithStatus:SCLoginFailedMissingParams data:nil error:nil];
	
	self.consumer = [[OAConsumer alloc] initWithKey:self.consumerKey secret:self.consumerSecret];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	self.blogname			= [defaults objectForKey:@"TumblrBlogName"];
	self.accessToken 		= [defaults objectForKey:@"TumblrAccessToken"];
	self.accessTokenSecret 	= [defaults objectForKey:@"TumblrAccessTokenSecret"];
	self.token = [[OAToken alloc] initWithKey:self.accessToken secret:self.accessTokenSecret];
	[self loginWithSdk];
}


- (void)loginWithSdk
{
	//if ( self.oauthAccessToken!=nil && self.oauthAccessTokenSecret!=nil )
	//	return;
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[self requestToken];
	});
}


#pragma mark - OAuth authentication methods

- (void) requestToken
{
	NSURL* requestTokenUrl = [NSURL URLWithString:@"https://www.tumblr.com/oauth/request_token"];
	OAMutableURLRequest* requestTokenRequest = [[OAMutableURLRequest alloc] initWithURL:requestTokenUrl
																			   consumer:self.consumer
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
 
	NSURL* authorizeUrl = [NSURL URLWithString:@"https://www.tumblr.com/oauth/authorize"];
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


- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
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
			NSURL* accessTokenUrl = [NSURL URLWithString:@"https://www.tumblr.com/oauth/access_token"];
			OAMutableURLRequest* accessTokenRequest = [[OAMutableURLRequest alloc] initWithURL:accessTokenUrl
																					  consumer:self.consumer
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
		[self loginCompleteWithStatus:SCLoginCancelled data:nil error:nil];
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
	accessToken = [[OAToken alloc] initWithHTTPResponseBody:httpBody];
	self.accessToken 	   = accessToken.key;
	self.accessTokenSecret = accessToken.secret;
	self.token = [[OAToken alloc] initWithKey:self.accessToken secret:self.accessTokenSecret];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:self.consumerKey    	forKey:@"TumblrConsumerKey"];
	[defaults setObject:self.consumerSecret 	forKey:@"TumblrConsumerSecret"];
	[defaults setObject:self.callback       	forKey:@"TumblrCallback"];
	[defaults setObject:self.accessToken 		forKey:@"TumblrAccessToken"];
	[defaults setObject:self.accessTokenSecret	forKey:@"TumblrAccessTokenSecret"];
	[defaults synchronize];
	
	[self loginCompleteWithStatus:SCLoginSuccessful data:data error:nil];
}

- (void)didFailOAuth:(OAServiceTicket*)ticket error:(NSError*)error {
	// ERROR!
	TrendiliNSLog(@"");
	[self loginCompleteWithStatus:SCLoginCancelled data:nil error:error];
}


/**
 *	Get Tumblr user info
 *
 */
- (void) getUserInfo
{
	self.blognames = [[NSMutableArray alloc] init];
	NSURL* requestTokenUrl = [NSURL URLWithString:@"http://api.tumblr.com/v2/user/info"];
	OAMutableURLRequest* requestTokenRequest = [[OAMutableURLRequest alloc] initWithURL:requestTokenUrl
																			   consumer:self.consumer
																				  token:self.token
																				  realm:nil
																	  signatureProvider:nil];
	[requestTokenRequest setHTTPMethod:@"GET"];
	OADataFetcher* dataFetcher = [[OADataFetcher alloc] init];
	[dataFetcher performRequest:requestTokenRequest withHandler:^(OAServiceTicket *ticket, NSData *data, NSError *error) {
		if ( !error )
		{
			NSLog(@"didPost:=%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
			id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
			
			if ( [json isKindOfClass:[NSDictionary class]] ) {
				NSDictionary *response = [json objectForKey:@"response"];
				NSDictionary *user     = [response objectForKey:@"user"];
				NSArray		 *blogs    = [user objectForKey:@"blogs"];
				for ( NSDictionary *blog in blogs )
				{
					[self.blognames addObject:[blog objectForKey:@"name"]];
				}
				if ( [self.blognames count] == 1 )
					[self saveBlogName:self.blognames[0]];
				else if ( [self.blognames count] > 1 )
					[self alertSelectBlog];
			}
		}
		else
		{
			NSLog(@"error = %@", error.description);
		}
	}];
}


- (void)alertSelectBlog
{
	alertSelect = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Tumblr Blogs", nil)
											 message:NSLocalizedString(@"Please select Tumblr blog you wish to post to.", nil)
											delegate:self
								   cancelButtonTitle:nil
								   otherButtonTitles:nil];
	for ( NSString *blog in self.blognames )
	{
		[alertSelect addButtonWithTitle:blog];
	}
	
	[alertSelect show];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if ( alertView == alertSelect )
	{
		[alertView dismissWithClickedButtonIndex:buttonIndex animated:NO];
		[self saveBlogName:self.blognames[buttonIndex]];
	}
}


- (void) saveBlogName:(NSString *)blogname
{
	self.blogname = blogname;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:self.blogname forKey:@"TumblrBlogName"];
	[defaults synchronize];
	[self post:@"Test update"];
}



/**
 *	Get Tumblr user info
 *
 */
- (void) post:(NSString *)status
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	self.blogname = [defaults objectForKey:@"TumblrBlogName"];
	NSString *urlString = [NSString stringWithFormat:@"http://api.tumblr.com/v2/blog/%@.tumblr.com/post", self.blogname];
	NSURL* requestTokenUrl = [NSURL URLWithString:urlString];
	OAMutableURLRequest* requestTokenRequest = [[OAMutableURLRequest alloc] initWithURL:requestTokenUrl
																			   consumer:self.consumer
																				  token:self.token
																				  realm:nil
																	  signatureProvider:nil];
	[requestTokenRequest setHTTPMethod:@"POST"];
	OARequestParameter* typeParam = [[OARequestParameter alloc] initWithName:@"type" value:@"text"];
	OARequestParameter* bodyParam = [[OARequestParameter alloc] initWithName:@"body" value:status];
	[requestTokenRequest setParameters:@[typeParam, bodyParam]];
	
	OADataFetcher* dataFetcher = [[OADataFetcher alloc] init];
	[dataFetcher performRequest:requestTokenRequest withHandler:^(OAServiceTicket *ticket, NSData *data, NSError *error) {
		if ( !error )
		{
			NSLog(@"didPost:=%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
		}
		else
		{
			NSLog(@"error = %@", error.description);
		}
	}];
}


- (BOOL)canUpdateStatus
{
	return YES;
}


@end
