//
//  IDZAvatarDownloader.m
//  IDZSocial/Common
//
// Copyright (c) 2013 iOSDeveloperZone.com
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
#import "IDZAvatarDownloader.h"

@interface IDZAvatarDownloader ()
{
    NSObject<IDZAvatarDownloader>* mDelegate;
    id mContext;
    NSURLRequest* mRequest;
    NSURLConnection* mConnection;
    NSMutableData* mData;
}
@end

@implementation IDZAvatarDownloader
@synthesize response = mResponse;

- (id)initWithURL:(NSURL*)url delegate:(NSObject<IDZAvatarDownloader>*)delegate context:(id)context
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSParameterAssert(url);
    NSParameterAssert(delegate);
    /* should check that delegate reponds to protocol */
    if(self = [super init])
    {
        mDelegate = delegate;
        mContext = context;
        mRequest = [NSURLRequest requestWithURL:url];
        mConnection = [[NSURLConnection alloc] initWithRequest:mRequest delegate:self startImmediately:NO];
        mData = [[NSMutableData alloc] init];
    }
    return self;
}

//- (void)dealloc
//{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
//}

- (void)startDownload
{
    [mConnection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [mConnection start];
    
}
- (void)cancelDownload
{
    [mConnection cancel];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    [mDelegate downloader:self didFailWithError:error context:mContext];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    mResponse = response;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    [mData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    UIImage* image = [UIImage imageWithData:mData];
    [mDelegate downloader:self didDownloadAvatar:image context:mContext];
}

@end
