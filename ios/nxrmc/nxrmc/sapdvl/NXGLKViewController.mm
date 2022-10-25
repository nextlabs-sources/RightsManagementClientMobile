//
//  NXGLKViewController.m
//  vdstest6
//
//  Created by nextlabs on 9/7/15.
//  Copyright (c) 2015 zhuimengfuyun. All rights reserved.
//

#import "NXGLKViewController.h"

#import "NXStepItemsScrollView.h"
#import "NSTimer+NXBlockSupport.h"
#import "DVLInclude.h"

#define NXSTEPITEMSVIEWTAG 2000

CGFloat kStepViewHeight = 50;

@interface NXDVLStepItem : NSObject

@property (nonatomic, strong) NSNumber *stepID;
@property (nonatomic, strong) NSString *stepDescription;
@property (nonatomic, strong) NSString *stepName;
@property (nonatomic, strong) UIImage *stepScreenShotImage;

@end

@implementation NXDVLStepItem

@end

@interface NXGLKViewController ()<UIGestureRecognizerDelegate, NXStepItemsScrollViewDelegate>
{
    CGPoint	ptLastPan;
    CGPoint ptLastRotate;
    float fLastZoom;
}
@property (strong) NSTimer *timer;

@property () IDVLCore *core;
@property () IDVLRenderer *renderer;
@property () IDVLScene *scene;

//@property (strong, nonatomic) NSMutableArray *stepItems;

@property (weak, nonatomic) NXStepItemsScrollView *stepsView;

@property (nonatomic) BOOL isTimerInvalidated;

@end

@implementation NXGLKViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    _stepItems = [[NSMutableArray alloc] init];
    
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    GLKView *view = (GLKView *)self.view;
    view.context = context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    [EAGLContext setCurrentContext:context];
    
    [self initGestures];
    
    _isTimerInvalidated = NO;
}

- (void)dealloc {
    [self.timer invalidate];
    self.timer = nil;
    
    self.core->DoneRenderer();
    self.core->Release();
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (bool)loadVDSFile:(NSString *)filePath {
    [[self.view viewWithTag:NXSTEPITEMSVIEWTAG] removeFromSuperview];
    
    _stepsView = [NXStepItemsScrollView stepItemsScrollView];
    [self addStepScrollView];
    
    self.core = DVLCreateCoreInstance();
    if (!self.core) {
        NSLog(@"creating DVL core error!");
        return false;
    }
    
    DVLRESULT res = self.core->Init(NULL, DVL_VERSION_MAJOR, DVL_VERSION_MINOR);
    if (DVLFAILED(res)) {
        NSLog(@"initializing DVL core error: %d", res);
    }
    
    res = self.core->InitRenderer();
    if (DVLFAILED(res)) {
        NSLog(@"initializing renderer error: %d", res);
    }
    self.renderer = self.core->GetRendererPtr();
    self.renderer->SetBackgroundColor(1.f, 1.f, 1.f, 	1.f, 1.f, 1.f);
    
    NSString *path = [NSString stringWithFormat:@"file://%@", filePath];
    
    res = self.core->LoadScene(path.UTF8String, NULL, &_scene);
    if (DVLFAILED(res)) {
        NSLog(@"failed loading scene: %d", res);
        return false;
    }
    self.renderer->AttachScene(_scene);
    
    [self initStepItems];
    if (_stepsView.stepItemCount == 0) {
        [[self.view viewWithTag:NXSTEPITEMSVIEWTAG] removeFromSuperview];
        _stepsView = nil;
    }
    self.scene->Release();
    return true;
}

- (UIImage *)snapshotImage {
    return ((GLKView *)self.view).snapshot;
}

- (void)initGestures {
    UIPanGestureRecognizer *recognizerPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    recognizerPan.minimumNumberOfTouches = 2;
    recognizerPan.maximumNumberOfTouches = 2;
    recognizerPan.delegate = self;
    [self.view addGestureRecognizer:recognizerPan];
    
    UIPanGestureRecognizer *recognizerRotate = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(rotate:)];
    recognizerRotate.minimumNumberOfTouches = 1;
    recognizerRotate.maximumNumberOfTouches = 1;
    [self.view addGestureRecognizer:recognizerRotate];
    
    UIPinchGestureRecognizer *recognizerPinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
    recognizerPinch.delegate = self;
    [self.view addGestureRecognizer:recognizerPinch];
    
    [recognizerPan requireGestureRecognizerToFail:recognizerRotate];
    [recognizerPinch requireGestureRecognizerToFail:recognizerRotate];
    
    UITapGestureRecognizer *recognizerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [self.view addGestureRecognizer:recognizerTap];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)viewDidLayoutSubviews {
    if (self.renderer) {
        self.renderer->SetDimensions(self.view.bounds.size.width * self.view.contentScaleFactor, self.view.bounds.size.height * self.view.contentScaleFactor);
    }
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    if (self.renderer) {
        self.renderer->RenderFrame();
    }
}

#pragma mark - Rendering on demand

- (void)update {
    if (self.renderer && self.renderer->ShouldRenderFrame()) {
        [self.view setNeedsDisplay];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!_isTimerInvalidated) {
        __weak NXGLKViewController *weakSelf = self;
        self.timer = [NSTimer nx_scheduledTimerWithTimeInterval:0.01 block:^{
            [weakSelf update];
        } repeats:YES];
        [self.timer fire];
        _isTimerInvalidated = YES;
    }
}

#pragma mark - NXStepItemsScrollViewDelegate

- (void)nxStepItemScrollView:(NXStepItemsScrollView *)scrollView didStepItemChanged:(NXStepItemView *)stepItemView {
    self.scene->PauseCurrentStep();
    self.scene->ActivateStep((DVLID)stepItemView.tag, true, false);
}

#pragma mark - gestures

- (void)pan:(UIPanGestureRecognizer *)rec {
    CGPoint pt = [rec translationInView:self.view];
    
    if (rec.state == UIGestureRecognizerStateBegan) {
        ptLastPan = pt;
        CGPoint pt2 = [rec locationInView:self.view];
        self.renderer->BeginGesture(pt2.x * self.view.contentScaleFactor, pt2.y * self.view.contentScaleFactor);
    }
    
    float dx = pt.x - ptLastPan.x;
    float dy = pt.y - ptLastPan.y;
    
    self.renderer->Pan(dx, dy);
    ptLastPan = pt;
    
    if (rec.state == UIGestureRecognizerStateEnded || rec.state == UIGestureRecognizerStateCancelled) {
        self.renderer->EndGesture();
    }
}

- (void)rotate:(UIPanGestureRecognizer *)rec {
    CGPoint pt = [rec locationInView:self.view];
    
    switch (rec.state) {
        case UIGestureRecognizerStateBegan:
            self.renderer->BeginGesture(pt.x * self.view.contentScaleFactor, pt.y * self.view.contentScaleFactor);
            break;
        case UIGestureRecognizerStateChanged:
            self.renderer->Rotate(pt.x - ptLastRotate.x, pt.y - ptLastRotate.y);
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            self.renderer->EndGesture();
            break;
        default:
            break; // do nothing
    }
    ptLastRotate = pt;
}

- (void)pinch:(UIPinchGestureRecognizer *)rec {
    if (rec.state == UIGestureRecognizerStateBegan) {
        fLastZoom = 1.f;
        CGPoint pt2 = [rec locationInView:self.view];
        self.renderer->BeginGesture(pt2.x * self.view.contentScaleFactor, pt2.y * self.view.contentScaleFactor);
    }
    
    if (!isnan(rec.scale) && !isinf(rec.scale)) {
        self.renderer->Zoom(rec.scale / fLastZoom);
        fLastZoom = rec.scale;
    }
    
    if (rec.state == UIGestureRecognizerStateEnded || rec.state == UIGestureRecognizerStateCancelled) {
        self.renderer->EndGesture();
    }
}

- (void)tap:(UITapGestureRecognizer *)rec {
    CGPoint pt = [rec locationInView:self.view];
    self.renderer->Tap(pt.x * self.view.contentScaleFactor, pt.y * self.view.contentScaleFactor, false);
}

#pragma mark 

- (void)addStepScrollView {
    _stepsView.translatesAutoresizingMaskIntoConstraints = NO;
    _stepsView.tag = NXSTEPITEMSVIEWTAG;
    _stepsView.delegate = self;
    
    //auto layout
    [self.view addSubview:_stepsView];
    
    [self.view addConstraint:[NSLayoutConstraint
                              constraintWithItem:_stepsView
                              attribute:NSLayoutAttributeBottom
                              relatedBy:NSLayoutRelationEqual
                              toItem:self.view
                              attribute:NSLayoutAttributeBottom
                              multiplier:1
                              constant:0]];
    
    [self.view addConstraint:[NSLayoutConstraint
                              constraintWithItem:_stepsView
                              attribute:NSLayoutAttributeTrailing
                              relatedBy:NSLayoutRelationEqual
                              toItem:self.view
                              attribute:NSLayoutAttributeTrailing
                              multiplier:1
                              constant:0]];
    [self.view addConstraint:[NSLayoutConstraint
                              constraintWithItem:_stepsView
                              attribute:NSLayoutAttributeLeading
                              relatedBy:NSLayoutRelationEqual
                              toItem:self.view
                              attribute:NSLayoutAttributeLeading
                              multiplier:1
                              constant:0]];
    [_stepsView addConstraint:[NSLayoutConstraint
                               constraintWithItem:_stepsView
                               attribute:NSLayoutAttributeHeight
                               relatedBy:NSLayoutRelationEqual
                               toItem:nil
                               attribute:NSLayoutAttributeHeight
                               multiplier:1
                               constant:kStepViewHeight]];
}

- (void)initStepItems {
    sDVLProceduresInfo procs = {};
    procs.m_uSizeOfDVLProceduresInfo = sizeof(procs);
    if (DVLSUCCEEDED(self.scene->RetrieveProcedures(&procs))) {
        for (uint32_t i = 0; i < procs.m_uProceduresCount; i++) {
            sDVLProcedure p = procs.m_pProcedures[i];
            NSLog(@"procedure #%d: name = %s, steps = %d\n", i, p.m_szName, p.m_uStepsCount);
            for (uint32_t i = 0; i < p.m_uStepsCount; i++) {
                NXDVLStepItem *item = [[NXDVLStepItem alloc] init];
                sDVLStep s = p.m_pSteps[i];
                DVLID stepId = s.m_ID;
                item.stepID = [[NSNumber alloc] initWithUnsignedLongLong:s.m_ID];
                item.stepName = [[NSString alloc] initWithCString:s.m_szName encoding:NSUTF8StringEncoding];
                item.stepDescription =[[NSString alloc] initWithCString:s.m_szDescription encoding:NSUTF8StringEncoding];
                sDVLImage img = {};
                img.m_uSizeOfDVLImage = sizeof(img);
                if (DVLSUCCEEDED(self.scene->RetrieveThumbnail(stepId, &img))) {
                    UIImage *image = [[UIImage alloc] initWithData:[NSData dataWithBytes:img.m_pImageBuffer length:img.m_uImageSize]];
                    item.stepScreenShotImage = image;
                    self.scene->ReleaseThumbnail(&img);
                }
                //                [self.stepItems addObject:item];
                [self.stepsView addStepItem:item.stepID image:item.stepScreenShotImage];
            }
        }
        self.scene->ReleaseProcedures(&procs);
    }
}

@end