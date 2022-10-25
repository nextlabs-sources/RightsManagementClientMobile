//
//  CheckBoxView.m
//  AdhocTest
//
//  Created by nextlabs on 6/27/16.
//  Copyright © 2016 zhuimengfuyun. All rights reserved.
//

#import "CheckBoxView.h"

#import "CheckboxCollectionViewCell.h"
#import "CheckBoxViewFlowLayout.h"

#define kItemCountPerRow 3
#define KCellIdentifier @"CellIdentifier"

@interface CheckBoxView ()<UICollectionViewDataSource, UICollectionViewDelegate>

@property(nonatomic, weak) UICollectionView *collectionView;

//@property(nonatomic) BOOL canChecked;

@end

@implementation CheckBoxView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self commitInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commitInit];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceDidRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    return self;
}

- (void)reloadData {
    [self.collectionView reloadData];
}

-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (CGSize)contentSize {
    return self.collectionView.contentSize;
}

- (void)commitInit {
    CheckBoxViewFlowLayout *layout = [[CheckBoxViewFlowLayout alloc] init];
    
    layout.minimumInteritemSpacing = 1;
    layout.minimumLineSpacing = 0;
    layout.maximumInteritemSpacing = 30;
    layout.headerReferenceSize = CGSizeMake(200, 30);
    layout.footerReferenceSize = CGSizeMake(200, 1);
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
    [self addSubview:collectionView];
    
    collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:collectionView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:collectionView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:collectionView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:collectionView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0]];
    
    self.collectionView = collectionView;
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.backgroundColor = [UIColor clearColor];
    
    [self.collectionView registerClass:[CheckboxCollectionViewCell class] forCellWithReuseIdentifier:KCellIdentifier];
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"section"];
}
- (void)setDataArray:(NSArray *)dataArray {
    _dataArray = dataArray;
    [self.collectionView reloadData];
}

- (void)setUserInteractionEnabled:(BOOL)userInteractionEnabled {
    [super setUserInteractionEnabled:userInteractionEnabled];
//    self.canChecked = userInteractionEnabled;
    [self.collectionView reloadData];
}

#pragma mark - UICollectionViewDataSource, UICollectionViewDelegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.dataArray.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSArray *rightsArray = self.dataArray[section];
    return rightsArray.count;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *reusableView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"section" forIndexPath:indexPath];
    [[reusableView viewWithTag:3] removeFromSuperview];
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 200, 30)];
    label.font = [UIFont fontWithName:@"Helvetica-Bold" size:15];
    label.text = self.titlesArray[indexPath.section];
    [reusableView addSubview:label];
    label.tag = 3;
    return reusableView;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CheckboxCollectionViewCell *cell = (CheckboxCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:KCellIdentifier forIndexPath:indexPath];
    NSArray *rightsArray = self.dataArray[indexPath.section];
    CheckBoxCellModel *model = rightsArray[indexPath.row];
    cell.title = model.title;
    cell.checked = model.checked;
    cell.buttonClickedBlock = ^(BOOL checked) {
        model.checked = checked;
    };
    if (indexPath.row == 0 && indexPath.section == 0) {
        cell.checked = YES;
        model.checked = YES;
        cell.userInteractionEnabled = NO;
        //this is a temp solution. when set check. the image is not changed. it may be because the userInteractionEnabled property
        [cell.button setImage:[UIImage imageNamed:@"checkbox"] forState:UIControlStateNormal];
    } else {
        cell.userInteractionEnabled = self.userInteractionEnabled;
    }
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSArray *rightsArray = self.dataArray[indexPath.section];
    CheckBoxCellModel *model = rightsArray[indexPath.row];
    CGRect rect = [model.title boundingRectWithSize:CGSizeMake(MAXFLOAT, 30)
                              options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                           attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:17]}
                              context:NULL];
    return CGSizeMake(rect.size.width + 50, 40);
}

#pragma mark - Respoinse to notification

-(void)deviceDidRotate:(NSNotification *)notification {
    [self.collectionView reloadData];
}

@end