//
//  HttpRequest.swift
//  HttpRequestMaker
//
//  Created by Hidden Butler Development on 8/11/16.
//  Copyright © 2016 Taylor Robbins. All rights reserved.
//

import Foundation

class HttpRequest
{
	var Url: String!;
	var Method: String!;
	var Headers: [String: String]!;
	var Content: [String: String]!;
	var Files: [String]!;
	
	init(url: String, method: String)
	{
		self.Url = url;
		self.Method = method;
		self.Headers = [:];
		self.Content = [:];
		self.Files = [];
	}
	
	deinit
	{
		NSLog("Deallocating HttpRequest");
	}
	
	func DoRequest(session: NSURLSession, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void)
	{
		NSLog("Sending request to \"\(self.Url)\"");
		
		let nsRequest = NSMutableURLRequest(URL: NSURL(string: self.Url)!);
		
		nsRequest.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringCacheData;
		
		nsRequest.HTTPMethod = self.Method;
		
		nsRequest.allHTTPHeaderFields = [:];
		for (key,value) in self.Headers
		{
			nsRequest.allHTTPHeaderFields![key] = value;
		}
		
		var paramString = "";
		
		var isFirst = true;
		for (key,value) in self.Content
		{
			if (isFirst) { isFirst = false; }
			else { paramString += "&"; }
			
			paramString += key + "=" + value;
		}
		
		nsRequest.HTTPBody = paramString.dataUsingEncoding(NSUTF8StringEncoding)
		
		let nsTask = session.dataTaskWithRequest(nsRequest, completionHandler: completionHandler);
		
		//var responseData: String = "";
		//responseData = String(data: data!, encoding: NSUTF8StringEncoding)!;
		
		NSLog("Starting the task");
		nsTask.resume();
		
		//NSLog("Returning created response");
		//return HttpResponse(request: self, content: responseData);
	}
}
