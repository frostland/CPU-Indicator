/*
 * FLGlobals.c
 * CPU Indicator
 *
 * Created by François LAMBOLEY on 12/20/11.
 * Copyright (c) 2011 Frost Land. All rights reserved.
 */

#include <ApplicationServices/ApplicationServices.h>

natural_t nCPUs = 0;
CGFloat globalCPUUsage = 0.;
CGFloat *CPUUsages = NULL;
