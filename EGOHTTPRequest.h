//
//  EGOHTTPRequest.h
//  EGOHTTPRequest
//
//  Created by Shaun Harrison on 12/2/09.
//  Copyright (c) 2009-2010 enormego
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
	BOOL isFinished;
	BOOL isCancelled;
	
	NSThread* _backgroundThread;
	
	NSString* _requestMethod;
	NSData* _requestBody;
}

+ (NSMutableArray*)currentRequests;
+ (void)cancelRequestsForDelegate:(id)delegate;

- (id)initWithURL:(NSURL*)aURL;
- (id)initWithURL:(NSURL*)aURL delegate:(id)delegate;

- (void)addRequestHeader:(NSString *)header value:(NSString *)value;

- (void)startAsynchronous;
- (void)startSynchronous;
- (void)cancel;

@property(nonatomic,retain) NSString* requestMethod; // Default: GET
@property(nonatomic,retain) NSData* requestBody;

@property(nonatomic,readonly) NSData* responseData;
@property(nonatomic,readonly) NSString* responseString;
@property(nonatomic,readonly) NSInteger responseStatusCode;
@property(nonatomic,readonly) NSDictionary* responseHeaders;

@property(nonatomic,readonly,getter=URL) NSURL* url;
@property(nonatomic,readonly) NSError* error;
@property(nonatomic,readonly,getter=isStarted) BOOL started;
@property(nonatomic,readonly,getter=isFinished) BOOL finished;
@property(nonatomic,readonly,getter=isCancelled) BOOL cancelled;

@property(nonatomic,retain) NSURLResponse* response;
@property(assign) id delegate;
@property(assign) SEL didFinishSelector;
@property(assign) SEL didFailSelector;

@property(nonatomic,assign) NSTimeInterval timeoutInterval; // Default is 30 seconds

@end