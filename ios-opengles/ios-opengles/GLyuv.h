//
//  OpenglesRender.h
//  ios-opengles
//
//  Created by wzj on 2018/12/16.
//  Copyright © 2018年 wzj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface GLyuv : NSObject
-(instancetype) initWith: (CGRect) rect;
-(void) dealloc;
-(void) drawYUV: (uint8_t*) yuv width: (int) width height: (int) height;
@end
