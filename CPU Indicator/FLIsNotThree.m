/*
 * FLIsNotThree.m
 * CPU Indicator
 *
 * Created by François LAMBOLEY on 12/20/11.
 * Copyright (c) 2011 Frost Land. All rights reserved.
 */

#import "FLIsNotThree.h"

@implementation FLIsNotThree

+ (Class)transformedValueClass
{
	return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation
{
	return NO;
}

- (id)transformedValue:(id)value
{
	return [NSNumber numberWithBool:([value integerValue] != 3)];
}

@end
