/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "RLViewController.h"

#import <CoreLocation/CoreLocation.h>

#import "RLAppDelegate.h"

#import "Konashi.h"

static NSString *loadingText = @"Loading...";

@interface RLViewController () <FBLoginViewDelegate>

//@property (strong, nonatomic) IBOutlet UIButton *buttonPostStatus;
@property (strong, nonatomic) IBOutlet UITextField *textObjectID;
@property (strong, nonatomic) IBOutlet UITextView *textOutput;
@property (strong, nonatomic) FBRequestConnection *requestConnection;
@property FBProfilePictureView *fbProfile;
@property (strong, nonatomic) id<FBGraphUser> loggedInUser;
@property NSUInteger likescount;

- (void)sendRequests;
@end

@implementation RLViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    // Create Login View so that the app will be granted "status_update" permission.
    
    [Konashi initialize];
    
    [Konashi addObserver:self selector:@selector(ready) name:KONASHI_EVENT_READY];
    
    
    FBLoginView *loginview = [[FBLoginView alloc] init];
    loginview.frame = CGRectOffset(loginview.frame, 5, 5);
    
#ifdef __IPHONE_7_0
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_7_0
        if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
            loginview.frame = CGRectOffset(loginview.frame, 5, 25);
        }
#endif
#endif
#endif
    
    loginview.delegate = self;
    
    [self.view addSubview:loginview];
    
    [loginview sizeToFit];
}

- (void)viewDidUnload {
//    self.buttonPickFriends = nil;
//    self.buttonPickPlace = nil;
//    self.buttonPostPhoto = nil;
//    self.buttonPostStatus = nil;
//    self.labelFirstName = nil;
//    self.loggedInUser = nil;
//    self.profilePic = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
    // first get the buttons set for login mode
//    self.buttonPostPhoto.enabled = YES;
//    self.buttonPostStatus.enabled = YES;
//    self.buttonPickFriends.enabled = YES;
//    self.buttonPickPlace.enabled = YES;
    
    // "Post Status" available when logged on and potentially when logged off.  Differentiate in the label.
//    [self.buttonPostStatus setTitle:@"Post Status Update (Logged On)" forState:self.buttonPostStatus.state];
    
    if (FBSession.activeSession.isOpen) {
        [self sendRequests];
    }else{
    
    }
    
}

- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView
                            user:(id<FBGraphUser>)user {
    // here we use helper properties of FBGraphUser to dot-through to first_name and
    // id properties of the json response from the server; alternatively we could use
    // NSDictionary methods such as objectForKey to get values from the my json object
    //self.labelFirstName.text = [NSString stringWithFormat:@"Hello %@!", user.first_name];
    // setting the profileID property of the FBProfilePictureView instance
    // causes the control to fetch and display the profile picture for the user
    //self.profilePic.profileID = user.id;
    self.loggedInUser = user;
    NSLog(@"%@", self.loggedInUser.id);
    
}


- (void)loginView:(FBLoginView *)loginView handleError:(NSError *)error {
    // see https://developers.facebook.com/docs/reference/api/errors/ for general guidance on error handling for Facebook API
    // our policy here is to let the login view handle errors, but to log the results
    NSLog(@"FBLoginView encountered an error=%@", error);
}


- (void)sendRequests {
    // extract the id's for which we will request the profile
    NSString *fbid = self.loggedInUser.id;
    
    
    self.textOutput.text = loadingText;
    if ([self.textObjectID isFirstResponder]) {
        [self.textObjectID resignFirstResponder];
    }
    
    // create the connection object
    FBRequestConnection *newConnection = [[FBRequestConnection alloc] init];
    
    // for each fbid in the array, we create a request object to fetch
    // the profile, along with a handler to respond to the results of the request
    
    // create a handler block to handle the results of the request for fbid's profile
    FBRequestHandler handler =
    ^(FBRequestConnection *connection, id result, NSError *error) {
        // output the results of the request
        [self requestCompleted:connection forFbID:fbid result:result error:error];
    };
    
    
    
    // create the request object, using the fbid as the graph path
    // as an alternative the request* static methods of the FBRequest class could
    // be used to fetch common requests, such as /me and /me/friends
    FBRequest *request = [[FBRequest alloc] initWithSession:FBSession.activeSession
                                                  graphPath:fbid];
    
    
    
    // add the request to the connection object, if more than one request is added
    // the connection object will compose the requests as a batch request; whether or
    // not the request is a batch or a singleton, the handler behavior is the same,
    // allowing the application to be dynamic in regards to whether a single or multiple
    // requests are occuring
    [newConnection addRequest:request completionHandler:handler];
    
    // if there's an outstanding connection, just cancel
    [self.requestConnection cancel];
    
    // keep track of our connection, and start it
    self.requestConnection = newConnection;
    [newConnection start];
}

// FBSample logic
// Report any results.  Invoked once for each request we make.
- (void)requestCompleted:(FBRequestConnection *)connection
                 forFbID:fbID
                  result:(id)result
                   error:(NSError *)error {
    // not the completion we were looking for...
    if (self.requestConnection &&
        connection != self.requestConnection) {
        return;
    }
    
    // clean this up, for posterity
    self.requestConnection = nil;
    
    if ([self.textOutput.text isEqualToString:loadingText]) {
        self.textOutput.text = @"";
    }
    
    NSString *text;
    if (error) {
        // error contains details about why the request failed
        text = error.localizedDescription;
    } else {
        //NSLog(@"%@", result);
        // result is the json response from a successful request
        NSDictionary *dictionary = (NSDictionary *)result;
        // we pull the name property out, if there is one, and display it
        text = (NSString *)[dictionary objectForKey:@"name"];
    }
    
    self.textOutput.text = [NSString stringWithFormat:@"%@%@: %@\r\n",
                            self.textOutput.text,
                            [fbID stringByTrimmingCharactersInSet:
                             [NSCharacterSet whitespaceAndNewlineCharacterSet]],
                            text];
    //NSLog(@"%@", self.)
    
    [FBRequestConnection startWithGraphPath:@"/me?fields=posts.limit(4).fields(likes)"
                                 parameters:nil
                                 HTTPMethod:@"GET"
                          completionHandler:^(
                                              FBRequestConnection *connection,
                                              id result2,
                                              NSError *error
                                              ) {
                              /* handle the result */
                              
                              //NSLog(@"%@", result2);
                              //NSDictionary *fields = [[[result2 objectForKey:@"data"] objectAtIndex:3] objectForKey:@"likes"];
                              NSDictionary *dic = [[[result2 objectForKey:@"posts"]  objectForKey:@"data"] objectAtIndex:1];
                              
                              
                              NSLog(@"%@", dic);
                              
                              //NSLog(@"%d", [dic count]);
                              
                              BOOL is_exists = ([dic objectForKey:@"likes"] != nil);
                              //NSLog(@"%d", is_exists);
                              int ct;
                              if(is_exists){
                                  //NSLog(@"%@", [[dic objectForKey:@"likes"] objectForKey:@"data"]);
                                self.likescount= [[[dic objectForKey:@"likes"] objectForKey:@"data"] count];
                                  
                                NSLog(@"test1");
                                NSLog(@"%ld", (long)self.likescount);
                                
                              }else{
                                  ct = 0;
                                  NSLog(@"test2");
                                  NSLog(@"%d", 0);
                              }

                          }];
    
}

- (IBAction)find:(id)sender {
    [Konashi find];
}

- (void)ready
{
    // Drive LED
    [Konashi pwmMode:LED2 mode:KONASHI_PWM_ENABLE_LED_MODE];
    
    //Blink LED (interval: 0.5s)
    [Konashi pwmPeriod:LED2 period:1000000];   // 1.0s
    [Konashi pwmDuty:LED2 duty:500000];       // 0.5s
    [Konashi pwmMode:LED2 mode:ENABLE];
}

@end
