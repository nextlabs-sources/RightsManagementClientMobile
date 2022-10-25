//
//  NXOverlayTextInfo.m
//  nxrmc
//
//  Created by nextlabs on 8/19/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import "NXOverlayTextInfo.h"
#import "NXLoginUser.h"
#import "HexColor.h"


static NSString const *kFontName        = @"FontName";
static NSString const *kFontSize        = @"FontSize";
static NSString const *kRotation        = @"Rotation";
static NSString const *kText            = @"Text";
static NSString const *kTextColor       = @"TextColor";
static NSString const *kTransparency    = @"Transparency";

static NSString  *const kUser       = @"$(User)";
static NSString  *const KDate       = @"$(Date)";
static NSString  *const kTime       = @"$(Time)";
static NSString  *const KDocument   = @"$(Document)";

static const NSDictionary *rotationTable;
static const NSDictionary *colorTable;
static const NSDictionary *fontTable;

@interface NXOverlayTextInfo()

@property (nonatomic, copy) NSString *fontName;
@property (nonatomic, strong) NSNumber *fontSize;

@end

@implementation NXOverlayTextInfo

- (instancetype)init {
    if (self = [super init]) {
        [self initializeConstantVariables];
        _text = [[NSString alloc] initWithFormat:@"%@", @"nextlabs.com overlay test"];
        _font = [UIFont systemFontOfSize:15];
        _transparency = [NSNumber numberWithFloat:30];
        _textColor = [UIColor redColor];
        _isclockwiserotation = NO;
        _fontName = _font.fontName;
        _fontSize = [NSNumber numberWithFloat:_font.pointSize];
    }
    return self;
}

- (instancetype)initWithObligation:(NXHeartbeatAPIResponse *)heartbeatResponse {
    if (self = [super init]) {
        [self initializeConstantVariables];
        if (heartbeatResponse != nil) {
            [self fetchProperty:heartbeatResponse];
        } else {
            _text = [[NSString alloc] initWithFormat:@"%@", @"nextlabs.com overlay test"];
            _font = [UIFont systemFontOfSize:15];
            _transparency = [NSNumber numberWithFloat:30];
            _textColor = [UIColor redColor];
            _isclockwiserotation = NO;
            _fontName = _font.fontName;
            _fontSize = [NSNumber numberWithFloat:_font.pointSize];
        }
    }
    return self;
}

- (void) fetchProperty:(NXHeartbeatAPIResponse *)obligation {
    _isclockwiserotation = [[rotationTable objectForKey:obligation.rotation] boolValue];
    _fontName = [fontTable objectForKey:obligation.fontName];
    _fontSize = obligation.fontSize;
    _transparency = obligation.transparentRatio;
    _textColor = [UIColor colorWithHexString:obligation.fontColor];
    
    _font = [UIFont fontWithName:_fontName size:[_fontSize floatValue]];
    _text = [self parserTextStr:obligation.text];
}

- (NSString *)parserTextStr:(NSString *)text {

    NSString *user = [NXLoginUser sharedInstance].profile.email;

    NSString *temp = [text stringByReplacingOccurrencesOfString:[NSString stringWithString:kUser] withString:user];
    
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    NSString *time = [dateFormatter stringFromDate:date];
    
    [dateFormatter setDateFormat:@"yyyy-MM-dd "];
    NSString *datestr = [dateFormatter stringFromDate:date];
    temp = [temp stringByReplacingOccurrencesOfString:[NSString stringWithString:kTime] withString:time];
    temp = [temp stringByReplacingOccurrencesOfString:[NSString stringWithString:KDate] withString:datestr];
    
    temp = [temp stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
    return [temp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];  //delete space char and ‘\n’ in the head and tail.
}

- (void)initializeConstantVariables {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        rotationTable = [NSDictionary dictionaryWithObjectsAndKeys:
                         [NSNumber numberWithBool:YES],  @"Clockwise",
                         [NSNumber numberWithBool:NO],   @"Anticlockwise", nil];
        fontTable = [NSDictionary dictionaryWithObjectsAndKeys: @"Helvetica",   @"Sitka Text", nil];  //default font name is Helvetica.
    });
}

@end