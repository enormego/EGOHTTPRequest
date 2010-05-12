//
//  EGOHTTPRequest.m
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

#import "EGOHTTPRequest.h"

static NSMutableArray* __currentRequests;
static NSLock* __requestsLock;

@interface EGOHTTPRequest ()
+ (void)cleanUpRequest:(EGOHTTPRequest*)request;
+ (NSLock*)_requestsLock;
- (NSURLRequest*)_buildURLRequest;
@end


@implementation EGOHTTPRequest
@synthesize url=_URL, response=_response, delegate=_delegate, timeoutInterval=_timeoutInterval, 
			didFinishSelector=_didFinishSelector, didFailSelector=_didFailSelector, error=_error,
			cancelled=isCancelled, started=isStarted, finished=isFinished, requestMethod=_requestMethod,
			requestBody=_requestBody;

- (id)initWithURL:(NSURL*)aURL {
	return [self initWithURL:aURL delegate:nil];
}

- (id)initWithURL:(NSURL*)aURL delegate:(id)delegate {
	if((self = [super init])) {
		_URL = [aURL retain];
		self.delegate = delegate;
		_responseData = [[NSMutableData alloc] init];
		_requestHeaders = [[NSMutableDictionary alloc] init];

		self.timeoutInterval = 60;
		self.didFinishSelector = @selector(requestDidFinish:);
		self.didFailSelector = @selector(requestDidFail:withError:);
	}
	
	return self;
}

+ (NSMutableArray*)currentRequests {
	@synchronized(self) {
		if(!__currentRequests) {
			__currentRequests = [[NSMutableArray alloc] init];	
		}
	}
	
	return __currentRequests;
}

+ (NSLock*)_requestsLock {
	@synchronized(self) {
		if(!__requestsLock) {
			__requestsLock = [[NSLock alloc] init];	
		}
	}
	
	return __requestsLock;
}

- (void)addRequestHeader:(NSString *)header value:(NSString *)value {
	[_requestHeaders setObject:value forKey:header];
}

- (NSURLRequest*)_buildURLRequest {
	if(isStarted || isCancelled) return nil;
	else isStarted = YES;
	
	NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:self.url
																cachePolicy:NSURLRequestReturnCacheDataElseLoad
															timeoutInterval:self.timeoutInterval];
	
	[request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
	
	if(_requestMethod) {
		[request setHTTPMethod:_requestMethod];
	} else {
		[request setHTTPMethod:@"GET"];
	}
	
	if(_requestBody) {
		[request setHTTPBody:_requestBody];
	}
	
	for(NSString* key in _requestHeaders) {
		[request setValue:[_requestHeaders objectForKey:key] forHTTPHeaderField:key];
	}
	
	[[[self class] _requestsLock] lock];
	[[[self class] currentRequests] addObject:self];
	[[[self class] _requestsLock] unlock];
	
	return [request autorelease];
}

- (void)startAsynchronous {
	NSURLRequest* request = [self _buildURLRequest];
	
	if(request) {
		[self performSelectorInBackground:@selector(startConnectionInBackgroundWithRequest:) withObject:request];
	}
}

- (void)startSynchronous {
	NSURLRequest* request = [self _buildURLRequest];
	if(!request) return;
	
	NSURLResponse* aResponse = nil;
	NSError* anError = nil;
	NSData* responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&aResponse error:&anError];
	
	[_responseData setData:responseData];
	self.response = aResponse;
	
	if(_error) [_error release];
	
	if(anError) {
		_error = [anError retain];
		
		if(!isCancelled) {
			if([self.delegate respondsToSelector:self.didFailSelector]) {
				[self.delegate performSelector:self.didFailSelector withObject:self withObject:_error];
			}
		}		
	} else {
		_error = nil;

		if(!isCancelled) {
			if([self.delegate respondsToSelector:self.didFinishSelector]) {
				[self.delegate performSelector:self.didFinishSelector withObject:self];
			}
		}
	}
	
	isFinished = YES;
	[[self class] cleanUpRequest:self];
}

- (void)startConnectionInBackgroundWithRequest:(NSURLRequest*)request {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	_backgroundThread = [[NSThread currentThread] retain];
	
	_connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
	
	while(!isCancelled && !isFinished) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
	}
	
	if(isCancelled) {
		[_connection cancel];
	}

	[_backgroundThread release];
	_backgroundThread = nil;
	
	[_connection release];
	_connection = nil;
	
	[pool release];
}

+ (void)cleanUpRequest:(EGOHTTPRequest*)request {
	[[[self class] _requestsLock] lock];
	request.delegate = nil;
	[[self currentRequests] removeObject:request];
	[[[self class] _requestsLock] unlock];
}

+ (void)cancelRequestsForDelegate:(id)delegate {
	[[self _requestsLock] lock];
	NSArray* requests = [[self currentRequests] copy];
	[[self _requestsLock] unlock];
	
	for(EGOHTTPRequest* request in requests) {
		if([request isKindOfClass:[EGOHTTPRequest class]]){
			if(request.delegate == delegate) {
				request.delegate = nil;
				[request cancel];
			}
		}
	}
	
	[requests release];
}

- (void)cancel {
	if(isCancelled) return;
	else isCancelled = YES;
	
	isFinished = YES;
	
	// No need to call cancel because flagging as cancelled will cancel the request in the thread.
	
	[[self class] cleanUpRequest:self];
}

- (NSData*)responseData {
	return _responseData;
}

- (NSString*)responseString {
	NSStringEncoding stringEncoding;
	
	if([self.response textEncodingName].length > 0) {
		stringEncoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)[self.response textEncodingName]));
	} else {
		stringEncoding = NSUTF8StringEncoding;	
	}
	
	return [[[NSString alloc] initWithData:self.responseData encoding:stringEncoding] autorelease];
}

- (NSDictionary*)responseHeaders {
	if([self.response isKindOfClass:[NSHTTPURLResponse class]]) {
		return [(NSHTTPURLResponse*)self.response allHeaderFields];
	} else {
		return nil;	
	}
}

- (NSInteger)responseStatusCode {
	if([self.response isKindOfClass:[NSHTTPURLResponse class]]) {
		return [(NSHTTPURLResponse*)self.response statusCode];
	} else {
		return -NSNotFound;	
	}
}

#pragma mark -
#pragma mark Asynchrous NSURLConnection Methods
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	if(connection != _connection) return;
	[_responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	if(connection != _connection) return;
	self.response = response;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	if(connection != _connection) return;

	if(!isCancelled) {
		if([self.delegate respondsToSelector:self.didFinishSelector]) {
			[self.delegate performSelector:self.didFinishSelector withObject:self];
		}
	}
	
	isFinished = YES;
	[[self class] cleanUpRequest:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	if(connection != _connection) return;
	
	[_error release];
	_error = [error retain];

	if(!isCancelled) {
		if([self.delegate respondsToSelector:self.didFailSelector]) {
			[self.delegate performSelector:self.didFailSelector withObject:self withObject:error];
		}
	}
	
	isFinished = YES;
	[[self class] cleanUpRequest:self];
}

#pragma mark -

- (void)dealloc {
	[[self class] cleanUpRequest:self];
	
	isFinished = YES;
	self.response = nil;
	self.delegate = nil;
	[_responseData release]; _responseData=nil;
	[_requestHeaders release], _requestHeaders = nil;
	[_connection release], _connection = nil;
	[_error release], _error = nil;
	[_URL release], _URL = nil;

	[super dealloc];
}

@end
