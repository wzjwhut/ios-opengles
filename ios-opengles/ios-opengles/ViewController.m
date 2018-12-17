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


@interface ViewController ()
{
    GLrgb* rgbGL;
    GLyuv* yuvGL;
}
@property (weak, nonatomic) IBOutlet GLKView *rgbView;
@property (weak, nonatomic) IBOutlet GLKView *yuvView;

- (IBAction)freshRGB:(id)sender;
- (IBAction)freshYUV:(id)sender;


@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initGLView];
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
    glClearColor(0.0, 0.0, 1.0, 1);
    glClear( GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);

    /* 画一帧rgb数据 */
    if( view == _rgbView){
        if(rgbGL == nil){
            rgbGL = [[GLrgb alloc] initWith:rect];
        }
        int r = rand()%256;
        int g = rand()%256;
        int b = rand()%256;
        int w = 128;
        int h = 128;
        uint8_t* data = malloc(w*h*3);
        for(int i=0; i<w*h*3; i+=3){
            data[i] = r;
            data[i+1] = g;
            data[i+2] = b;
        }
        [rgbGL drawRGB:data width:w height:h];
        free(data);
    }else if(view == _yuvView){
        if(yuvGL == nil){
            yuvGL = [[GLyuv alloc] initWith:rect];
        }
        const int w = 128;
        const int h = 128;
        const int totalSize = w*h*3/2;
        uint8_t* data = (uint8_t*)malloc(totalSize);
        memset(data, rand()%200 + 16, totalSize);
        [yuvGL drawYUV:data width:w height:h];
        free(data);
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
