//
//  ViewController.swift
//  HttpRequestMaker
//
//  Created by Hidden Butler Development on 8/10/16.
//  Copyright © 2016 Taylor Robbins. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController
{
	//--------------------------------------IBOutlets-----------------------------------------------
	
	@IBOutlet var UrlTextField: NSTextField!;
	
	@IBOutlet var HeaderTableView: NSTableView!;
	@IBOutlet var HeaderKeyTextField: NSTextField!;
	@IBOutlet var HeaderValueTextField: NSTextField!;
	@IBOutlet var HeaderAddButton: NSButton!;
	@IBOutlet var HeaderRemoveButton: NSButton!;
	
	@IBOutlet var ContentTableView: NSTableView!;
	@IBOutlet var ContentKeyTextField: NSTextField!;
	@IBOutlet var ContentValueTextField: NSTextField!;
	@IBOutlet var ContentAddButton: NSButton!;
	@IBOutlet var ContentRemoveButton: NSButton!;
	
	@IBOutlet var FilesTableView: NSTableView!;
	@IBOutlet var FileAddButton: NSButton!;
	@IBOutlet var FileRemoveButton: NSButton!;
	
	@IBOutlet var MethodPopup: NSPopUpButton!;
	@IBOutlet var SubmitRequestButton: NSButton!;
	@IBOutlet var UploadFilesButton: NSButton!;
	
	@IBOutlet var PastRequestTableView: NSTableView!;
	@IBOutlet var LoadRequestButton: NSButton!;
	
	@IBOutlet var ResultTabView: NSTabView!;
	
	@IBOutlet var RawTextTextView: NSTextView!;
	
	@IBOutlet var JSONTextView: NSTextView!;
	@IBOutlet var FormatJSONButton: NSButton!;
	@IBOutlet var JSONValidLabel: NSTextField!;
	
	@IBOutlet var ResultImageView: NSImageView!;
	
	@IBOutlet var ResponseCodeTextField: NSTextField!;
	@IBOutlet var TranslationTextField: NSTextField!;
	@IBOutlet var HResultTextField: NSTextField!;
	@IBOutlet var ContentTypeTextField: NSTextField!;
	@IBOutlet var ResponseHeadersTableView: NSTableView!;
	
	//---------------------------------------My Variables-------------------------------------------
	
	var Headers: [String: String] = [:];
	var Content: [String: String] = [:];
	var Files: [String] = [];
	var PastResponses: [HttpResponse] = [];
	var CurrentResponse: HttpResponse? = nil;
	var SubmittedRequest: HttpRequest? = nil;
	var OurSession: NSURLSession? = nil;
	
	//---------------------------------------View Controller Overrides------------------------------
	
    override func viewDidLoad()
	{
		super.viewDidLoad();
		NSLog("We hit viewDidLoad");
		
		Headers = ["header1":"value1"];
		Content = ["username":"harry", "password":"potter"];
		Files = ["/Users/hiddenbutler/Documents/somefile.png", "/Users/hiddenbutler/Images/picture.png"];
		PastResponses = [];
		CurrentResponse = nil;
		SubmittedRequest = nil;
		
		if (Constants.VERBOSE) { NSLog("Creation our NSURLSession"); }
		OurSession = NSURLSession(
			configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
			delegate:nil, delegateQueue:NSOperationQueue.mainQueue());
		
//		CurrentResponse = HttpResponse(request: HttpRequest(url: "http://google.com", method: "POST"),
//		                               content: "Response was generated.");
//		CurrentResponse!.Headers["h1"] = "Hello";
//		
//		PastResponses.insert(CurrentResponse!, atIndex: 0);
		
		//set the options on the Method PopupButton
		self.MethodPopup.removeAllItems();
		self.MethodPopup.addItemsWithTitles(["GET","POST","DELETE"]);
		self.MethodPopup.setTitle("POST");
		
		//Set data sources
		HeaderTableView.setDataSource(self);
		ContentTableView.setDataSource(self);
		ResponseHeadersTableView.setDataSource(self);
		FilesTableView.setDataSource(self);
		PastRequestTableView.setDataSource(self);
		
		//Set delegates
		HeaderTableView.setDelegate(self);
		ContentTableView.setDelegate(self);
		ResponseHeadersTableView.setDelegate(self);//<- This is currently unneeded?
		FilesTableView.setDelegate(self);
		PastRequestTableView.setDelegate(self);
		HeaderValueTextField.delegate = self;
		ContentValueTextField.delegate = self;
		//FilesOutlineView.setDelegate(self);
		//PastRequestOutlineView.setDelegate(self);
		
		RefreshResponseViews();
    }
	
	//I'm not actually sure what this is for?
	override var representedObject: AnyObject?
	{
		didSet
		{
			// Update the view, if already loaded.
		}
	}
	
	//--------------------------------------My Functions--------------------------------------------
	
	//This should be called whenever the selected response to view has
	//been changed. We will completely repopulate all of the pages in the
	//ResponseTabView to display the CurrentResponse if it has been filled.
	//If CurrentResposne is nil then we will display values that indicate so.
	//This function is also called in viewDidLoad().
	func RefreshResponseViews()
	{
		if (CurrentResponse == nil)
		{
			RawTextTextView.string = "No Response Selected";
			
			JSONTextView.string = "No Response Selected";
			JSONValidLabel.stringValue = "JSON: None";
			JSONValidLabel.textColor = NSColor(red: 0, green: 0, blue: 0, alpha: 1);
			
			ResultImageView.image = NSImage(named: "noImage");
			
			ResponseCodeTextField.stringValue = "";
			TranslationTextField.stringValue = "";
			HResultTextField.stringValue = "";
			ContentTypeTextField.stringValue = "No Response Selected";
			
		}
		else
		{
			RawTextTextView.string = CurrentResponse!.ContentStr;
			if (CurrentResponse!.ContentStr == "") { RawTextTextView.string = "[No Response Obtained]"; }
			
			if (CurrentResponse!.ContentStr == "")
			{
				JSONTextView.string = "[No Response Obtained]";
				JSONValidLabel.stringValue = "JSON: None";
				JSONValidLabel.textColor = NSColor(red: 0, green: 0, blue: 0, alpha: 1);
			}
			else
			{
				let formattedStr = JSONStringify(CurrentResponse!.ContentStr);
				if (formattedStr == "")
				{
					JSONTextView.string = CurrentResponse!.ContentStr;
					JSONValidLabel.stringValue = "JSON: Invalid";
					JSONValidLabel.textColor = NSColor(red: 1, green: 0, blue: 0, alpha: 1);
				}
				else
				{
					JSONTextView.string = formattedStr;
					JSONValidLabel.stringValue = "JSON: Valid";
					JSONValidLabel.textColor = NSColor(red: 0, green: 1, blue: 0, alpha: 1);
				}
			}
			
			ResultImageView.image = NSImage(named: "corruptImage");
			
			ResponseCodeTextField.stringValue = "200";
			TranslationTextField.stringValue = "OK";
			HResultTextField.stringValue = "No Errors";
			ContentTypeTextField.stringValue = "application/html";
		}
	}
	
	//This function checks the HeaderKeyTextField and HeaderValueTextField contents
	//and if both are not empty then we add (or replace) the key value pair in the
	//array of headers. 
	//After a success we also make the HeaderKeyTextField the first responder.
	func AddHeaderFromTextFields()
	{
		if (Constants.VERBOSE) { NSLog("Asked to add Header item \"\(HeaderKeyTextField.stringValue)\" => \"\(HeaderValueTextField.stringValue)\""); }
		
		if (HeaderKeyTextField.stringValue != "" &&
			HeaderValueTextField.stringValue != "")
		{
			self.Headers[HeaderKeyTextField.stringValue] = HeaderValueTextField.stringValue;
			HeaderKeyTextField.stringValue = "";
			HeaderValueTextField.stringValue = "";
			HeaderTableView.reloadData();
			HeaderKeyTextField.becomeFirstResponder();
		}
		else
		{
			if (Constants.DEBUG) { NSLog("Either Key or Value TextField was empty"); }
		}
	}
	//If an item is selected in the HeaderTableView then we will remove the corrisponding
	//item in the Header array and ask the TableView to deselect and reload it's items.
	func RemoveSelectedHeader()
	{
		if (Constants.DEBUG) { NSLog("Removing Header row \(HeaderTableView.selectedRow)"); }
		
		let row = HeaderTableView.selectedRow;
		HeaderTableView.deselectAll(self);
		HeaderRemoveButton.enabled = false;
		
		let sortedKeys = Array(self.Headers.keys).sort(<);
		let key = sortedKeys[row];
		
		self.Headers.removeValueForKey(key);
		
		HeaderTableView.reloadData();
	}
	
	//This function checks the ContentKeyTextField and ContentValueTextField contents
	//and if both are not empty then we add (or replace) the key value pair in the
	//array of content.
	//After a success we also make the ContentKeyTextField the first responder.
	func AddContentFromTextFields()
	{
		if (Constants.VERBOSE) { NSLog("Asked to add Content item \"\(ContentKeyTextField.stringValue)\" => \"\(ContentValueTextField.stringValue)\""); }
		
		if (ContentKeyTextField.stringValue != "" &&
			ContentValueTextField.stringValue != "")
		{
			self.Content[ContentKeyTextField.stringValue] = ContentValueTextField.stringValue;
			ContentKeyTextField.stringValue = "";
			ContentValueTextField.stringValue = "";
			ContentTableView.reloadData();
			ContentKeyTextField.becomeFirstResponder();
		}
		else
		{
			if (Constants.DEBUG) { NSLog("Either Key or Value TextField was empty"); }
		}
	}
	//If an item is selected in the ContentTableView then we will remove the corrisponding
	//item in the Content array and ask the TableView to deselect and reload it's items.
	func RemoveSelectedContent()
	{
		if (Constants.DEBUG) { NSLog("Removing Content row \(ContentTableView.selectedRow)"); }
		
		let row = ContentTableView.selectedRow;
		ContentTableView.deselectAll(self);
		ContentRemoveButton.enabled = false;
		
		let sortedKeys = Array(self.Content.keys).sort(<);
		let key = sortedKeys[row];
		
		self.Content.removeValueForKey(key);
		
		ContentTableView.reloadData();
	}
	
	func AddFileFromPath(path: String)
	{
		Files.insert(path, atIndex: Files.count);
		FilesTableView.reloadData();
	}
	func RemoveSelectedFile()
	{
		if (Constants.DEBUG) { NSLog("Removing File row \(FilesTableView.selectedRow)"); }
		
		let row = FilesTableView.selectedRow;
		FilesTableView.deselectAll(self);
		FileRemoveButton.enabled = false;
		
		Files.removeAtIndex(row);
		
		FilesTableView.reloadData();
	}
	
	func HandleResponse(data: NSData?, response: NSURLResponse?, error: NSError?) -> Void
	{
		if (data != nil)
		{
			if (SubmittedRequest != nil)
			{
				if (Constants.DEBUG) { NSLog("A response was recieved"); }
				
				let newResponse = HttpResponse(
					request: self.SubmittedRequest!,
					content: String(data: data!, encoding: NSUTF8StringEncoding)!);
				self.SubmittedRequest = nil;
				
				PastResponses.insert(newResponse, atIndex: 0);
				
				NSLog("There are now \(PastResponses.count) past responses.");
				
				PastRequestTableView.reloadData();
				PastRequestTableView.selectRowIndexes(NSIndexSet(index: 0), byExtendingSelection: false);
				CurrentResponse = PastResponses[0];
				RefreshResponseViews();
				
			}
			else
			{
				NSLog("A response came back but the SubmittedRequest was not set");
			}
		}
		else
		{
			NSLog("NSData in response was empty");
		}
	}
	
	func JSONStringify(value: String) -> String
	{
		let strData = value.dataUsingEncoding(NSUTF8StringEncoding);
		if (strData == nil) { return ""; }
		
		let JSONobj = try? NSJSONSerialization.JSONObjectWithData(strData!, options: []);
		if (JSONobj == nil) { return ""; }
		
		let data = try? NSJSONSerialization.dataWithJSONObject(JSONobj!,
			options: NSJSONWritingOptions.PrettyPrinted);
		if (data == nil) { return ""; }
		
		let formattedStr = NSString(data: data!, encoding: NSUTF8StringEncoding);
		if (formattedStr == nil) { return ""; }
		
		return formattedStr! as String;
	}

	//--------------------------------------IBActions (Button Presses)------------------------------
	
	@IBAction func SubmitRequestPressed(sender: AnyObject)
	{
		if (Constants.VERBOSE) { NSLog("Submit Request Button Pressed"); }
		
		let url = UrlTextField.stringValue;
		if (url == "")
		{
			if (Constants.DEBUG) { NSLog("UrlTextField was empty"); }
			UrlTextField.becomeFirstResponder();
			return;
		}
		let request = HttpRequest(url: url, method: "POST");
		for (key,value) in Headers
		{
			request.Headers[key] = value;
		}
		for (key,value) in Content
		{
			request.Content[key] = value;
		}
		
		self.SubmittedRequest = request;
		
		request.DoRequest(OurSession!, completionHandler: self.HandleResponse);
	}
	
	@IBAction func HeaderAddButtonPressed(sender: AnyObject)
	{
		if (Constants.VERBOSE) { NSLog("Header Add Button Pressed"); }
		
		AddHeaderFromTextFields();
	}
	@IBAction func HeaderRemoveButtonPressed(sender: AnyObject)
	{
		if (Constants.VERBOSE) { NSLog("Header Remove Button Pressed"); }
		
		RemoveSelectedHeader();
	}
	
	@IBAction func ContentAddButtonPressed(sender: AnyObject)
	{
		if (Constants.VERBOSE) { NSLog("Content Add Button Pressed"); }
		
		AddContentFromTextFields();
	}
	@IBAction func ContentRemoveButtonPressed(sender: AnyObject)
	{
		if (Constants.VERBOSE) { NSLog("Content Remove Button Pressed"); }
		
		RemoveSelectedContent();
	}
	
	@IBAction func FileAddButtonPressed(sender: AnyObject)
	{
		
	}
	@IBAction func FileRemoveButtonPressed(sender: AnyObject)
	{
		RemoveSelectedFile();
	}
	
	@IBAction func FormatJSONButtonPressed(sender: AnyObject)
	{
		if (CurrentResponse == nil) { return; }
		
		if (JSONTextView.string == nil || JSONTextView.string == "")
		{
			JSONTextView.string = "";
			JSONValidLabel.stringValue = "JSON: None";
			JSONValidLabel.textColor = NSColor(red: 0, green: 0, blue: 0, alpha: 1);
		}
		else
		{
			let formattedStr = JSONStringify(JSONTextView.string!);
			if (formattedStr == "")
			{
				JSONTextView.string = JSONTextView.string!;
				JSONValidLabel.stringValue = "JSON: Invalid";
				JSONValidLabel.textColor = NSColor(red: 1, green: 0, blue: 0, alpha: 1);
			}
			else
			{
				JSONTextView.string = formattedStr;
				JSONValidLabel.stringValue = "JSON: Valid";
				JSONValidLabel.textColor = NSColor(red: 0, green: 1, blue: 0, alpha: 1);
			}
		}
	}
	
	//--------------------------------------Other---------------------------------------------------
	
	
}

//We are the datasource for HeaderTableView, ContentTableView, and ResponseHeadersTableView
extension MainViewController: NSTableViewDataSource
{
	//This is called by the NSTableView when it wants to know how many rows
	//there are in the table. We simply have to return an integer. It will
	//generate the NSTextFields in each cell and then ask us what to put in
	//each cell. We are the datasource for 3 different NSTableViews so we
	//have to check who is asking before returning a number.
	func numberOfRowsInTableView(tableView: NSTableView) -> Int
	{
		if (Constants.VERBOSE) { NSLog("Asking for num of rows for NSTableView \"\(tableView.identifier)\""); }
		
		if (tableView.identifier == "Headers")
		{
			return self.Headers.count;
		}
		else if (tableView.identifier == "Content")
		{
			return self.Content.count;
		}
		else if (tableView.identifier == "ResponseHeaders")
		{
			return CurrentResponse?.Headers.count ?? 0;
		}
		else if (tableView.identifier == "Files")
		{
			return self.Files.count;
		}
		else if (tableView.identifier == "PastRequests")
		{
			NSLog("Told the UI that there are \(self.PastResponses.count) responses.");
			return self.PastResponses.count;
		}
		else
		{
			return 0;
		}
		//return CurrentResponse?.Request.Headers.count ?? 5;
	}
	
	//This is called whenever the NSTableView wants to know what should go
	//in a specific cell. We return strings and they populate the NSTextFields
	//that populate each cell. We are the datasource for 3 different NSTableViews
	//so we have to check which one is asking before returning values.
	func tableView(tableView: NSTableView,
	               objectValueForTableColumn column: NSTableColumn?,
				   row: Int) -> AnyObject?
	{
		if (Constants.VERBOSE) { NSLog("NSTableView \"\(tableView.identifier)\" asking for (\(column?.title),\(row))"); }
		
		if (tableView.identifier == "Headers")
		{
			let sortedKeys = Array(self.Headers.keys).sort(<);
			let key = sortedKeys[row];
			if (column != nil && column!.title == "Key")
			{
				return key;
			}
			else if (column != nil && column!.title == "Value")
			{
				return self.Headers[key] ?? "";
			}
			else
			{
				return column?.title ?? "no column";
			}
		}
		else if (tableView.identifier == "Content")
		{
			let sortedKeys = Array(self.Content.keys).sort(<);
			let key = sortedKeys[row];
			if (column != nil && column!.title == "Key")
			{
				return key;
			}
			else if (column != nil && column!.title == "Value")
			{
				return self.Content[key] ?? "";
			}
			else
			{
				return column?.title ?? "no column";
			}
		}
		else if (tableView.identifier == "ResponseHeaders")
		{
			if (CurrentResponse != nil)
			{
				let sortedKeys = Array(self.CurrentResponse!.Headers.keys).sort(<);
				let key = sortedKeys[row];
				if (column != nil && column!.title == "Key")
				{
					return key;
				}
				else if (column != nil && column!.title == "Value")
				{
					return self.CurrentResponse!.Headers[key] ?? "";
				}
				else
				{
					return column?.title ?? "no column";
				}
			}
			else
			{
				return "null";
			}
		}
		else if (tableView.identifier == "Files")
		{
			if (column != nil && column!.title == "Name")
			{
				if (row < self.Files.count)
				{
					return self.Files[row];
				}
				else
				{
					return "[Out of index]";
				}
			}
			else
			{
				return column?.title ?? "no column";
			}
		}
		else if (tableView.identifier == "PastRequests")
		{
			NSLog("Was asked by the UI for Response \(row)");
			if (column != nil && column!.title == "Name")
			{
				if (row < self.PastResponses.count)
				{
					return self.PastResponses[row].Request!.Url;
				}
				else
				{
					return "[Out of index]";
				}
			}
			else
			{
				return column?.title ?? "no column";
			}
		}
		else
		{
			return "unknown data source";
		}
	}
}

//We are the delegate for HeaderTableView, ContentTableView, and ResponseHeadersTableView
extension MainViewController: NSTableViewDelegate
{
	
	//This function is fired when the user is done editing a specific cell
	//and handles the inputted information being set in the actual data source
	//(which is this case is one of 3 things)
	func tableView(tableView: NSTableView,
	               setObjectValue object: AnyObject?,
				   forTableColumn column: NSTableColumn?,
				   row: Int)
	{
		if (Constants.VERBOSE) { NSLog("NSTableView \"\(tableView.identifier)\" done editing in (\(column?.title),\(row))"); }
		
		if (tableView.identifier == "Headers")
		{
			let sortedKeys = Array(self.Headers.keys).sort(<);
			let key = sortedKeys[row];
			if (column != nil && column!.title == "Key")
			{
				if (object is String)
				{
					let newKey = object as! String;
					self.Headers[newKey] = self.Headers[key];
					self.Headers.removeValueForKey(key);
					tableView.reloadData();
				}
				else
				{
					NSLog("Input was not a string?");
				}
			}
			else if (column != nil && column!.title == "Value")
			{
				self.Headers.updateValue(object as? String ?? "Wasn't a string", forKey: key);
			}
			else
			{
				NSLog("Unkown table column (setting)");
			}
		}
		else if (tableView.identifier == "Content")
		{
			let sortedKeys = Array(self.Content.keys).sort(<);
			let key = sortedKeys[row];
			if (column != nil && column!.title == "Key")
			{
				if (object is String)
				{
					let newKey = object as! String;
					self.Content[newKey] = self.Content[key];
					self.Content.removeValueForKey(key);
					tableView.reloadData();
				}
				else
				{
					NSLog("Input was not a string?");
				}
			}
			else if (column != nil && column!.title == "Value")
			{
				self.Content.updateValue(object as? String ?? "Wasn't a string", forKey: key);
			}
			else
			{
				NSLog("Unkown table column (setting)");
			}
		}
		else if (tableView.identifier == "ResponseHeaders")
		{
			NSLog("Should not be able to edit ResponseHeaders' TextFields.");
		}
		else if (tableView.identifier == "Files")
		{
			NSLog("Should not be able to edit Files' TextFields.");
		}
		else if (tableView.identifier == "PastRequests")
		{
			NSLog("Should not be able to edit PastRequests' TextFields.");
		}
		else
		{
			NSLog("Unknown tableview to set data for");
		}
	}
	
	//This function is called anytime the selection is about to change for the NSTableView.
	//It tells passes us the proposed selection set and we have to return the NSIndexSet
	//that we want to actually be selected. In this case we simply return the set that was
	//passed to us. However first we make sure we do any checking and updating we need to
	//when the selection is changed. We use this to enable and disable the "Remove Selected"
	//buttons for the "Header" and "Content" NSTableViews
	func tableView(tableView: NSTableView,
	               selectionIndexesForProposedSelection indexes: NSIndexSet) -> NSIndexSet
	{
		if (Constants.VERBOSE) { NSLog("Selection Proposed \(indexes.count)"); }
		
		if (tableView.identifier == "Headers")
		{
			if (indexes.count == 1)
			{
				HeaderRemoveButton.enabled = true;
			}
			else
			{
				HeaderRemoveButton.enabled = false;
			}
		}
		else if (tableView.identifier == "Content")
		{
			if (indexes.count == 1)
			{
				ContentRemoveButton.enabled = true;
			}
			else
			{
				ContentRemoveButton.enabled = false;
			}
		}
		else if (tableView.identifier == "ResponseHeaders")
		{
			
		}
		else if (tableView.identifier == "Files")
		{
			if (indexes.count == 1)
			{
				FileRemoveButton.enabled = true;
			}
			else
			{
				FileRemoveButton.enabled = false;
			}
		}
		else if (tableView.identifier == "PastRequests")
		{
			if (indexes.count == 1)
			{
				LoadRequestButton.enabled = true;
				if (indexes.firstIndex < self.PastResponses.count && indexes.firstIndex >= 0)
				{
					self.CurrentResponse = self.PastResponses[indexes.firstIndex];
				}
				else
				{
					LoadRequestButton.enabled = false;
					self.RefreshResponseViews();
					return NSIndexSet();
				}
			}
			else
			{
				LoadRequestButton.enabled = false;
			}
			self.RefreshResponseViews();
		}
		
		return indexes;
	}
	
	//This is fired when the user selects a column header (normally indicating to select
	//the whole column). We can return true or false telling NSTableView whether to actually
	//select the column or not. We disable column selection by always returning false.
	func tableView(tableView: NSTableView,
	               shouldSelectTableColumn column: NSTableColumn?) -> Bool
	{
		if (Constants.VERBOSE) { NSLog("Disallowed selection of column \"\(column?.title)\""); }
		return false;
	}
}

//We are the delegate for HeaderValueTextField and ContentValueTextField
extension MainViewController: NSTextFieldDelegate
{
	//This is called whenever the user tries to leave a recently changed string
	//in the NSTextField (usually to select a different control element). It is
	//also fired when the user presses enter. Currently we handle this event for
	//HeaderValueTextField and ContentValueTextField to allow you to quickly add
	//items using the enter key after entering your value.
	func control(control: NSControl,
	             textShouldEndEditing fieldEditor: NSText) -> Bool
	{
		if (Constants.VERBOSE) { NSLog("We were asked whether we should end a text edit for \"\(control.identifier)\""); }
		
		if (control.identifier == "HeaderValue") { AddHeaderFromTextFields(); }
		if (control.identifier == "ContentValue") { AddContentFromTextFields(); }
		
		return true;
	}
}
