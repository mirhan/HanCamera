//
//  EditViewController.h
//  HanCamera
//
//  Created by 韩畅 on 14/11/10.
//  Copyright (c) 2014年 韩畅. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EditViewController : UIViewController
@property UIImage* originalImage;
@property UIImage* image;
@property(nonatomic,retain) NSArray *pickerViewData;
+ (UIImage *) effectImage: (UIImage *)uIImage byFilterName:(NSString *)filterName;
@end
