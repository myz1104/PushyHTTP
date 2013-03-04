//
//  TWConnectionDelegate.m
//  ThreadedWeb
//
//  Created by Chen Zhang on 3/5/13.
//  Copyright (c) 2013 Chen Zhang. All rights reserved.
//

#import "TWConnectionDelegate.h"





@implementation TWConnectionTestSource
NSString *kMimicNotification= @"pure_mimic";
- (id)initWithInterval:(NSTimeInterval)interval {
    self = [super init];
    if (self) {
        _timer = [NSTimer timerWithTimeInterval:interval
                                         target:self
                                       selector:@selector(mimicEvent)
                                       userInfo:nil
                                        repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (void)mimicEvent{
    int s = rand();
    [[NSNotificationCenter defaultCenter] postNotificationName:kMimicNotification
                                                        object:self
                                                      userInfo:@{@"val": @(s)}];
}
@end

@interface TWConnectionDelegate ()
@property (strong,nonatomic) NSMutableDictionary *observance;
@end
@implementation TWConnectionDelegate
- (id) init {
    self = [super init];
    if (self) {
        _observance = [NSMutableDictionary dictionaryWithCapacity:3];
        
    }
    return self;
}
- (void)HTTPServer:(HTTPServer *)server didMakeNewConnection:(HTTPConnection *)connection {
    NSLog(@"server did make new connection:%@, %@", server, connection);
}
- (void)HTTPConnection:(HTTPConnection *)connection didReceiveRequest:(HTTPServerRequest *)mess {
    CFHTTPMessageRef request = [mess request];
    HTTPServer *server = [connection server];
    
    NSString *vers = (__bridge_transfer id)CFHTTPMessageCopyVersion(request);
    if (!vers || ![vers isEqual:(id)kCFHTTPVersion1_1]) {
        CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 505, NULL, (__bridge CFStringRef)vers); // Version Not Supported
        [mess setResponse:response];
        CFRelease(response);
        return;
    }
    
    NSString *method = (__bridge_transfer id)CFHTTPMessageCopyRequestMethod(request);
    if (!method) {
        CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 400, NULL, kCFHTTPVersion1_1); // Bad Request
        [mess setResponse:response];
        CFRelease(response);
        return;
    }
    
    if ([method isEqual:@"GET"] || [method isEqual:@"HEAD"]) {
        NSURL *uri = (__bridge_transfer NSURL *)CFHTTPMessageCopyRequestURL(request);
        NSURL *url = [NSURL URLWithString:[uri path] relativeToURL:[server documentRoot]];
        NSString *path = [uri path];
        NSRange prefixRange = [path rangeOfString:@"/wait/"];
        if (prefixRange.location == 0) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, DISPATCH_QUEUE_SERIAL), ^{
                // Parse observing resources indicator
                NSString *key = [path substringFromIndex:prefixRange.length];
                // TODO: replace with predicate
                if ([key isEqualToString:@"10"]) {
                    NSString *localKey = [[NSUUID UUID] UUIDString];
                    // Register for resource notification
                    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
                    id localObserver = [center addObserverForName:kMimicNotification
                                                           object:nil
                                                            queue:[NSOperationQueue currentQueue]
                                                       usingBlock:^(NSNotification *note) {
                                                           if ([connection isValid]) {
                                                               // Generate response and send
                                                               NSData *data = [NSJSONSerialization dataWithJSONObject:note.userInfo
                                                                                                              options:0
                                                                                                                error:nil];
                                                               
                                                               CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 200, NULL, kCFHTTPVersion1_1);
                                                               NSString *lengthString = [NSString stringWithFormat:@"%d", data.length];
                                                               CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Length"), (__bridge CFStringRef)lengthString);
                                                               CFHTTPMessageSetBody(response, (__bridge CFDataRef) data);
                                                               // -setResponse: actually makes the outputStream begin writing outgoing bytes
                                                               [mess setResponse:response];
                                                               CFRelease(response);
                                                               
                                                           }
                                                           // Clean-up anyway.
                                                           [self removeObservanceWithKey:localKey];
                                                       }];
                    // Register service-observance relationship
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        NSLog(@"Register observance for key:%@",localKey);
                        self.observance[localKey] = localObserver;
                    });

                }
                
            });
            return;
        }
        
        
        NSData *data = [NSData dataWithContentsOfURL:url];
        
        if (!data) {
            CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 404, NULL, kCFHTTPVersion1_1); // Not Found
            [mess setResponse:response];
            CFRelease(response);
            return;
        }
        
        CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 200, NULL, kCFHTTPVersion1_1); // OK
        CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Length", (__bridge CFStringRef)[NSString stringWithFormat:@"%d", [data length]]);
        if ([method isEqual:@"GET"]) {
            CFHTTPMessageSetBody(response, (__bridge CFDataRef)data);
        }
        [mess setResponse:response];
        CFRelease(response);
        return;
    }
    
    CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 405, NULL, kCFHTTPVersion1_1); // Method Not Allowed
    [mess setResponse:response];
    CFRelease(response);

    
}
- (void)HTTPConnection:(HTTPConnection *)conn didSendResponse:(HTTPServerRequest *)mess {
    NSLog(@"didSendResponse, invalidate connection: %@", conn);
    [conn invalidate];
}
- (void)removeObservanceWithKey:(NSString *)key {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"remove observance for key: %@", key);
        [[NSNotificationCenter defaultCenter] removeObserver:self.observance[key]];
        [self.observance removeObjectForKey:key];
    });
}
@end
