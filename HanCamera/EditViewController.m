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
    
    CIContext *context = [CIContext contextWithOptions:nil];
    
    CIImage *ciImage = [[CIImage alloc] initWithImage:uIImage];
    
    CIFilter *filter = [CIFilter filterWithName:filterName];
    [filter setValue:ciImage forKey:kCIInputImageKey];
    
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    
    CGRect extent = [result extent];
    
    CGImageRef cgImage = [context createCGImage:result fromRect:extent];
    UIImage *filteredImage = [[UIImage alloc] initWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
    return filteredImage;
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
