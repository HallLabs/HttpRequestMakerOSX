//
//  HttpResponse.swift
//  HttpRequestMaker
//
//  Created by Hidden Butler Development on 8/11/16.
//  Copyright © 2016 Taylor Robbins. All rights reserved.
//

import Foundation
import Cocoa

class HttpResponse
{
	var Request: HttpRequest!;
	var ContentData: NSData!;
	var ContentStr: String!;
	var Headers: [String: String]!;
	var MIMEType: String!;
	var TextEncoding: String!;
	var StatusCode: Int!;
	var StatusCodeString: String!;
	
	init(request: HttpRequest, content: NSData, response: NSURLResponse?)
	{
		self.Request = request;
		self.ContentData = content;
		self.ContentStr = String(data: content, encoding: NSUTF8StringEncoding) ?? "[could not decode as UTF8] \(content.length) bytes";
		self.Headers = [:];
		
		if (response != nil)
		{
			self.MIMEType = response!.MIMEType ?? "";
			self.TextEncoding = response!.textEncodingName ?? "";
			if (response! is NSHTTPURLResponse)
			{
				let httpResponse = response as! NSHTTPURLResponse;
				self.StatusCode = httpResponse.statusCode;
				self.StatusCodeString =
					NSHTTPURLResponse.localizedStringForStatusCode(httpResponse.statusCode);
			}
			else
			{
				NSLog("The response was not an NSHTTPURLResponse");
			}
		}
		else
		{
			if (Constants.DEBUG) { NSLog("We did not recieve an NSURLResponse object."); }
			
			self.MIMEType = "";
			self.TextEncoding = "";
			self.StatusCode = 200;
			self.StatusCodeString = "no error";
		}
	}
	
	deinit
	{
		NSLog("Deallocating HttpResponse");
	}
}