//
//  ViewController.m
//  ios-opengles
//
//  Created by wzj on 2018/12/16.
//  Copyright © 2018年 wzj. All rights reserved.
//

#import "ViewController.h"
#import <pthread.h>
#import "GLrgb.h"
#import "GLyuv.h"
#import "ImageUtil.h"


@interface ViewController ()
{
    GLrgb* rgbGL;
    GLyuv* yuvGL;
    uint8_t* yuv;
    uint8_t* rgb;
    int width;
    int height;
}
@property (weak, nonatomic) IBOutlet GLKView *rgbView;
@property (weak, nonatomic) IBOutlet GLKView *yuvView;

- (IBAction)freshRGB:(id)sender;
- (IBAction)freshYUV:(id)sender;


@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImage* image = [UIImage imageNamed:@"1.jpg"];
    width =  image.size.width;
    height = image.size.height;
    rgb = [ImageUtil rgbArray:image];
    yuv = [ImageUtil yuvArray:rgb width:width height:height];
    [self initGLView];
}

- (void)dealloc
{
    
}

-(void) initGLView
{
    /** init gl view */
    _rgbView.contentScaleFactor = 1.0;
    _rgbView.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:_rgbView.context];
    _rgbView.delegate = self;
    _rgbView.enableSetNeedsDisplay  = YES;
    
    _yuvView.contentScaleFactor = 1.0;
    _yuvView.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:_yuvView.context];
    _yuvView.delegate = self;
    _yuvView.enableSetNeedsDisplay  = YES;
    
}

/** GLKView执行绘图的接口 */
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.0, 0.0, 0.0, 1);
    glClear( GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
    
    /* 画一帧rgb数据 */
    if( view == _rgbView){
        if(rgbGL == nil){
            rgbGL = [[GLrgb alloc] initWith:rect];
        }
        [rgbGL drawRGB:rgb width:width height:height];
    }else if(view == _yuvView){
        if(yuvGL == nil){
            yuvGL = [[GLyuv alloc] initWith:rect];
        }
        [yuvGL drawYUV:yuv width:width height:height];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)freshRGB:(id)sender {
    [_rgbView display];
}

- (IBAction)freshYUV:(id)sender {
    [_yuvView display];
}
@end
