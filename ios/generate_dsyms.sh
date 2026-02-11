#!/bin/bash

# Script to generate dSYMs for frameworks that don't have them
# This fixes the missing dSYM error for objective_c.framework

set -e

echo "Generating missing dSYMs..."

# Find all frameworks in the build
FRAMEWORKS_PATH="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}"

if [ -d "$FRAMEWORKS_PATH" ]; then
    echo "Checking frameworks in: $FRAMEWORKS_PATH"
    
    for FRAMEWORK in "$FRAMEWORKS_PATH"/*.framework; do
        if [ -d "$FRAMEWORK" ]; then
            FRAMEWORK_NAME=$(basename "$FRAMEWORK" .framework)
            FRAMEWORK_BINARY="$FRAMEWORK/$FRAMEWORK_NAME"
            DSYM_PATH="${BUILT_PRODUCTS_DIR}/${FRAMEWORK_NAME}.framework.dSYM"
            
            # Check if dSYM already exists
            if [ ! -d "$DSYM_PATH" ]; then
                # Check if the framework binary exists and has debug symbols
                if [ -f "$FRAMEWORK_BINARY" ]; then
                    echo "Generating dSYM for $FRAMEWORK_NAME..."
                    
                    # Use dsymutil to generate dSYM
                    xcrun dsymutil "$FRAMEWORK_BINARY" -o "$DSYM_PATH" 2>/dev/null || {
                        echo "Warning: Could not generate dSYM for $FRAMEWORK_NAME (may not contain debug symbols)"
                    }
                    
                    if [ -d "$DSYM_PATH" ]; then
                        echo "✓ Generated dSYM for $FRAMEWORK_NAME"
                    fi
                fi
            else
                echo "✓ dSYM already exists for $FRAMEWORK_NAME"
            fi
        fi
    done
fi

echo "dSYM generation complete"
