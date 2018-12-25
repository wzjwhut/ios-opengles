//
//  ImageUtil.h
//  ios-opengles
//
//  Created by wzj on 2018/12/25.
//  Copyright © 2018年 wzj. All rights reserved.
//

#ifndef ImageUtil_h
#define ImageUtil_h

#import <UIKit/UIImage.h>

@interface ImageUtil : NSObject
+ (unsigned char *)rgbArray: (UIImage *) uiimage;
+ (unsigned char*)yuvArray: (uint8_t*) rgb width:(int) w height:(int) h;
@end
@implementation ImageUtil
+ (unsigned char *)rgbArray: (UIImage *) uiimage
{
    CGImageRef image = [uiimage CGImage];
    CGSize size = uiimage.size;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    int pixelCount = size.width * size.height;
    uint8_t* rgba = malloc(pixelCount * 4);
    CGContextRef context = CGBitmapContextCreate(rgba, size.width, size.height, 8, 4 * size.width, colorSpace, kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(context, CGRectMake(0, 0, size.width, size.height), image);
    CGContextRelease(context);
    uint8_t* rgb = malloc(pixelCount * 3);
    int m = 0;
    int n = 0;
    for(int i=0; i<pixelCount; i++){
        rgb[m++] = rgba[n++];
        rgb[m++] = rgba[n++];
        rgb[m++] = rgba[n++];
        n++;
    }
    free(rgba);
    return rgb;
}
+ (unsigned char*)yuvArray: (uint8_t*) rgb width:(int) w height:(int) h{
    int pixelCount = w*h;
    uint8_t* yuv888 = malloc(pixelCount*3);
    uint8_t R,G,B,Y,U,V;
    int n = 0;
    int yuv888bytes = pixelCount*3;
    for(int i=0; i<yuv888bytes; ){
        R = rgb[i++];
        G = rgb[i++];
        B = rgb[i++];
        
        Y =  (int) ((0.257 * R) + (0.504 * G) + (0.098 * B) + 16);
        U =  (int) (-(0.148 * R) - (0.291 * G) + (0.439 * B) + 128);
        V =  (int) ((0.439 * R) - (0.368 * G) - (0.071 * B) + 128);
        yuv888[n++] = Y;
        yuv888[n++] = U;
        yuv888[n++] = V;
    }
    uint8_t* yuv420 = malloc(pixelCount*3/2);
    uint8_t* y = yuv420;
    uint8_t* ptr;
    n = 0;
    for(int i=0; i<yuv888bytes; i+=3){
        y[n++] = yuv888[i];
    }
    
    n=0;
    uint8_t* u = yuv420 + pixelCount;
    ptr = yuv888;
    int lineszieBytes = w*3;
    for(int i=0; i<h; i+=2){
        for(int j=1; j<lineszieBytes; j+=6){
            u[n++] = (ptr[j] + ptr[j+3] + ptr[j + lineszieBytes] + ptr[j + lineszieBytes + 3])/4;
        }
        ptr += lineszieBytes*2;
    }

    n=0;
    uint8_t* v = yuv420 + pixelCount + w*h/4;
    ptr = yuv888;
    for(int i=0; i<h; i+=2){
        for(int j=2; j<lineszieBytes; j+=6){
            v[n++] = (ptr[j] + ptr[j+3] + ptr[j + lineszieBytes] + ptr[j + lineszieBytes + 3])/4;
        }
        ptr += lineszieBytes*2;
    }
    free(yuv888);
    return yuv420;
}

@end


#endif /* ImageUtil_h */
