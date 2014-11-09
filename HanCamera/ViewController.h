//
//  ViewController.h
//  HanCamera
//
//  Created by 韩畅 on 14/11/6.
//  Copyright (c) 2014年 韩畅. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef enum : NSUInteger {
    hcCameraModeFullScreen,
    hcCameraMode1to1,
    hcCameraMode3to4,
} hcCameraMode;

@interface ViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic,retain) AVCaptureSession *session;
@property AVCaptureStillImageOutput *imageOutput;
@property AVCaptureVideoPreviewLayer *previewSubLayer;
@property hcCameraMode cameraMode;

#pragma mark Actions
- (IBAction)clickSnapeImageButton:(id)sender;
- (IBAction)clickCameraRollButton:(id)sender;
- (IBAction)switchCameraButton:(id)sender;
- (IBAction)clickFlashlightButton:(id)sender;
- (IBAction)clickProportionButton:(id)sender;

@end

