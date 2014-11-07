//
//  RLAppDelegate.h
//  RealLike2
//
//  Created by grasp on 2014/05/10.
//  Copyright (c) 2014年 grasp. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <FacebookSDK/FacebookSDK.h>

@class RLViewController;

@interface RLAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) RLViewController *rootViewController;

@end
