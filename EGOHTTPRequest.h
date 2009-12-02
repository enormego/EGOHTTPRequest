//
//  EGOHTTPRequest.h
//  EGOHTTPRequest
//
//  Created by Shaun Harrison on 12/2/09.
//  Copyright 2009 enormego. All rights reserved.
//
//  This work is licensed under the Creative Commons GNU General Public License License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/GPL/2.0/
//  or send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
//

#import <Foundation/Foundation.h>

@interface EGOHTTPRequest : NSObject {
@private
	NSURL* _URL;
	NSError* _error;
	NSURLResponse* _response;
	NSMutableData* _responseData;
	NSURLConnection* _connection;
	NSMutableDictionary* _requestHeaders;
	
	NSTimeInterval _timeoutInterval;
	
	SEL _didFinishSelector;
	SEL _didFailSelector;
	
	id _delegate;
	
	BOOL isStarted;
	BOOL isCancelled;
}

+ (NSMutableArray*)currentRequests;
+ (void)cancelRequestsForDelegate:(id)delegate;

- (id)initWithURL:(NSURL*)aURL;
- (id)initWithURL:(NSURL*)aURL delegate:(id)delegate;

- (void)addRequestHeader:(NSString *)header value:(NSString *)value;

- (void)startAsynchronous;
- (void)cancel;

@property(nonatomic,readonly) NSData* responseData;
@property(nonatomic,readonly) NSString* responseString;
@property(nonatomic,readonly) NSInteger responseStatusCode;
@property(nonatomic,readonly) NSDictionary* responseHeaders;

@property(nonatomic,readonly,getter=URL) NSURL* url;
@property(nonatomic,readonly) NSError* error;
@property(nonatomic,readonly,getter=isStarted) BOOL started;
@property(nonatomic,readonly,getter=isCancelled) BOOL cancelled;

@property(nonatomic,retain) NSURLResponse* response;
@property(nonatomic,assign) id delegate;
@property(nonatomic,assign) SEL didFinishSelector;
@property(nonatomic,assign) SEL didFailSelector;

@property(nonatomic,assign) NSTimeInterval timeoutInterval; // Default is 30 seconds

@end