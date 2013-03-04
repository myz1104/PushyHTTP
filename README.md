PushyHTTP
=========

A multi-threaded long poll based HTTP Server based upon Apple's CFNetwork Server Example.

TWConnectionDelegate class provides delegation needed to implement the multi-threaded long poll server logics.

TWConnectionTestSource class simulates a periodic firing data source, posting repeated notifications with random number along with its userInfo.

TWConnectionDelegate holds a request and register to the data source with help of NSNotificationCenter. On notified, the call-back block generates a JSON string as body of response with userInfo, sends the response, invalidate the conneciton, and unregister the observing itself.
