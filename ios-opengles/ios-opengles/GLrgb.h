//
//  GlesRGB.h
//  ios-opengles
//
//  Created by wzj on 2018/12/16.
//  Copyright © 2018年 wzj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface GLrgb : NSObject

@property int rectWidth;
@property int rectHeight;

-(instancetype) initWith: (CGRect*) __weak rect;
-(void) drawRGB: (uint8_t*) rgb_data width: (int) width height: (int) height;
@end
