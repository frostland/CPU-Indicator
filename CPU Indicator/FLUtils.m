/*
 * FLUtils.m
 * CPU Indicator
 *
 * Created by François LAMBOLEY on 12/21/11.
 * Copyright (c) 2011 Frost Land. All rights reserved.
 */

#import "FLUtils.h"

#include <mach/mach.h> /* To get CPU Usage */

#import "FLConstants.h"

void FLRefreshKnownCPUUsage(void) {
	natural_t cpuCount;
	processor_info_array_t infoArray;
	mach_msg_type_number_t infoCount;
	
	/* The total ticks are integer, but we will use them in division,
	 * so we need floats. We do not need ticks numbers as integers */
	CGFloat totalTicks, totalTicksNoIdle;
	static CGFloat *totalTicksPerCPU, *totalTicksNoIdlePerCPU; /* Allocated once and for all in the function to avoid to many uses of malloc */
	static CGFloat previousTotalTicks = 0, previousTotalTicksNoIdle = 0;
	static CGFloat *previousTotalTicksPerCPU = NULL, *previousTotalTicksNoIdlePerCPU = NULL;
	kern_return_t error = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &cpuCount, &infoArray, &infoCount);
	if (error) {
		mach_error("*** Error in host_processor_info:", error);
		return;
	}
	
	if (cpuCount != nCPUs || CPUUsages == NULL ||
		 totalTicksPerCPU == NULL || totalTicksNoIdlePerCPU == NULL ||
		 previousTotalTicksPerCPU == NULL || previousTotalTicksNoIdlePerCPU == NULL) {
		if (CPUUsages != NULL) free(CPUUsages);
		CPUUsages = calloc(cpuCount, sizeof(CGFloat));
		if (CPUUsages == NULL) {
			NSLog(@"*** Error: cannot allocate %ld bytes", cpuCount * sizeof(CGFloat));
			return;
		}
		if (totalTicksPerCPU != NULL) free(totalTicksPerCPU);
		totalTicksPerCPU = calloc(cpuCount, sizeof(CGFloat));
		if (totalTicksPerCPU == NULL) {
			NSLog(@"*** Error: cannot allocate %ld bytes", cpuCount * sizeof(CGFloat));
			return;
		}
		if (totalTicksNoIdlePerCPU != NULL) free(totalTicksNoIdlePerCPU);
		totalTicksNoIdlePerCPU = calloc(cpuCount, sizeof(CGFloat));
		if (totalTicksNoIdlePerCPU == NULL) {
			NSLog(@"*** Error: cannot allocate %ld bytes", cpuCount * sizeof(CGFloat));
			return;
		}
		if (previousTotalTicksPerCPU != NULL) free(previousTotalTicksPerCPU);
		previousTotalTicksPerCPU = calloc(cpuCount, sizeof(CGFloat));
		if (previousTotalTicksPerCPU == NULL) {
			NSLog(@"*** Error: cannot allocate %ld bytes", cpuCount * sizeof(CGFloat));
			return;
		}
		if (previousTotalTicksNoIdlePerCPU != NULL) free(previousTotalTicksNoIdlePerCPU);
		previousTotalTicksNoIdlePerCPU = calloc(cpuCount, sizeof(CGFloat));
		if (previousTotalTicksNoIdlePerCPU == NULL) {
			NSLog(@"*** Error: cannot allocate %ld bytes", cpuCount * sizeof(CGFloat));
			return;
		}
	}
	nCPUs = cpuCount;
	
	totalTicks = totalTicksNoIdle = 0.;
	processor_cpu_load_info_data_t *cpuLoadInfo = (processor_cpu_load_info_data_t *)infoArray;
	for (natural_t cpu = 0; cpu < cpuCount; ++cpu) {
		totalTicksPerCPU[cpu] = totalTicksNoIdlePerCPU[cpu] = 0;
		for (NSUInteger state = 0; state < CPU_STATE_MAX; ++state) {
			/* Ticks states are, in that order: "user", "system", "idle", "nice" */
			unsigned long ticks = cpuLoadInfo[cpu].cpu_ticks[state];
			totalTicks += ticks;
			totalTicksPerCPU[cpu] += ticks;
			if (state != 2) {
				totalTicksNoIdle += ticks;
				totalTicksNoIdlePerCPU[cpu] += ticks;
			}
		}
		CPUUsages[cpu] = (totalTicksNoIdlePerCPU[cpu] - previousTotalTicksNoIdlePerCPU[cpu])/(totalTicksPerCPU[cpu] - previousTotalTicksPerCPU[cpu]);
		previousTotalTicksPerCPU[cpu] = totalTicksPerCPU[cpu];
		previousTotalTicksNoIdlePerCPU[cpu] = totalTicksNoIdlePerCPU[cpu];
	}
	
	globalCPUUsage = (totalTicksNoIdle - previousTotalTicksNoIdle)/(totalTicks - previousTotalTicks);
	//	NSLog(@"Current CPU Usage: %g", knownCPUUsage);
	
	previousTotalTicks = totalTicks;
	previousTotalTicksNoIdle = totalTicksNoIdle;
	vm_deallocate(mach_task_self(), (vm_address_t)infoArray, infoCount);
	
	[[NSNotificationCenter defaultCenter] postNotificationName:FL_NTF_CPU_USAGE_UPDATED object:nil];
}
