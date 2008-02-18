// Copyright (c) 2006-2008 Simon Fell
//
// Permission is hereby granted, free of charge, to any person obtaining a 
// copy of this software and associated documentation files (the "Software"), 
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense, 
// and/or sell copies of the Software, and to permit persons to whom the 
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included 
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
// THE SOFTWARE.
//

#import "WelcomeController.h"

@implementation WelcomeController

- (void)awakeFromNib {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkShowWelcome:) name:NSApplicationDidFinishLaunchingNotification object:nil];
}

- (float)currentVersion {
	NSDictionary *plist = [[NSBundle mainBundle] infoDictionary];
	NSString * currentVersionString = [plist objectForKey:@"CFBundleVersion"];
	return currentVersionString == nil ? 0.0f : [currentVersionString floatValue];	
}

- (void)installScripts:(id)sender {
	[installList release];
	installList = nil;
	[window makeKeyAndOrderFront:self];
	[self setInstallText:@"Installing Scripts..."];
	[self setInstallProgress:1];
	[self setInstallDone:NO];
	[NSTimer scheduledTimerWithTimeInterval:0.10 target:self selector:@selector(startInstall:) userInfo:nil repeats:NO];
}

- (void)checkShowWelcome:(NSNotification *)n {
	float currentVersion = [self currentVersion];
	float lastRegistered = [[NSUserDefaults standardUserDefaults] floatForKey:@"installedVersion"];
	if (currentVersion > lastRegistered) {
		[self installScripts:self];
	} else {
		[self setInstallText:@""];
		[self setInstallProgress:0];
		[self setInstallDone:YES];
	}
}

- (void)dealloc {
	[text release];
	[super dealloc];
}

- (void)buildInstallList {
	NSString *a1 = [[NSBundle mainBundle] pathForResource:@"Add Email to Salesforce.com"   ofType:@"scpt" inDirectory:@"mail scripts"];
	NSString *a2 = [[NSBundle mainBundle] pathForResource:@"Create Case In Salesforce.com" ofType:@"scpt" inDirectory:@"mail scripts"];
	NSString *e1 = [[NSBundle mainBundle] pathForResource:@"Add Email to Salesforce.com"   ofType:@"scpt" inDirectory:@"entourage scripts"];
	NSString *e2 = [[NSBundle mainBundle] pathForResource:@"Create Case In Salesforce.com" ofType:@"scpt" inDirectory:@"entourage scripts"];
	NSArray *library = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	NSString *mailScripts = [[library objectAtIndex:0] stringByAppendingPathComponent:@"Scripts/Applications/Mail"];
	NSArray *docs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *entourageScripts = [[docs objectAtIndex:0] stringByAppendingPathComponent:@"Microsoft User Data/Entourage Script Menu Items"];
	
	installList = [[NSMutableArray alloc] init];
	[installList addObject:[NSArray arrayWithObjects:a1, mailScripts, nil]];
	[installList addObject:[NSArray arrayWithObjects:a2, mailScripts, nil]];
	[installList addObject:[NSArray arrayWithObjects:e1, entourageScripts, nil]];
	[installList addObject:[NSArray arrayWithObjects:e2, entourageScripts, nil]];
}

- (void)ensureDirectoryExists:(NSString *)dir {
	if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
		[self ensureDirectoryExists:[dir stringByDeletingLastPathComponent]];
		[[NSFileManager defaultManager] createDirectoryAtPath:dir attributes:nil];	
	}
}

- (void)fileManager:(NSFileManager *)manager willProcessPath:(NSString *)path {
}

-(BOOL)fileManager:(NSFileManager *)manager shouldProceedAfterError:(NSDictionary *)errorInfo {
    int result;
    result = NSRunAlertPanel(@"Maildrop", @"File operation error:%@ with file: %@\r\n\r\nPlease fix and select Reinstall Scripts from the help menu", @"OK", nil, nil, 
            [errorInfo objectForKey:@"Error"], 
            [errorInfo objectForKey:@"Path"]);
    return NO;
}

- (void)startInstall:(id)sender {
	if (installList == nil) 
		[self buildInstallList];
	
	if ([installList count] > 0) {
		NSArray *todo = [installList lastObject];
		NSString *destDir = [todo objectAtIndex:1];
		NSString *srcFile = [todo objectAtIndex:0];
		NSString *dstFile = [destDir stringByAppendingPathComponent:[srcFile lastPathComponent]];
		[self ensureDirectoryExists:destDir];
		if ([[NSFileManager defaultManager] fileExistsAtPath:dstFile])
			[[NSFileManager defaultManager] removeFileAtPath:dstFile handler:self];
		if(![[NSFileManager defaultManager] copyPath:srcFile toPath:dstFile handler:self])
			NSLog(@"Failed on copy of %@ to %@", srcFile, dstFile);
		[installList removeLastObject];
		[self setInstallProgress:progress+1];
		[NSTimer scheduledTimerWithTimeInterval:0.15 target:self selector:@selector(startInstall:) userInfo:nil repeats:NO];
	} else {
		[self setInstallText:@"Finished Installing Scripts"];
		[self setInstallDone:YES];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:[self currentVersion]] forKey:@"installedVersion"];
	}
}

- (IBAction)showHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"access" inBook:@"Maildrop Help"];
}

- (int)installProgress {
	return progress;
}

- (void)setInstallProgress:(int)newInstallProgress {
	progress = newInstallProgress;
}

- (NSString *)installText {
	return text;
}

- (void)setInstallText:(NSString *)aInstallText {
	aInstallText = [aInstallText copy];
	[text release];
	text = aInstallText;
}

- (BOOL)installDone {
	return done;
}

- (void)setInstallDone:(BOOL)newInstallDone {
	done = newInstallDone;
}

@end
