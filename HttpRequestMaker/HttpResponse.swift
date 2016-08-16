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
	var ContentStr: String!;
	var Headers: [String: String]!;
	
	init(request: HttpRequest, content: String)
	{
		self.Request = request;
		self.ContentStr = content;
		self.Headers = [:];
	}
	
	deinit
	{
		NSLog("Deallocating HttpResponse");
	}
}