/*
 * Constants.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 9/1/15.
 * Copyright © 2015 Frost Land. All rights reserved.
 */

import Foundation



let kAppErrorDomainName = "fr.frostland.cpu-indicator"
let kErr_Unknown = 1
let kErr_CoreDataSetup = 2
let kErr_CannotSaveRollbacked = 3



let kUDK_FirstRun = "FLFirstRun"

let kUDK_PrefsPanesSizes          = "FLPrefsPanesSizes"
let kUDK_LatestSelectedPrefPaneId = "FLLatestPrefPaneId"


enum WindowIndicatorLevel: Int {
	case normal    = 1
	case aboveAll  = 2
	case behindAll = 3
}

let kUDK_ShowWindowIndicator                   = "FLShowWindow"
let kUDK_WindowIndicatorLevel                  = "FLWindowLevel"
let kUDK_WindowIndicatorScale                  = "FLWindowScale"
let kUDK_WindowIndicatorOpacity                = "FLWindowOpacity"
let kUDK_WindowIndicatorDisableShadow          = "FLShadowlessWindow"
let kUDK_WindowIndicatorLocked                 = "FLWindowLocked"
let kUDK_WindowIndicatorClickless              = "FLClicklessWindow"
let kUDK_WindowIndicatorDecreaseOpacityOnHover = "FLDecreaseWindowOpacityOnHover"


enum MenuIndicatorMode: Int {
	case image = 1
	case text  = 2
	case both  = 3
}

let kUDK_ShowMenuIndicator      = "FLShowMenu"
let kUDK_MenuIndicatorMode      = "FLMenuMode"
let kUDK_MenuIndicatorOnePerCPU = "FLOneMenuPerCPU"


let kUDK_ShowDockIcon = "FLShowDock"
let kUDK_DockIconIsCPUIndicator = "FLShowCPUInDock"


@objc
enum MixedImageState: Int16 {
	case useSkinDefault    = -1
	case allow             =  1
	case allowTransitions  =  2
	case disallow          =  3
}
let kUDK_SelectedSkinUID = "FLSelectedSkinUID"
let kUDK_MixedImageState = "FLMixedImageState"
