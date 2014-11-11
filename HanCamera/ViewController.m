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
#import "EditViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *proportionButton;
@property (weak, nonatomic) IBOutlet UIButton *switchCameraButton;
@property (weak, nonatomic) IBOutlet UIButton *snapButton;
@property (weak, nonatomic) IBOutlet UIButton *flashlightButton;
@property (weak, nonatomic) IBOutlet UIView *preview;
@end

@implementation ViewController

@synthesize session;
@synthesize imageOutput;
@synthesize cameraMode;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setCameraMode:hcCameraMode9to16];
    
    [[[self preview] layer] setBackgroundColor:[[UIColor blackColor]CGColor]];
    
    // session 连接到 captureDevive
    [self setSession:[[AVCaptureSession alloc] init]];

    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:nil];
    
    if ([[self session] canAddInput:deviceInput])
        [[self session] addInput:deviceInput];
    
    // 初始化界面按键
    [self initViewsOfButtons:captureDevice.flashMode];
    
    // 预览 session
    [self loadPreviewLayer];
    
    // output
    [self setImageOutput:[[AVCaptureStillImageOutput alloc] init]];
    
    NSDictionary *setting = [[NSDictionary alloc]initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [[self imageOutput] setOutputSettings:setting];
    
    [session addOutput:self.imageOutput];
    
    [[self session] startRunning];
}

// 预览 session
- (void) loadPreviewLayer {
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:[self session]];
    
    CGFloat proportion = [self getPoportionByHcCameraMode:[self cameraMode]];
    [previewLayer setFrame:[self getFrameByProportion:proportion]];
    
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    [[[self preview] layer] setMasksToBounds:YES];
    [[[self preview] layer] insertSublayer:previewLayer atIndex:0];
}

// 根据比例裁剪图片
- (UIImage*) cropImageWithImage:(UIImage*) image proportion:(CGFloat)proportion  {
    
    CGSize newSize = [self sizeWithSize:image.size poportion:proportion];
    
    CGRect rect = CGRectMake(image.scale * (image.size.height / 2 - newSize.height / 2),
                             image.scale * (image.size.width / 2 - newSize.width / 2),
                             image.scale * newSize.height,
                             image.scale * newSize.width);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, rect);
    UIImage *newImage = [UIImage imageWithCGImage:imageRef scale:image.scale orientation:image.imageOrientation];
    
    CGImageRelease(imageRef);
    
    return newImage;
}

// 按照 size 缩放图片
- (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize;
{
    // Create a graphics image context
    UIGraphicsBeginImageContext(newSize);
    
    // Tell the old image to draw in this new context, with the desired
    // new size
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    
    // Get the new image from the context
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // End the context
    UIGraphicsEndImageContext();
    
    // Return the new image.
    return newImage;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// 拍照按钮
- (IBAction)clickSnapImageButton:(id)sender {
    
    // 闪光效果
    UIView *flashView = [[UIView alloc] initWithFrame:[[self preview] frame]];
    [flashView setBackgroundColor:[UIColor blackColor]];
    [[[self preview] window] addSubview:flashView];
    
    [UIView animateWithDuration:.4f
                     animations:^{
                         [flashView setAlpha:0.f];
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
        // 切割图片
        CGFloat proportion = [self getPoportionByHcCameraMode:[self cameraMode]];
        image = [self cropImageWithImage:image proportion:proportion];
        
        UIImageWriteToSavedPhotosAlbum(image, self, nil, nil); // TODO 异常处理
    }];
}

// 图片库按钮
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
    }
}

// 图库选中了照片
- (void)imagePickerController: (UIImagePickerController *)picker
didFinishPickingMediaWithInfo: (NSDictionary *)info
{
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
    [picker dismissViewControllerAnimated:YES completion:^(void){}];
    
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        UIImage *image = [info
                          objectForKey:UIImagePickerControllerOriginalImage];
        
        UIImage *newImage = [EditViewController effectImage:image byFilterName:@"None"];
        
        EditViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"theEditView"];
        
        [viewController setOriginalImage:image];
        [viewController setImage:newImage];
        
        
        [self presentViewController:viewController animated:YES completion:^{
        }];
    }
}

// 保存图片出现 error
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error
  contextInfo:(void *)contextInfo
{
    if (error != NULL)
    {
        NSLog(@"error - didFinishSavingWithError");
        
    }
}

// 获取相机 input
- (AVCaptureDeviceInput *)getVideoInput {
    
    for (AVCaptureDeviceInput *input in self.session.inputs) {
        if ([input.device hasMediaType:AVMediaTypeVideo]) {
            return input;
        }
    }
    
    return nil;
}

// 前后摄像头按钮
- (IBAction)clickSwitchCameraButton:(id)sender {
    
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

// 闪光灯按钮
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
    
    UIImage *buttonImage = [self getImageByFlashlightMode:input.device.flashMode];
    buttonImage = [self imageWithImage:buttonImage scaledToSize:CGRectMake(0,0,40,40).size];
    [[self flashlightButton] setImage:buttonImage forState:UIControlStateNormal];
    
}

// 画幅比例按钮
- (IBAction)clickProportionButton:(id)sender {
    
    hcCameraMode newCameraMode;
    if ([self cameraMode] == hcCameraMode3to4) {
        newCameraMode = hcCameraMode9to16;
    } else {
        newCameraMode = [self cameraMode] + 1;
    }
    [self setCameraMode:newCameraMode];
    
    [[self proportionButton] setTitle:[self getTitleByCameraMode:[self cameraMode]] forState:UIControlStateNormal];
    
    AVCaptureVideoPreviewLayer *subPreviewLayer = [[[[self preview] layer] sublayers] objectAtIndex:0];
    [subPreviewLayer removeFromSuperlayer];
    
    CGFloat proportion = [self getPoportionByHcCameraMode:[self cameraMode]];
    CGRect rect = [self getFrameByProportion:proportion];
    [subPreviewLayer setFrame:rect];
    [[[self preview] layer] insertSublayer:subPreviewLayer atIndex:0];
}

// 初始化按键
- (void) initViewsOfButtons:(AVCaptureFlashMode) flashMode {
    
    // 闪光灯按钮
    NSString *buttonTitle = [self getTitleByFlashlightMode:flashMode];
    [[self flashlightButton] setTitle:buttonTitle forState:normal];
    
    UIImage *buttonImage = [self getImageByFlashlightMode:flashMode];
    buttonImage = [self imageWithImage:buttonImage scaledToSize:CGRectMake(0,0,40,40).size];
    [[self flashlightButton] setImage:buttonImage forState:UIControlStateNormal];
    
    // 前后摄像头切换按钮
    [[self switchCameraButton] setTitle:@"" forState:UIControlStateNormal];
    buttonImage = [UIImage imageNamed:@"switchCamera.png"];
    buttonImage = [self imageWithImage:buttonImage scaledToSize:CGRectMake(0,0,40,40).size];
    [[self switchCameraButton] setImage:buttonImage forState:UIControlStateNormal];
    
    // 拍照按钮
    [[self snapButton] setTitle:@"" forState:UIControlStateNormal];
    buttonImage = [UIImage imageNamed:@"snap.png"];
    buttonImage = [self imageWithImage:buttonImage scaledToSize:CGRectMake(0,0,50,50).size];
    [[self snapButton] setImage:buttonImage forState:UIControlStateNormal];
    
    // 画布比例按钮
    [[self proportionButton] setTitle:[self getTitleByCameraMode:[self cameraMode]] forState:UIControlStateNormal];
}

- (NSString *) getTitleByCameraMode:(hcCameraMode) theCameraMode{
    NSString *buttonTitle;
    if (theCameraMode == hcCameraMode9to16) {
        buttonTitle = @"16:9";
    } else if (theCameraMode == hcCameraMode1to1) {
        buttonTitle = @"1:1";
    } else { // hcCameraMode3to4
        buttonTitle = @"4:3";
    }
    
    return buttonTitle;
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

- (UIImage *) getImageByFlashlightMode:(AVCaptureFlashMode) flashMode {
    
    NSString *imageName;
    if (flashMode == AVCaptureFlashModeAuto) {
        imageName = @"flashlightAuto.png";
    } else if (flashMode == AVCaptureFlashModeOff) {
        imageName = @"flashlightOff.png";
    } else { // AVCaptureFlashModeOn
        imageName = @"flashlightOn.png";
    }
    
    UIImage *buttonImage = [UIImage imageNamed:imageName];
    
    return buttonImage;
}

// 根据比例获得缩小后的 size
- (CGSize) sizeWithSize:(CGSize) size poportion:(CGFloat) proportion{
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    CGFloat screenProportion = screenSize.width / screenSize.height;
    
    CGSize newSize;
    if (proportion > screenProportion) {
        newSize.width  = size.width;
        newSize.height = size.width / proportion;
    } else {
        newSize.height = size.height;
        newSize.width  = size.height * proportion;
    }
    
    return newSize;
}

// 根据 cameraMode 获取比例
- (CGFloat) getPoportionByHcCameraMode:(hcCameraMode) theCameraMode {
    
    if (theCameraMode == hcCameraMode1to1) {
        return 1.0 / 1.0;
    } else if (theCameraMode == hcCameraMode3to4) {
        return 3.0 / 4.0;
    } else {// hcCameraMode9to16
        return 9.0 / 16.0;
    }
}

// 根据比例获取 frame
- (CGRect) getFrameByProportion:(CGFloat) proportion {
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    
    CGSize newSize = [self sizeWithSize:screenSize poportion:proportion];
    
    return CGRectMake(screenSize.width / 2 - newSize.width / 2,
                      screenSize.height / 2 - newSize.height / 2,
                      newSize.width,
                      newSize.height);
}


@end
