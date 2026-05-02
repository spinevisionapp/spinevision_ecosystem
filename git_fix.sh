#!/bin/bash
# SpineVision Git Optimization Script
# Resolves "too many changes" by purging ignored files from the Git cache.

echo "Cleaning Git index and untracking ignored files..."
git rm -r --cached .
git add .

echo "Performing garbage collection to save space..."
git gc --prune=now --aggressive

echo "Git environment optimized."