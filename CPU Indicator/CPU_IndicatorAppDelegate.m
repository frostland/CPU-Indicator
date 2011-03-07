//
//  CPU_IndicatorAppDelegate.m
//  CPU Indicator
//
//  Created by François LAMBOLEY on 2/27/11.
//  Copyright 2011 Frost Land. All rights reserved.
//

#import "CPU_IndicatorAppDelegate.h"

#include <mach/mach.h>

@implementation CPU_IndicatorAppDelegate

@synthesize window, cpuIndicatorView;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[cpuIndicatorView setImages:[NSArray arrayWithObjects:[NSImage imageNamed:@"babe0.png"], [NSImage imageNamed:@"babe1.png"], [NSImage imageNamed:@"babe2.png"], [NSImage imageNamed:@"babe3.png"], [NSImage imageNamed:@"babe4.png"], nil]];
//	[cpuIndicatorView setImages:[NSArray arrayWithObjects:[NSImage imageNamed:@"green.png"], [NSImage imageNamed:@"orange.png"], [NSImage imageNamed:@"red.png"], nil]];
	[[NSTimer scheduledTimerWithTimeInterval:.5 target:self selector:@selector(refreshKnownCPUUsage:) userInfo:NULL repeats:YES] fire];
}

- (void)refreshKnownCPUUsage:(NSTimer *)t
{
	natural_t cpuCount;
	processor_info_array_t infoArray;
	mach_msg_type_number_t infoCount;
	
	/* The total ticks are integer, but we will use them in division,
	 * so we need floats. We do not need ticks numbers as integers */
	CGFloat totalTicks, totalTicksNoIdle;
	static CGFloat previousTotalTicks = 0, previousTotalTicksNoIdle = 0;
	kern_return_t error = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &cpuCount, &infoArray, &infoCount);
	if (error) {
		mach_error("host_processor_info error:", error);
		return;
	}
	
	totalTicks = totalTicksNoIdle = 0.;
	processor_cpu_load_info_data_t *cpuLoadInfo = (processor_cpu_load_info_data_t *)infoArray;
	for (natural_t cpu = 0; cpu < cpuCount; ++cpu) {
		for (NSUInteger state = 0; state < CPU_STATE_MAX; ++state) {
			/* Ticks states are, in that order: "user", "system", "idle", "nice" */
			unsigned long ticks = cpuLoadInfo[cpu].cpu_ticks[state];
			totalTicks += ticks;
			if (state != 2) totalTicksNoIdle += ticks;
		}
	}
	
	knownCPUUsage = (totalTicksNoIdle - previousTotalTicksNoIdle)/(totalTicks - previousTotalTicks);
//	NSLog(@"Current CPU Usage: %g", knownCPUUsage);
	
	previousTotalTicks = totalTicks;
	previousTotalTicksNoIdle = totalTicksNoIdle;
	vm_deallocate(mach_task_self(), (vm_address_t)infoArray, infoCount);
	
	[cpuIndicatorView setCurCPULoad:knownCPUUsage animated:YES];
}

@end
