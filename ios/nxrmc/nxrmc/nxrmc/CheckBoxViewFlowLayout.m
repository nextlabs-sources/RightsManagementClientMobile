//
//  CheckBoxViewFlowLayou.m
//  nxrmc
//
//  Created by nextlabs on 8/4/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "CheckBoxViewFlowLayout.h"

@implementation CheckBoxViewFlowLayout
//
- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *answer = [super layoutAttributesForElementsInRect:rect];
    for (int i = 0; i < answer.count; ++ i) {
        UICollectionViewLayoutAttributes *currentLayoutAttributes = answer[i];
        if (currentLayoutAttributes.indexPath.row == 0 && currentLayoutAttributes.representedElementCategory == UICollectionElementCategoryCell) {
            CGRect frame = currentLayoutAttributes.frame;
            frame.origin.x = self.collectionView.contentInset.left;
            currentLayoutAttributes.frame = frame;
        }
    }
    
    return answer;
}

@end
