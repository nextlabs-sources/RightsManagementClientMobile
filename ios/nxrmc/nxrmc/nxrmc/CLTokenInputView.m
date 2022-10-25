//
//  CLTokenInputView.m
//  CLTokenInputView
//
//  Created by Rizwan Sattar on 2/24/14.
//  Copyright (c) 2014 Cluster Labs, Inc. All rights reserved.
//

#import "CLTokenInputView.h"

#import "CLTokenView.h"
#import "NXCustomTextView.h"

static CGFloat const HSPACE = 0.0;
static CGFloat const TEXT_FIELD_HSPACE = 4.0; // Note: Same as CLTokenView.PADDING_X
static CGFloat const VSPACE = 4.0;
static CGFloat const MINIMUM_TEXTFIELD_WIDTH = 56.0;
static CGFloat const PADDING_TOP = 4.0;
static CGFloat const PADDING_BOTTOM = 4.0;
static CGFloat const PADDING_LEFT = 8;
static CGFloat const PADDING_RIGHT = 8;
static CGFloat const STANDARD_ROW_HEIGHT = 36.0;

static CGFloat const FIELD_MARGIN_X = 4.0;

@interface CLTokenInputView () <CLTokenViewDelegate, UITextViewDelegate>

@property (strong, nonatomic) CL_GENERIC_MUTABLE_ARRAY(NXInputModel *) *tokens;
@property (strong, nonatomic) CL_GENERIC_MUTABLE_ARRAY(CLTokenView *) *tokenViews;
@property (strong, nonatomic) NXCustomTextView *textView;
@property (strong, nonatomic) UILabel *fieldLabel;


@property (assign, nonatomic) CGFloat intrinsicContentHeight;
@property (assign, nonatomic) CGFloat additionalTextFieldYOffset;

@end

@implementation CLTokenInputView

- (void)commonInit
{
    self.textView = [[NXCustomTextView alloc] initWithFrame:CGRectMake(0, PADDING_TOP, self.bounds.size.width, STANDARD_ROW_HEIGHT - PADDING_BOTTOM - PADDING_TOP)];
    self.textView.font = [UIFont systemFontOfSize:16.0];
    self.textView.backgroundColor = [UIColor clearColor];
    self.textView.keyboardType = UIKeyboardTypeEmailAddress;
    self.textView.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.textView.delegate = self;
    self.additionalTextFieldYOffset = 0.0;
    
    [self addSubview:self.textView];
    

    self.tokens = [NSMutableArray arrayWithCapacity:20];
    self.tokenViews = [NSMutableArray arrayWithCapacity:20];

    self.fieldColor = [UIColor lightGrayColor];
    
    self.fieldLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    // NOTE: Explicitly not setting a font for the field label
    self.fieldLabel.textColor = self.fieldColor;
    self.fieldLabel.font = [UIFont systemFontOfSize:14];
    [self addSubview:self.fieldLabel];
    self.fieldLabel.hidden = YES;

    self.intrinsicContentHeight = 40;
    [self repositionViews];
    self.backgroundColor = [UIColor whiteColor];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, MAX(45, self.intrinsicContentHeight));
}


#pragma mark - Tint color


- (void)tintColorDidChange
{
    for (UIView *tokenView in self.tokenViews) {
        tokenView.tintColor = self.tintColor;
    }
}


#pragma mark - Adding / Removing Tokens

- (void)addToken:(NXInputModel *)token
{
    if ([self.tokens containsObject:token]) {
        return;
    }

    [self.tokens addObject:token];
    CLTokenView *tokenView = [[CLTokenView alloc] initWithToken:token font:self.textView.font];
    if ([self respondsToSelector:@selector(tintColor)]) {
        tokenView.tintColor = self.tintColor;
    }
    tokenView.delegate = self;
    CGSize intrinsicSize = tokenView.intrinsicContentSize;
    tokenView.frame = CGRectMake(0, 0, intrinsicSize.width, intrinsicSize.height);
    [self.tokenViews addObject:tokenView];
    [self addSubview:tokenView];
    self.textView.text = @"";
    if ([self.delegate respondsToSelector:@selector(tokenInputView:didAddToken:)]) {
        [self.delegate tokenInputView:self didAddToken:token];
    }

    // Clearing text programmatically doesn't call this automatically
    [self onTextViewTextDidChange:nil];

    [self updatePlaceholderTextVisibility];
    [self repositionViews];
}

- (void)removeToken:(NXInputModel *)token
{
    NSInteger index = [self.tokens indexOfObject:token];
    if (index == NSNotFound) {
        return;
    }
    [self removeTokenAtIndex:index];
}

- (void)removeTokenAtIndex:(NSInteger)index
{
    if (index == NSNotFound) {
        return;
    }
    CLTokenView *tokenView = self.tokenViews[index];
    [tokenView removeFromSuperview];
    [self.tokenViews removeObjectAtIndex:index];
    NXInputModel *removedToken = self.tokens[index];
    [self.tokens removeObjectAtIndex:index];
    if ([self.delegate respondsToSelector:@selector(tokenInputView:didRemoveToken:)]) {
        [self.delegate tokenInputView:self didRemoveToken:removedToken];
    }
    [self updatePlaceholderTextVisibility];
    [self repositionViews];
}

- (NSArray *)allTokens
{
    return [self.tokens copy];
}

- (NXInputModel *)tokenizeTextfieldText
{
    NXInputModel *token = nil;
    NSString *text = self.textView.text;
    if (text.length > 0 &&
        [self.delegate respondsToSelector:@selector(tokenInputView:tokenForText:)]) {
        token = [self.delegate tokenInputView:self tokenForText:text];
        if (token != nil) {
            [self addToken:token];
            self.textView.text = @"";
            [self onTextViewTextDidChange:nil];
            
        }
    }
    return token;
}


#pragma mark - Updating/Repositioning Views

- (void)repositionViews
{
    CGRect bounds = self.bounds;
    CGFloat rightBoundary = CGRectGetWidth(bounds) - PADDING_RIGHT;
    CGFloat firstLineRightBoundary = rightBoundary;

    CGFloat curX = PADDING_LEFT;
    CGFloat curY = PADDING_TOP;
    CGFloat totalHeight = STANDARD_ROW_HEIGHT;
    BOOL isOnFirstLine = YES;

    // Position field view (if set)
    if (self.fieldView) {
        CGRect fieldViewRect = self.fieldView.frame;
        fieldViewRect.origin.x = curX + FIELD_MARGIN_X;
        fieldViewRect.origin.y = curY + ((STANDARD_ROW_HEIGHT - CGRectGetHeight(fieldViewRect))/2.0);
        self.fieldView.frame = fieldViewRect;

        curX = CGRectGetMaxX(fieldViewRect) + FIELD_MARGIN_X;
    }

    // Position field label (if field name is set)
    if (!self.fieldLabel.hidden) {
        CGSize labelSize = self.fieldLabel.intrinsicContentSize;
        CGRect fieldLabelRect = CGRectZero;
        fieldLabelRect.size = labelSize;
        fieldLabelRect.origin.x = curX + FIELD_MARGIN_X;
        fieldLabelRect.origin.y = curY + ((STANDARD_ROW_HEIGHT-CGRectGetHeight(fieldLabelRect))/2.0);
        self.fieldLabel.frame = fieldLabelRect;
        
        curX = CGRectGetMaxX(fieldLabelRect) + FIELD_MARGIN_X;
    }

    // Position accessory view (if set)
    if (self.accessoryView) {
        CGRect accessoryRect = self.accessoryView.frame;
        accessoryRect.origin.x = CGRectGetWidth(bounds) - PADDING_RIGHT - CGRectGetWidth(accessoryRect);
        accessoryRect.origin.y = curY + ((STANDARD_ROW_HEIGHT-CGRectGetHeight(accessoryRect))/2.0);
        self.accessoryView.frame = accessoryRect;

        firstLineRightBoundary = CGRectGetMinX(accessoryRect) - HSPACE;
    }

    // Position token views
    CGRect tokenRect = CGRectNull;
    for (CLTokenView *tokenView in self.tokenViews) {
        tokenRect = tokenView.frame;
        
        CGFloat tokenBoundary = isOnFirstLine ? firstLineRightBoundary : rightBoundary;
        if (curX + CGRectGetWidth(tokenRect) > tokenBoundary) {
            // Need a new line
            curX = PADDING_LEFT;
            curY += STANDARD_ROW_HEIGHT + VSPACE;
            totalHeight += STANDARD_ROW_HEIGHT;
            isOnFirstLine = NO;
        }
        if (!isOnFirstLine) {
            CGSize sizeName = [tokenView.displayText boundingRectWithSize:CGSizeMake(MAXFLOAT, 0.0) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:tokenView.font} context:nil].size;
            if (sizeName.width > (tokenBoundary - curX)) {
                tokenRect.size.width = tokenBoundary - curX;
            }
        }
        
        tokenRect.origin.x = curX;
        tokenRect.origin.y = curY + ((STANDARD_ROW_HEIGHT - CGRectGetHeight(tokenRect))/2.0);
        tokenView.frame = tokenRect;

        curX = CGRectGetMaxX(tokenRect) + HSPACE;
    }

    // Always indent textfield by a little bit
    curX += TEXT_FIELD_HSPACE;
    CGFloat textBoundary = isOnFirstLine ? firstLineRightBoundary : rightBoundary;
    
    CGFloat availableWidthForTextField = textBoundary - curX;
    CGSize size =[self.textView.text sizeWithAttributes:@{NSFontAttributeName:self.textView.font}];
    if (availableWidthForTextField < MINIMUM_TEXTFIELD_WIDTH || (size.width + 15 > availableWidthForTextField)) {
        isOnFirstLine = NO;
        // If in the future we add more UI elements below the tokens,
        // isOnFirstLine will be useful, and this calculation is important.
        // So leaving it set here, and marking the warning to ignore it
#pragma unused(isOnFirstLine)
        curX = PADDING_LEFT + TEXT_FIELD_HSPACE;
        curY += STANDARD_ROW_HEIGHT+VSPACE;
        totalHeight += STANDARD_ROW_HEIGHT;
        // Adjust the width
        availableWidthForTextField = rightBoundary - curX;
    }

    CGRect textFieldRect = self.textView.frame;
    textFieldRect.origin.x = curX;
    textFieldRect.origin.y = curY + self.additionalTextFieldYOffset;
    textFieldRect.size.width = availableWidthForTextField;
    textFieldRect.size.height = self.textView.contentSize.height > STANDARD_ROW_HEIGHT ? self.textView.contentSize.height: STANDARD_ROW_HEIGHT;
    self.textView.frame = textFieldRect;
    CGFloat oldContentHeight = self.intrinsicContentHeight;
    self.intrinsicContentHeight = MAX(totalHeight, CGRectGetMaxY(textFieldRect) + PADDING_BOTTOM);
    [self invalidateIntrinsicContentSize];

    if (oldContentHeight != self.intrinsicContentHeight) {
        if ([self.delegate respondsToSelector:@selector(tokenInputView:didChangeHeightTo:)]) {
            [self.delegate tokenInputView:self didChangeHeightTo:self.intrinsicContentSize.height];
        }
    }
    [self setNeedsDisplay];
}

- (void)updatePlaceholderTextVisibility
{
    if (self.tokens.count > 0) {
        self.textView.placeholder = nil;
    } else {
        self.textView.placeholder = self.placeholderText;
    }
}


- (void)layoutSubviews
{
    [self repositionViews];
    [super layoutSubviews];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    self.textView.placeholder = self.placeholderText;
    if ([self.delegate respondsToSelector:@selector(tokenInputViewDidBeginEditing:)]) {
        [self.delegate tokenInputViewDidBeginEditing:self];
    }
    self.tokenViews.lastObject.hideUnselectedComma = NO;
    [self unselectAllTokenViewsAnimated:YES];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if ([self.delegate respondsToSelector:@selector(tokenInputViewDidEndEditing:)]) {
        [self.delegate tokenInputViewDidEndEditing:self];
    }
    self.tokenViews.lastObject.hideUnselectedComma = YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    //enter
    NSString *newstr = [textView.text stringByReplacingCharactersInRange:range withString:text];
    [self onTextViewTextDidChange:newstr];
    [self repositionViews];
    if ([text isEqualToString:@"\n"]) {
        if ([textView.text stringByReplacingOccurrencesOfString:@" " withString:@""].length) {
            NXInputModel *token = [[NXInputModel alloc] initWithDisplayText:textView.text context:textView.text];
            [self addToken:token];
            return NO;
        }
        [textView resignFirstResponder];
        return NO;
    }
    //backplace
    if (textView.text.length == 0 && [text isEqualToString:@""]) {
        if (textView.text.length == 0) {
            CLTokenView *tokenView = self.tokenViews.lastObject;
            if (tokenView) {
                [self selectTokenView:tokenView animated:YES];
            }
        }
        return NO;
    }
    
    if ([textView.text stringByReplacingOccurrencesOfString:@" " withString:@""].length
        && ([text isEqualToString:@" "] ||
            [text isEqualToString:@";"])) {
        NXInputModel *token = [[NXInputModel alloc] initWithDisplayText:textView.text context:textView.text];
        [self addToken:token];
        return NO;
    }
    
    if (text.length > 0 && [self.tokenizationCharacters member:text]) {
        [self tokenizeTextfieldText];
        // Never allow the change if it matches at token
        return NO;
    }
    return YES;
}

#pragma mark - Text Field Changes

- (void)onTextViewTextDidChange:(NSString *)newstring {
    if ([self.delegate respondsToSelector:@selector(tokenInputView:didChangeText:)]) {
        [self.delegate tokenInputView:self didChangeText:newstring];
    }
}


#pragma mark - Text Field Customization

- (void)setKeyboardType:(UIKeyboardType)keyboardType
{
    _keyboardType = keyboardType;
    self.textView.keyboardType = _keyboardType;
}

- (void)setAutocapitalizationType:(UITextAutocapitalizationType)autocapitalizationType
{
    _autocapitalizationType = autocapitalizationType;
    self.textView.autocapitalizationType = _autocapitalizationType;
}

- (void)setAutocorrectionType:(UITextAutocorrectionType)autocorrectionType
{
    _autocorrectionType = autocorrectionType;
    self.textView.autocorrectionType = _autocorrectionType;
}

- (void)setKeyboardAppearance:(UIKeyboardAppearance)keyboardAppearance
{
    _keyboardAppearance = keyboardAppearance;
    self.textView.keyboardAppearance = _keyboardAppearance;
}


#pragma mark - Measurements (text field offset, etc.)

- (CGFloat)textFieldDisplayOffset
{
    // Essentially the textfield's y with PADDING_TOP
    return CGRectGetMinY(self.textView.frame) - PADDING_TOP;
}


#pragma mark - Textfield text


- (NSString *)text
{
    return self.textView.text;
}


#pragma mark - CLTokenViewDelegate

- (void)tokenViewDidRequestDelete:(CLTokenView *)tokenView replaceWithText:(NSString *)replacementText
{
    // First, refocus the text field
    [self.textView becomeFirstResponder];
    if (replacementText.length > 0) {
        self.textView.text = replacementText;
    }
    // Then remove the view from our data
    NSInteger index = [self.tokenViews indexOfObject:tokenView];
    if (index == NSNotFound) {
        return;
    }
    [self removeTokenAtIndex:index];
}

- (void)tokenViewDidRequestSelection:(CLTokenView *)tokenView
{
    [self selectTokenView:tokenView animated:YES];
}


#pragma mark - Token selection

- (void)selectTokenView:(CLTokenView *)tokenView animated:(BOOL)animated
{
    [tokenView setSelected:YES animated:animated];
    for (CLTokenView *otherTokenView in self.tokenViews) {
        if (otherTokenView != tokenView) {
            [otherTokenView setSelected:NO animated:animated];
        }
    }
}

- (void)unselectAllTokenViewsAnimated:(BOOL)animated
{
    for (CLTokenView *tokenView in self.tokenViews) {
        [tokenView setSelected:NO animated:animated];
    }
}


#pragma mark - Editing

- (BOOL)isEditing
{
    return [self.textView isFirstResponder];
}


- (void)beginEditing
{
    [self.textView becomeFirstResponder];
    [self unselectAllTokenViewsAnimated:NO];
}


- (void)endEditing
{
    [self.textView resignFirstResponder];
    if ([self.textView.text stringByReplacingOccurrencesOfString:@" " withString:@""].length) {
        NXInputModel *token = [[NXInputModel alloc] initWithDisplayText:self.textView.text context:self.textView.text];
        [self addToken:token];
    }
}


#pragma mark - (Optional Views)

- (void)setFieldName:(NSString *)fieldName
{
    if (_fieldName == fieldName) {
        return;
    }
    NSString *oldFieldName = _fieldName;
    _fieldName = fieldName;

    self.fieldLabel.text = _fieldName;
    [self.fieldLabel invalidateIntrinsicContentSize];
    BOOL showField = (_fieldName.length > 0);
    self.fieldLabel.hidden = !showField;
    if (showField && !self.fieldLabel.superview) {
        [self addSubview:self.fieldLabel];
    } else if (!showField && self.fieldLabel.superview) {
        [self.fieldLabel removeFromSuperview];
    }

    if (oldFieldName == nil || ![oldFieldName isEqualToString:fieldName]) {
        [self repositionViews];
    }
}

- (void)setFieldColor:(UIColor *)fieldColor {
    _fieldColor = fieldColor;
    self.fieldLabel.textColor = _fieldColor;
}

- (void)setFieldView:(UIView *)fieldView
{
    if (_fieldView == fieldView) {
        return;
    }
    [_fieldView removeFromSuperview];
    _fieldView = fieldView;
    if (_fieldView != nil) {
        [self addSubview:_fieldView];
    }
    [self repositionViews];
}

- (void)setPlaceholderText:(NSString *)placeholderText
{
    if (_placeholderText == placeholderText) {
        return;
    }
    _placeholderText = placeholderText;
    [self updatePlaceholderTextVisibility];
}

- (void)setAccessoryView:(UIView *)accessoryView
{
    if (_accessoryView == accessoryView) {
        return;
    }
    [_accessoryView removeFromSuperview];
    _accessoryView = accessoryView;

    if (_accessoryView != nil) {
        [self addSubview:_accessoryView];
    }
    [self repositionViews];
}


#pragma mark - Drawing

- (void)setDrawBottomBorder:(BOOL)drawBottomBorder
{
    if (_drawBottomBorder == drawBottomBorder) {
        return;
    }
    _drawBottomBorder = drawBottomBorder;
    [self setNeedsDisplay];
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    if (self.drawBottomBorder) {

        CGContextRef context = UIGraphicsGetCurrentContext();
        CGRect bounds = self.bounds;
        CGContextSetStrokeColorWithColor(context, [UIColor lightGrayColor].CGColor);
        CGContextSetLineWidth(context, 0.5);

        CGContextMoveToPoint(context, 0, bounds.size.height);
        CGContextAddLineToPoint(context, CGRectGetWidth(bounds), bounds.size.height);
        CGContextStrokePath(context);
    }
}

@end
