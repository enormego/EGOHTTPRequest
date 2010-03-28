//
//  EGOHTTPFormRequest.h
//  EGOHTTPRequest
//
//  Created by Shaun Harrison on 3/28/10.
//  Copyright (c) 2010 enormego
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


@interface EGOHTTPFormRequest : EGOHTTPRequest {
@private
	NSMutableDictionary* _formData;
	NSStringEncoding _stringEncoding;
}

- (void)setPostValue:(id<NSObject>)value forKey:(NSString*)key;

@property(nonatomic,assign) NSStringEncoding stringEncoding; // Default: NSUTF8StringEncoding
@end

@interface NSString (EGOHTTPFormRequest)
- (NSString*)urlEncodedString; // Default: NSUTF8StringEncoding
- (NSString*)urlEncodedStringWithEncoding:(NSStringEncoding)encoding;
@end