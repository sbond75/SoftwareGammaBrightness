//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//
#pragma once

#import <Foundation/Foundation.h>
#import <IOKit/i2c/IOI2CInterface.h>
#import <CoreGraphics/CoreGraphics.h>

// https://github.com/MonitorControl/MonitorControl/discussions/635
extern CFDictionaryRef CoreDisplay_DisplayCreateInfoDictionary(CGDirectDisplayID);
