//
//  Drag2RefeshView.m
//  DragToRefreshDemo
//
//  Created by ShiTeng on 15/5/6.
//  Copyright (c) 2015年 ShiTeng. All rights reserved.
//

#import "NXDrag2RefreshView.h"
#import "NXCommonUtils.h"

@interface NXDrag2RefeshView()
@property(nonatomic) Drag2RefreshViewType refeshViewType;
@property(nonatomic, strong) UILabel* hintLabel;
@property(nonatomic, strong) UILabel* timeLabel;

@property(nonatomic, strong) UIImageView* arrowImageView;
@property(nonatomic, strong) UIImageView* shadowView;
@property(nonatomic, strong) UIActivityIndicatorView* indicatorView;
@end

@implementation NXDrag2RefeshView
-(instancetype) initWithFrame:(CGRect)frame refeshViewType:(Drag2RefreshViewType) viewType{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.94 green:0.94 blue:0.96 alpha:1.0];
        _refeshViewType = viewType;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        // infromation text area
        _hintLabel = [[UILabel alloc] init];
        _hintLabel.autoresizingMask =
        UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        _hintLabel.font = [UIFont boldSystemFontOfSize:13.f];
        _hintLabel.textColor        = [UIColor lightGrayColor];
        _hintLabel.backgroundColor  = [UIColor clearColor];
        _hintLabel.textAlignment    = NSTextAlignmentCenter;
        [self addSubview:_hintLabel];
        
        // updata time text area
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.autoresizingMask =
        UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        _timeLabel.font = [UIFont systemFontOfSize:10.f];
        _timeLabel.textColor = [UIColor lightGrayColor];
        _timeLabel.backgroundColor = [UIColor clearColor];
        _timeLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_timeLabel];
        
        // The arrow image view
        _arrowImageView = [[UIImageView alloc] init];
        _arrowImageView.contentMode = UIViewContentModeScaleAspectFill;
        _arrowImageView.image = [UIImage imageNamed:@"arrow_up"];
        _arrowImageView.layer.transform = CATransform3DMakeRotation(M_PI, 0.0f, 0.0f, 1.0f);
        [self addSubview:_arrowImageView];
        
        // indicate view
        _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _indicatorView.backgroundColor = [UIColor clearColor];
        _indicatorView.hidesWhenStopped = YES;
        [self addSubview:_indicatorView];
        
        _shadowView = [[UIImageView alloc] init];
        [self addSubview:_shadowView];
        
        // according to the type of Refreshview, layout the subview
        switch (viewType) {
            case kHeaderRefeshView:{
                _hintLabel.frame = CGRectMake(0, (frame.size.height - 50.f) / 3,
                                             frame.size.width, 30.f);
                _timeLabel.frame = CGRectMake(0, (frame.size.height - 50.f) / 3 + 30.f,
                                             frame.size.width, 20.f);
                [self relayoutInterface];
            }
                break;
            case kFooterRefeshView:{
                _shadowView.image = [UIImage imageNamed:@"shadow_up"];
                
                _hintLabel.frame = CGRectMake(0, (frame.size.height - 30.f) / 2,
                                              frame.size.width, 30.f);
                _timeLabel.frame = CGRectZero;
                [self relayoutInterface];

            }
                break;
            default:
                break;
        }
        
        
        
        
        // default state is drag to refresh
        self.state = kDrag2RefreshViewStateDragToRefresh;
    }
    
    return self;
}

#pragma mark - the setter of property state
-(void)setState:(Drag2RefreshViewState)newState
{
    
        _state = newState;  // Do not use self.state, otherwise there will be call himself, infinite loop
        switch (newState) {
            case kDrag2RefreshViewStateDragToRefresh:{
                switch (self.refeshViewType) {
                    case kFooterRefeshView:{
                        self.hintLabel.text = @"drag up to load more";
                    }
                        break;
                    case kHeaderRefeshView:{
                        self.hintLabel.text = @"drag down to refresh";
                    }
                        break;
                    default:
                        break;
                }
                [self switchImage:NO];
                [self updateRefreshTimeLabel];
                
            }
                break;
            case kDrag2RefreshViewStateLooseToRefresh:{
                switch (self.refeshViewType) {
                    case kHeaderRefeshView:{
                        self.hintLabel.text = @"Release";
                    }
                        break;
                    default:
                        break;
                }
                [self switchImage:NO];
                
            }
                break;
            case kDrag2RefreshViewStateRefreshing:{
               self.hintLabel.text = @"Loading";
               [self switchImage:YES];
                // if footview, we adjust ui according to hintlabel content,
                // so if hintlabel change, we need to relayoutInterface
                if (self.refeshViewType == kFooterRefeshView) {
                    [self relayoutInterface];
                }
            }
                break;
            default:
                break;
        }

    
}

#pragma mark - load image and arrow image operation
-(void) switchImage:(BOOL) isShowIndicatorView
{
    if (isShowIndicatorView) {
        [self.indicatorView startAnimating];
        self.arrowImageView.hidden = YES;
    }else{
        [self.indicatorView stopAnimating];
        self.arrowImageView.hidden = NO;
    }
        
}

- (void)flipImageAnimated:(BOOL)animated
{
    static BOOL isFlipped = NO;
    NSTimeInterval duration = animated ? .18 : 0.0;
    [UIView animateWithDuration:duration
                     animations:^()
     {
         self.arrowImageView.layer.transform = isFlipped ?
         CATransform3DMakeRotation(M_PI, 0.0f, 0.0f, 1.0f) :
         CATransform3DMakeRotation(M_PI * 2, 0.0f, 0.0f, 1.0f);
     }];
    
    isFlipped = !isFlipped;
}

#pragma mark - update updatetime labe
-(void) updateRefreshTimeLabel
{
    NSDate* newDate = [NSDate date];
    NSDateFormatter* dateFormater = [[NSDateFormatter alloc] init];
    [dateFormater setDateStyle:NSDateFormatterShortStyle];
    [dateFormater setTimeStyle:NSDateFormatterShortStyle];
    self.timeLabel.text = [NSString stringWithFormat:@"%s%@", "Update at ", [dateFormater stringFromDate:newDate]];
    
    [self relayoutInterface];
}

-(void) relayoutInterface
{

    if (self.refeshViewType == kHeaderRefeshView) {
        // calculate the size of timelabel content
        UIFont *font = self.timeLabel.font;         // The same as the timeLabel font
        CGSize size = self.timeLabel.frame.size;    // The same as the tiemLabel size
        NSDictionary * dic = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName,nil];
        size =[self.timeLabel.text boundingRectWithSize:size options:NSStringDrawingUsesLineFragmentOrigin |NSStringDrawingUsesFontLeading attributes:dic context:nil].size;

        // the arrowImageView and indicatorView is next to timelabel
        CGFloat boundWidth = 0.0f;
        if ([NXCommonUtils isiPad]) {
            boundWidth = 340;
        }else
        {
            boundWidth = self.bounds.size.width;
        }
        self.arrowImageView.frame = CGRectMake(boundWidth/2 - size.width/2 - 40, (self.bounds.size.height - 65.f) / 2,
                                           23.f, 60.f);
        self.indicatorView.frame = CGRectMake(boundWidth/2 - size.width/2 - 40, (self.bounds.size.height - 65.f) / 2,
                                          23.f, 60.f);
        
    }else if(self.refeshViewType == kFooterRefeshView){
        _arrowImageView.frame = CGRectZero;
        
        // calculate the size of hintlabel content
        UIFont *font = self.hintLabel.font;         // The same as the timeLabel font
        CGSize size = self.hintLabel.frame.size;    // The same as the tiemLabel size
        NSDictionary * dic = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName,nil];
        size =[self.hintLabel.text boundingRectWithSize:size options:NSStringDrawingUsesLineFragmentOrigin |NSStringDrawingUsesFontLeading attributes:dic context:nil].size;
        
        self.indicatorView.frame = CGRectMake(self.bounds.size.width/2 - size.width/2 - 40, (self.bounds.size.height - 65.f) / 2,
                                          23.f, 60.f);
        
        self.shadowView.frame = CGRectMake(0, 0, self.bounds.size.width, 5);
    }
    
}

@end
