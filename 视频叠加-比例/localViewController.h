//
//  localViewController.h
//  视频叠加-比例
//
//  Created by cc on 2020/1/22.
//  Copyright © 2020 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    composeVideos_1And1_portrait,
    composeVideos_1And1_landscape,
    composeVideos_16And9_portrait,
    composeVideos_16And9_landscape,
    composeVideos_9And16_portrait,
    composeVideos_9And16_landscape,
    
}composeVideosType;

NS_ASSUME_NONNULL_BEGIN

@interface localViewController : UIViewController

@property (nonatomic,assign) composeVideosType type;

@end

NS_ASSUME_NONNULL_END
