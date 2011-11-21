/*
 * FLConstants.h
 * CPU Indicator
 *
 * Created by François LAMBOLEY on 3/7/11.
 * Copyright 2011 Frost Land. All rights reserved.
 */

typedef enum FLMixedImageState {
	FLMixedImageStateFromSkin = -1,
	
	FLMixedImageStateAllow = 0,
	FLMixedImageStateTransitionsOnly = 1,
	FLMixedImageStateDisallow = 2
} FLSkinMixedImageState;

#define FL_UDK_FIRST_RUN @"FL First Run"
#define FL_UDK_HIDE_DOCK @"FL Hide Dock"
#define FL_UDK_STICK_TO_IMAGES @"FL Stick to Images" /* DEPRECATED by line below */
#define FL_UDK_MIXED_IMAGE_STATE @"FL Mixed Image State"
#define FL_UDK_DISALLOW_SHADOW @"FL Disallow Shadow"
#define FL_UDK_ALLOW_WINDOW_DRAG_N_DROP @"FL Allow Window Drag'n'Drop"
#define FL_UDK_WINDOW_TRANSPARENCY @"FL Window Transparency"
#define FL_UDK_SKIN_X_SCALE @"FL Skin X Scale"
#define FL_UDK_SKIN_Y_SCALE @"FL Skin Y Scale"
#define FL_UDK_LAST_SELECTED_PREF_ID @"FL Last Selected Pref Identifier"
#define FL_UDK_SELECTED_SKIN @"FL Selected Skin"
#define FL_UDK_PREFS_PANES_SIZES @"FL Prefs Panes Sizes"

#define FL_SKINS_ADDRESS @"http://www.frostland.fr/products/cpu_indicator/skins/"
