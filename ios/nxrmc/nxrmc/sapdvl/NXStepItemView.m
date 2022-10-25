//
//  NXStepItemView.m
//  scrollviewtest
//
//  Created by nextlabs on 9/16/15.
//  Copyright (c) 2015 zhuimengfuyun. All rights reserved.
//

#import "NXStepItemView.h"


@interface NXStepItemView()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (nonatomic) BOOL selected;

@end

@implementation NXStepItemView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

+ (instancetype) initWithImage:(UIImage *) image {
    NXStepItemView *view = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self.class) owner:self options:nil] lastObject];
    view.imageView.image = image;
    view.selected = NO;
    return view;
}

- (IBAction)stepItemClicked:(UIButton *)sender {
    self.selected = YES;
    if (_selected) {
        [self setBackgroundColor:[self selectedColor]];
    } else {
        [self setBackgroundColor:[self defaultColor]];
    }
}

- (UIColor *) selectedColor {
    return [UIColor blueColor];
}

- (UIColor *) defaultColor {
    return [UIColor whiteColor];
}

- (void) setSelected:(BOOL)selected {
    _selected = selected;
    if (_selected) {
        [self setBackgroundColor:[self selectedColor]];
    } else {
        [self setBackgroundColor:[self defaultColor]];
    }
    if (_selected) {
        if (_deletage && [_deletage respondsToSelector:@selector(nxStepItemDidClicked:state:)]) {
            [_deletage nxStepItemDidClicked:self state:_selected];
        }
    }
}

@end
