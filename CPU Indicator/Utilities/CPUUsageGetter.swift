/*
 * CPUUsageGetter.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 1/10/16.
 * Copyright © 2016 Frost Land. All rights reserved.
 */

import Cocoa



class CPUUsageGetter {
	
	/* lazy; only instanciated when needed (but never de-instanciated). */
	static var sharedCPUUsageGetter: CPUUsageGetter = {
		CPUUsageGetter(refreshInterval: 1.5)
	}()
	
	private var timer: NSTimer?
	
	private let observers = NSHashTable.weakObjectsHashTable()
	
	init(refreshInterval: NSTimeInterval) {
		timer = nil
		if refreshInterval >= 0 {
			timer = NSTimer.scheduledTimerWithTimeInterval(refreshInterval, target: self, selector: Selector("refreshKnownUsage:"), userInfo: nil, repeats: true)
			timer?.fire()
		}
	}
	
	deinit {
		timer?.invalidate()
		timer = nil
	}
	
	func addObserverForKnownUsageModification(observer: AnyObject) {
		observers.addObject(observer)
	}
	
	func removeObserverForKnownUsageModification(observer: AnyObject) {
		observers.removeObject(observer)
	}
	
	func refreshKnownUsage() {
		refreshKnownUsage(nil)
	}
	
	private(set) var cpuCount = 1
	private(set) var cpuUsages = [0.0]
	private(set) var globalCPUUsage = 0.0
	
	/* The total ticks are integer, but we will use them in division, so we
	 * need floats. We do not need ticks numbers as integers. */
	private var previousTotalTicks = 0.0, previousTotalTicksNoIdle = 0.0
	
	private var totalTicksPerCPU = [0.0], totalTicksNoIdlePerCPU = [0.0]
	private var previousTotalTicksPerCPU = [0.0], previousTotalTicksNoIdlePerCPU = [0.0]
	
	@objc
	private func refreshKnownUsage(timer: NSTimer?) {
		var newCPUCountNatural = natural_t()
		var infoArray = processor_info_array_t()
		var infoCount = mach_msg_type_number_t()
		
		let error = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &newCPUCountNatural, &infoArray, &infoCount)
		guard error == 0 else {
			mach_error("*** Error in host_processor_info:", error)
			return
		}
		
		let newCPUCount = Int(newCPUCountNatural)
		
		if newCPUCount != cpuCount {
			cpuCount = newCPUCount
			cpuUsages                      = [Double](count: newCPUCount, repeatedValue: 0.0)
			totalTicksPerCPU               = [Double](count: newCPUCount, repeatedValue: 0.0)
			totalTicksNoIdlePerCPU         = [Double](count: newCPUCount, repeatedValue: 0.0)
			previousTotalTicksPerCPU       = [Double](count: newCPUCount, repeatedValue: 0.0)
			previousTotalTicksNoIdlePerCPU = [Double](count: newCPUCount, repeatedValue: 0.0)
		}
		
		var totalTicks = 0.0, totalTicksNoIdle = 0.0
		let cpuLoadInfo = unsafeBitCast(infoArray, UnsafeMutablePointer<processor_cpu_load_info_data_t>.self)
		for var cpu = 0; cpu < newCPUCount; ++cpu {
			/* Note: In C/Objective-C, cpu_ticks is an array of size 4, which is
			 *       translated in Swift as a tuple of four elements.
			 *       If ever cpu_ticks contained more (or less) entries in another
			 *       Mac OS version, we would have to change this code.
			 *       In Objective-C, we used to have a generic version by itering
			 *       values from 0 to CPU_STATE_MAX... */
			let (user, system, idle, nice) = cpuLoadInfo.advancedBy(cpu).memory.cpu_ticks
			let total = Double(user + system + idle + nice)
			let totalNoIdle = Double(user + system + nice)
			totalTicks += total
			totalTicksNoIdle += totalNoIdle
			totalTicksPerCPU[cpu] = total
			totalTicksNoIdlePerCPU[cpu] = totalNoIdle
			
			cpuUsages[cpu] = (totalTicksNoIdlePerCPU[cpu] - previousTotalTicksNoIdlePerCPU[cpu])/(totalTicksPerCPU[cpu] - previousTotalTicksPerCPU[cpu])
			previousTotalTicksPerCPU[cpu] = totalTicksPerCPU[cpu]
			previousTotalTicksNoIdlePerCPU[cpu] = totalTicksNoIdlePerCPU[cpu]
		}
		
		globalCPUUsage = (totalTicksNoIdle - previousTotalTicksNoIdle)/(totalTicks - previousTotalTicks)
		previousTotalTicks = totalTicks
		previousTotalTicksNoIdle = totalTicksNoIdle
		
		vm_deallocate(mach_task_self_, unsafeBitCast(infoArray, vm_address_t.self), vm_size_t(infoCount))
		
		NSLog("%@", "Current CPU Usage: \(globalCPUUsage)")
		NSLog("%@", "CPU Usages: \(cpuUsages)")
		let frozenObservers = observers.allObjects
		for observer in frozenObservers {
			/* TODO: Notify observer the CPU Info changed. */
		}
	}
	
}
