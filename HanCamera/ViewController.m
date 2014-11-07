//
//  ViewController.m
//  HanCamera
//
//  Created by 韩畅 on 14/11/6.
//  Copyright (c) 2014年 韩畅. All rights reserved.
//

#import <Foundation/NSDictionary.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *flashlightButton;
@property (weak, nonatomic) IBOutlet UIView *previewLayer;
@end

@implementation ViewController

@synthesize session;
@synthesize imageOutput;

- (void)viewDidLoad {
    [super viewDidLoad];

    // session 连接到 captureDevive
    if ([self session] == nil) {
        [self setSession:[[AVCaptureSession alloc] init]];
    }
    
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError	*error;
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    
    if ([[self session] canAddInput:deviceInput])
        [[self session] addInput:deviceInput];
    
    
    // 设置闪光灯按钮
    NSString *buttonTitle = [self getTitleByFlashlightMode:captureDevice.flashMode];
    [[self flashlightButton] setTitle:buttonTitle forState:normal];
    
    // 预览 session
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:[self session]];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    CALayer *rootLayer = [[self previewLayer] layer];
    [rootLayer setMasksToBounds:YES];
    [previewLayer setFrame:CGRectMake(-70, 0, rootLayer.bounds.size.height, rootLayer.bounds.size.height)];
    [rootLayer insertSublayer:previewLayer atIndex:0];
    
    // output
    if ([self imageOutput] == nil) {
        [self setImageOutput:[[AVCaptureStillImageOutput alloc] init]];
    }
    
    NSDictionary *setting = [[NSDictionary alloc]initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [[self imageOutput] setOutputSettings:setting];
    
    [session addOutput:self.imageOutput];
    
    [[self session] startRunning];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)clickSnapeImageButton:(id)sender {
    
    // 闪光弹！
    UIView *flashView = [[UIView alloc] initWithFrame:[[self previewLayer] frame]];
    [flashView setBackgroundColor:[UIColor whiteColor]];
    [[[self previewLayer] window] addSubview:flashView];
    
    [UIView animateWithDuration:.4f
                     animations:^{
                         [flashView setAlpha:0]; // why 0.f ?
                     }
                     completion:^(BOOL finished){
                         [flashView removeFromSuperview];
                     }];
    
    // 获取相机的连接
    AVCaptureConnection *connection = nil;
    for (AVCaptureConnection *tempConnection in self.imageOutput.connections) {
        for (AVCaptureInputPort *port in [tempConnection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                connection = tempConnection;
                break;
            }
        }
        if (connection) {
            break;
        }
    }
    
    // 保存图片
    [self.imageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage *image = [[UIImage alloc]initWithData:imageData];
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        ALAssetsLibraryWriteImageCompletionBlock completionBlock = ^(NSURL *assetURL, NSError *error) {
            if (error) {
                // TODO
            }
        };
        [library writeImageToSavedPhotosAlbum:[image CGImage]
                                  orientation:(ALAssetOrientation)[image imageOrientation]
                              completionBlock:completionBlock];
    }];
}

- (IBAction)clickCameraRollButton:(id)sender {
    
    if ([UIImagePickerController isSourceTypeAvailable:
         UIImagePickerControllerSourceTypeSavedPhotosAlbum])
    {
        UIImagePickerController *imagePicker =
        [[UIImagePickerController alloc] init];
        imagePicker.delegate = self;
        imagePicker.sourceType =
        UIImagePickerControllerSourceTypePhotoLibrary;
        imagePicker.mediaTypes = [NSArray arrayWithObjects:
                                  (NSString *) kUTTypeImage,
                                  nil];
        imagePicker.allowsEditing = NO;
        [self presentViewController:imagePicker animated:YES completion:^(void){}];
        //[imagePicker release];
        // newMedia = NO;
    }
}

- (AVCaptureDeviceInput *)getVideoInput {
    
    for (AVCaptureDeviceInput *input in self.session.inputs) {
        if ([input.device hasMediaType:AVMediaTypeVideo]) {
            return input;
        }
    }
    
    return nil;
}


- (IBAction)switchCameraButton:(id)sender {
    
    AVCaptureDeviceInput *currentInput = [self getVideoInput];
    
    if (currentInput) {
        AVCaptureDevicePosition newPosition = AVCaptureDevicePositionFront;
        if (currentInput.device.position == AVCaptureDevicePositionFront) {
            newPosition = AVCaptureDevicePositionBack;
        }
        
        AVCaptureDevice *newDevice = nil;
        NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for (AVCaptureDevice *device in devices)
        {
            if ([device position] == newPosition)
            {
                newDevice = device;
                break;
            }
        }
        
        NSError	*error;
        AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:newDevice error:&error];
        
        [self.session beginConfiguration];
        [self.session removeInput:currentInput];
        [self.session addInput:newInput];
        [self.session commitConfiguration];
        
        // font camera 时隐藏闪光灯按钮
        if (newDevice.position == AVCaptureDevicePositionFront) {
            [self.flashlightButton setHidden:YES];
        } else {
            [self.flashlightButton setHidden:NO];
        }
    }
}

- (NSString *) getTitleByFlashlightMode:(AVCaptureFlashMode) flashMode {
    NSString *buttonTitle;
    if (flashMode == AVCaptureFlashModeAuto) {
        buttonTitle = @"Auto";
    } else if (flashMode == AVCaptureFlashModeOff) {
        buttonTitle = @"Off";
    } else {
        buttonTitle = @"On";
    }
    
    return buttonTitle;
}

- (IBAction)clickFlashlightButton:(id)sender {
    AVCaptureDeviceInput *input = [self getVideoInput];
    
    [input.device lockForConfiguration:nil];
    
    if (input.device.flashMode == AVCaptureFlashModeAuto) {
        [input.device setFlashMode:AVCaptureFlashModeOff];
    } else if (input.device.flashMode == AVCaptureFlashModeOff) {
        [input.device setFlashMode:AVCaptureFlashModeOn];
    } else {
        [input.device setFlashMode:AVCaptureFlashModeAuto];
    }
    
    [input.device unlockForConfiguration];
    
    NSString *buttonTitle = [self getTitleByFlashlightMode:input.device.flashMode];
    [[self flashlightButton] setTitle:buttonTitle forState:normal];
    
}

@end
