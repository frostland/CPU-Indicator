/*
 * FLSkinManager.m
 * CPU Indicator
 *
 * Created by François LAMBOLEY on 3/8/11.
 * Copyright 2011 Frost Land. All rights reserved.
 */

#import "FLSkinManager.h"

#import "FLConstants.h"
#import "FLDefaultPaths.h"

@interface FLSkinManager (Private)

@property(readonly) BOOL saveSkinList;

@end

@implementation FLSkinManager

- (instancetype)init
{
	if ((self = [super init]) != nil) {
		fm = [NSFileManager defaultManager];
		
		BOOL exists;
		NSString *pathToSkins = [fm pathForListSkinsDescr:&exists];
		if (exists) skinsDescriptions = [[NSUnarchiver unarchiveObjectWithFile:pathToSkins] retain];
		else        skinsDescriptions = [[NSMutableArray alloc] initWithObjects:[NSNull null], nil];
		
		cachedSkins = [[NSMutableArray alloc] initWithCapacity:[skinsDescriptions count]];
		for (NSUInteger i = 0; i < [skinsDescriptions count]; ++i)
			[cachedSkins addObject:[NSNull null]];
		
		[self selectSkinAtIndex:[self selectedSkinIndex]];
	}
	
	return self;
}

- (NSUInteger)nSkins
{
	return [skinsDescriptions count];
}

- (FLSkin *)skinAtIndex:(NSUInteger)idx
{
	if (![cachedSkins[idx] isEqual:[NSNull null]])
		return cachedSkins[idx];
	
	FLSkin *skin;
	if (idx == 0) skin = [[FLSkin new] autorelease];
	else          skin = [NSUnarchiver unarchiveObjectWithFile:[fm fullSkinPathFrom:skinsDescriptions[idx]]];
	if (skin != nil) cachedSkins[idx] = skin;
	
	return skin;
}

- (NSUInteger)selectedSkinIndex
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:FL_UDK_SELECTED_SKIN];
}

- (void)selectSkinAtIndex:(NSUInteger)idx
{
	if (idx == (NSUInteger)-1) idx = 0;
	if (idx >= [skinsDescriptions count]) idx = [skinsDescriptions count]-1;
	
	[[NSUserDefaults standardUserDefaults] setInteger:idx forKey:FL_UDK_SELECTED_SKIN];
}

- (BOOL)canRemoveSkinAtIndex:(NSUInteger)idx
{
	return (idx > 0) && (idx < [skinsDescriptions count]);
}

- (BOOL)installSkinAtPath:(NSString *)path useIt:(BOOL)use
{
	if ([NSUnarchiver unarchiveObjectWithFile:path] == nil)
		return NO;
	
	NSString *newPath = [fm pathForNewSkin];
	if (!newPath || ![fm copyItemAtPath:path toPath:newPath error:NULL])
		return NO;
	
	[skinsDescriptions addObject:[newPath lastPathComponent]];
	[cachedSkins addObject:[NSNull null]];
	
	[self saveSkinList];
	
	if (use) [self selectSkinAtIndex:[skinsDescriptions count] - 1];
	
	return YES;
}

- (BOOL)removeSkinAtIndex:(NSInteger)idx
{
	if (![self canRemoveSkinAtIndex:idx]) return NO;
	
	if (![fm removeItemAtPath:[fm fullSkinPathFrom:skinsDescriptions[idx]] error:NULL])
		return NO;
	
	[skinsDescriptions removeObjectAtIndex:idx];
	[cachedSkins removeObjectAtIndex:idx];
	
	if (idx < [self selectedSkinIndex]) [self selectSkinAtIndex:[self selectedSkinIndex] - 1];
	else                                [self selectSkinAtIndex:[self selectedSkinIndex]];
	
	[self saveSkinList];
	
	return YES;
}

- (void)dealloc
{
	[cachedSkins release];
	[skinsDescriptions release];
	
	[super dealloc];
}

@end

@implementation FLSkinManager (Private)

- (BOOL)saveSkinList
{
	return [NSArchiver archiveRootObject:skinsDescriptions toFile:[fm pathForListSkinsDescr:NULL]];
}

@end
