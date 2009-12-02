//
//  EGOHTTPRequest.m
//  EGOHTTPRequest
//
//  Created by Shaun Harrison on 12/2/09.
//  Copyright 2009 enormego. All rights reserved.
//
//  This work is licensed under the Creative Commons GNU General Public License License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/GPL/2.0/
//  or send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
//

#import "EGOHTTPRequest.h"

static NSMutableArray* __currentRequests;
static NSLock* __requestsLock;

@implementation EGOHTTPRequest
@synthesize url=_URL, response=_response, delegate=_delegate, timeoutInterval=_timeoutInterval, 
			didFinishSelector=_didFinishSelector, didFailSelector=_didFailSelector, error=_error,
			cancelled=isCancelled, started=isStarted;

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

- (void)startAsynchronous {
	if(self.started || self.cancelled) return;
	else isStarted = YES;
	
	NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:self.url
																cachePolicy:NSURLRequestReturnCacheDataElseLoad
															timeoutInterval:self.timeoutInterval];
	
	[request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"]; 
	
	for(NSString* key in _requestHeaders) {
		[request setValue:[_requestHeaders objectForKey:key] forHTTPHeaderField:key];
	}
	
	[[[self class] _requestsLock] lock];
	[[[self class] currentRequests] addObject:request];
	[[[self class] _requestsLock] unlock];

	_connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
	
	[request release];
}

+ (void)cleanUpRequest:(EGOHTTPRequest*)request {
	[[[self class] _requestsLock] lock];
	request.delegate = nil;
	[[self currentRequests] removeObject:request];
	[[[self class] _requestsLock] unlock];
}

+ (void)cancelRequestsForDelegate:(id)delegate {
	NSArray* requests = [[self currentRequests] copy];
	
	for(EGOHTTPRequest* request in requests) {
		if(![request isKindOfClass:[EGOHTTPRequest class]]) continue;
		if(request.delegate == delegate) {
			[request cancel];
		}
	}
	
	[requests release];
}

- (void)cancel {
	if(self.cancelled) return;
	else isCancelled = YES;
	
	[_connection cancel];
	
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

	[self.delegate retain];

	if([self.delegate respondsToSelector:self.didFinishSelector]) {
		[self.delegate performSelector:self.didFinishSelector withObject:self];
	}
	
	[self.delegate release];
	
	[[self class] cleanUpRequest:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	if(connection != _connection) return;
	
	[_error release];
	_error = [error retain];

	[self.delegate retain];
	
	if([self.delegate respondsToSelector:self.didFailSelector]) {
		[self.delegate performSelector:self.didFailSelector withObject:self withObject:error];
	}
	
	[self.delegate release];
	
	[[self class] cleanUpRequest:self];
}


- (void)dealloc {
	[[self class] cleanUpRequest:self];
	
	self.response = nil;
	self.delegate = nil;
	[_requestHeaders release];
	[_connection release];
	[_error release];
	[_URL release];
	
	[super dealloc];
}

@end
