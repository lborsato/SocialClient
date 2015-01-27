//
//  SocialClientDelegate.h
//
//  Created by Larry Borsato on 2015-01-26.
//  Copyright (c) 2015 alchemii. All rights reserved.
//

#ifndef SocialClientDelegate_h
#define SocialClientDelegate_h

#import <Foundation/Foundation.h>

@protocol SocialClientDelegate <NSObject>

@required

@optional
- (void) client:(id)client didLoginWithStatus:(NSInteger)status  data:(NSData *)data error:(NSError *)error;
- (void) client:(id)client didUpdateWithStatus:(NSInteger)status data:(NSData *)data error:(NSError *)error;

@end


#endif
