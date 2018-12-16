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


@interface ViewController ()
{
    //camera interface
    AVCaptureSession *captureSession;
    AVCaptureVideoPreviewLayer *previewLayer;
    AVCaptureConnection* captureConnection;
    
    //hardware encoder
    dispatch_queue_t aQueue;
    CMFormatDescriptionRef  format;
    int width;
    int height;
    BOOL gotSPSPPS;
    NSString* error;
    BOOL skipFlag;
    BOOL stopped;
}

@property (weak, nonatomic) IBOutlet GLKView *glView;
@property (weak, nonatomic) IBOutlet UIView *cameraView;

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self initGLView];
    
    /** 模拟器上会初化失败 */
    [self initCamera];
}

-(void) initGLView
{
    /** init gl view */
    _glView.contentScaleFactor = 1.0;
    _glView.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:_glView.context];
    _glView.delegate = self;
    _glView.enableSetNeedsDisplay  = YES;
}

/** GLKView执行绘图的接口 */
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.0, 0.0, 1.0, 1);
    glClear( GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
    

    int w = rect.size.width;
    int h = rect.size.height;
    if(w == 0 || h == 0){
        return;
    }
    
    GLrgb* rgb = [[GLrgb alloc] initWith:&rect];
    uint8_t* data = malloc(100*100*3);
    memset(data, 255, 100*100*3);
    [rgb drawRGB:data width:100 height:100];
}

- (BOOL) initCamera{
    NSError *deviceError;
    
    AVCaptureDevice *cameraDevice = [self cameraWithPosition:AVCaptureDevicePositionFront];
    if(cameraDevice == nil){
        cameraDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    
    AVCaptureDeviceInput *inputDevice = [AVCaptureDeviceInput deviceInputWithDevice:cameraDevice error:&deviceError];
    if(inputDevice == nil){
        NSLog(@"init input camera Device failed");
        return false;
    }
    
    
    // make output device
    
    AVCaptureVideoDataOutput *outputDevice = [[AVCaptureVideoDataOutput alloc] init];
    
    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    
    NSNumber* val = [NSNumber
                     numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange];
    NSDictionary* videoSettings =
    [NSDictionary dictionaryWithObject:val forKey:key];
    outputDevice.videoSettings = videoSettings;
    
    [outputDevice setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    captureSession = [[AVCaptureSession alloc] init];
    [captureSession addInput:inputDevice];
    [captureSession addOutput:outputDevice];
    
    // begin configuration for the AVCaptureSession
    [captureSession beginConfiguration];
    
    // picture resolution
    [captureSession setSessionPreset:[NSString stringWithString:AVCaptureSessionPreset640x480]];
    
    captureConnection = [outputDevice connectionWithMediaType:AVMediaTypeVideo];
    captureConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    
    NSNotificationCenter* notify = [NSNotificationCenter defaultCenter];
    
    [notify addObserver:self
               selector:@selector(statusBarOrientationDidChange:)
                   name:@"StatusBarOrientationDidChange"
                 object:nil];
    
    
    [captureSession commitConfiguration];
    
    // make preview layer and add so that camera's view is displayed on screen
    
    previewLayer = [AVCaptureVideoPreviewLayer    layerWithSession:captureSession];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    
    CALayer *rootLayer = [_cameraView layer];
    [rootLayer setMasksToBounds:YES];
    [previewLayer setFrame:[rootLayer bounds]];
    [rootLayer addSublayer:previewLayer];
    return true;
}

- (AVCaptureDevice *)cameraWithPosition : (AVCaptureDevicePosition) position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices )
        if ( device.position == position )
            return device;
    
    return nil ;
}

- (void)statusBarOrientationDidChange:(NSNotification*)notification {
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
