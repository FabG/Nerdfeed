//
//  NerdfeedAppDelegate.m
//  Nerdfeed
//
//  Created by Fabrice Guillaume on 1/30/13.
//  Copyright (c) 2013 Fabrice Guillaume. All rights reserved.
//

#import "NerdfeedAppDelegate.h"
#import "ListViewController.h"
#import "WebViewController.h"

@implementation NerdfeedAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    
    // Create an instance of ListViewController and set it as root view controller
    // of the navigation controller.
    ListViewController *lvc =
        [[ListViewController alloc]initWithStyle:UITableViewStylePlain];
    
    UINavigationController *masterNav =
        [[UINavigationController alloc] initWithRootViewController:lvc];
    
    // Instantiate WebViewcontroller to show web pages from the selected links and
    // set it as WebViewController of the ListViewController
    WebViewController *wvc = [[WebViewController alloc]init];
    [lvc setWebViewController:wvc];
    
    // check to make sure we're running on the iPad
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ) {
        NSLog(@"AppDelegate: iPad recognized - using split view");
        
        // webViewController must be in navigation controller
        UINavigationController *detailNav = [[UINavigationController alloc] initWithRootViewController:wvc];
        
        // When initializing a UIViewController, we pass it an array limited to 2 view
        // controllers: master and detail view controllers. The order determines their role
        NSArray *vcs = [NSArray arrayWithObjects:masterNav, detailNav, nil] ;
        
        UISplitViewController *svc = [[UISplitViewController alloc] init];
        
        // Set the delegate of the split view controller to the detail VC
        [svc setDelegate:wvc];
        
        [svc setViewControllers:vcs];
        
        // Set the root view controller of the window to the split view controller
        [[self window] setRootViewController:svc];
    } else {
        // On non-iPad devices, go with the old version and just add the
        // single nav controller to the window
        NSLog(@"AppDelegate: Non iPad - using single view");
        [[self window] setRootViewController:masterNav];
    }
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
