//
//  TWConnectionDelegate.h
//  ThreadedWeb
//
//  Created by Chen Zhang on 3/5/13.
//  Copyright (c) 2013 Chen Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTTPServer.h"

@interface TWConnectionTestSource : NSObject
@property (strong,nonatomic) NSTimer *timer;
- (id)initWithInterval:(NSTimeInterval)interval;
@end


@interface TWConnectionDelegate : NSObject
- (void)HTTPServer:(HTTPServer *)server didMakeNewConnection:(HTTPConnection *)connection;
- (void)HTTPConnection:(HTTPConnection *)connection didReceiveRequest:(HTTPServerRequest *)request;
- (void)HTTPConnection:(HTTPConnection *)conn didSendResponse:(HTTPServerRequest *)mess;

@end
