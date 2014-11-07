//
//  ViewController.h
//  HanCamera
//
//  Created by 韩畅 on 14/11/6.
//  Copyright (c) 2014年 韩畅. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic,retain) AVCaptureSession *session;
@property AVCaptureStillImageOutput *imageOutput;

#pragma mark Actions
- (IBAction)snapeImageButton:(id)sender;
- (IBAction)cameraRollButton:(id)sender;
- (IBAction)switchCameraButton:(id)sender;
- (IBAction)clickFlashlightButton:(id)sender;

@end

