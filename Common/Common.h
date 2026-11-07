#pragma once

#import <Foundation/Foundation.h>
#import "ApelinBootstrap.h"

// On roothide the bootstrap is not at /, so a bootstrap path goes through
// ApelinBootstrapPath (jbroot at run time), never a literal.
#define jbRootPath(path) ApelinBootstrapPath(path)
