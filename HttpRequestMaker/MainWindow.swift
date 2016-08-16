//
//  MainWindow.swift
//  HttpRequestMaker
//
//  Created by Hidden Butler Development on 8/11/16.
//  Copyright © 2016 Taylor Robbins. All rights reserved.
//

import Cocoa

class MainWindow: NSWindow
{
	override func close()
	{
		//the window can be closed but the application
		//will stay open by default. Since we only have
		//one window we want the application to close
		//if that window has been closed.
		exit(0);
	}
}
