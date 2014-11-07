//
//  ViewController.m
//  HanCamera
//
//  Created by 韩畅 on 14/11/6.
//  Copyright (c) 2014年 韩畅. All rights reserved.
//

#import <Foundation/NSDictionary.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *snapButton;
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
    
    // 预览 session
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:[self session]];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    CALayer *rootLayer = [[self previewLayer] layer];
    [rootLayer setMasksToBounds:YES];
    [previewLayer setFrame:CGRectMake(-70, 0, rootLayer.bounds.size.height, rootLayer.bounds.size.height)];
    [rootLayer insertSublayer:previewLayer atIndex:0];
    
    // output
    if (self.imageOutput == nil) {
        self.imageOutput = [[AVCaptureStillImageOutput alloc] init];
    }
    
    NSDictionary *setting = [[NSDictionary alloc]initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
    
    [self.imageOutput setOutputSettings:setting];
    
    [session addOutput:self.imageOutput];
    
    [[self session] startRunning];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)snapeImageButton:(id)sender {
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
    
    NSLog(@"about to request a capture from: %@", self.imageOutput);
    
    
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

@end
