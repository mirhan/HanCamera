//
//  EditViewController.m
//  HanCamera
//
//  Created by 韩畅 on 14/11/10.
//  Copyright (c) 2014年 韩畅. All rights reserved.
//

#import "EditViewController.h"

@interface EditViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *editImageView;
@property (weak, nonatomic) IBOutlet UIPickerView *effectPickerView;

@end

@implementation EditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.editImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.editImageView.userInteractionEnabled = YES;
    
    self.effectPickerView.delegate = (id)self;
    self.editImageView.image = self.image;
    
    // 似乎只有一部分可以在 iOS 中使用
    NSArray *array=[[NSArray alloc] initWithObjects:
                    @"None",
//                    @"CIColorCrossPolynomial",
//                    @"CIColorCube",
//                    @"CIColorCubeWithColorSpace",
//                    @"CIColorInvert",
//                    @"CIColorMap",
//                    @"CIColorMonochrome",
//                    @"CIColorPosterize",
                    @"CIFalseColor",
//                    @"CIMaskToAlpha",
//                    @"CIMaximumComponent",
//                    @"CIMinimumComponent",
                    @"CIPhotoEffectChrome",
                    @"CIPhotoEffectFade",
//                    @"CIPhotoEffectInstant", 
//                    @"CIPhotoEffectMono",
//                    @"CIPhotoEffectNoir", 
//                    @"CIPhotoEffectProcess", 
//                    @"CIPhotoEffectTonal", 
//                    @"CIPhotoEffectTransfer", 
//                    @"CISepiaTone", 
//                    @"CIVignette", 
//                    @"CIVignetteEffect",
                    nil];
    [self setPickerViewData:array];
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [[self pickerViewData] count];
}

-(UIView *)pickerView:(UIPickerView *)pickerView
          titleForRow:(NSInteger)row
         forComponent:(NSInteger)component
{
    
    return [[self pickerViewData] objectAtIndex:row];
}


// 选中 pickerview 的某行时会调用该函数。
- (void)pickerView:(UIPickerView *)thePickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSString *filterName = [[self pickerViewData]objectAtIndex:row];
    UIImage *newImage = [EditViewController effectImage:[self originalImage] byFilterName:filterName];
    
    [self setImage:newImage];
    [[self editImageView] setImage:newImage];
}

// Cancel 按钮
- (IBAction)clickCancelButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}

// Done 按钮
- (IBAction)clickDoneButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
    }];
    
    UIImageWriteToSavedPhotosAlbum([self image], self, nil, nil); // TODO 异常处理
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// 滤镜
+ (UIImage *) effectImage: (UIImage *)uIImage byFilterName:(NSString *)filterName;
{
    if ([filterName isEqualToString:@"None"]) {
        return uIImage;
    }
    
    UIImage *tempImage = [EditViewController scaleAndRotateImage:uIImage];
    
    CIContext *context = [CIContext contextWithOptions:nil];
    
    CIImage *ciImage = [[CIImage alloc] initWithImage:tempImage]; // 解决滤镜后图片方向不对的问题
    
    CIFilter *filter = [CIFilter filterWithName:filterName];
    [filter setValue:ciImage forKey:kCIInputImageKey];
    
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    
    CGRect extent = [result extent];
    
    CGImageRef cgImage = [context createCGImage:result fromRect:extent];
    UIImage *filteredImage = [[UIImage alloc] initWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
    return filteredImage;
}

// Code from: http://discussions.apple.com/thread.jspa?messageID=7949889
+ (UIImage *)scaleAndRotateImage:(UIImage *)image {
    int kMaxResolution = 640; // Or whatever
    
    CGImageRef imgRef = image.CGImage;
    
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    if (width > kMaxResolution || height > kMaxResolution) {
        CGFloat ratio = width/height;
        if (ratio > 1) {
            bounds.size.width = kMaxResolution;
            bounds.size.height = roundf(bounds.size.width / ratio);
        }
        else {
            bounds.size.height = kMaxResolution;
            bounds.size.width = roundf(bounds.size.height * ratio);
        }
    }
    
    CGFloat scaleRatio = bounds.size.width / width;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    UIImageOrientation orient = image.imageOrientation;
    switch(orient) {
            
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
            
        case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
            
        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
            
        case UIImageOrientationLeftMirrored: //EXIF = 5
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationLeft: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationRightMirrored: //EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        case UIImageOrientationRight: //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
            
    }
    
    UIGraphicsBeginImageContext(bounds.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
    
    CGContextConcatCTM(context, transform);
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageCopy;
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
