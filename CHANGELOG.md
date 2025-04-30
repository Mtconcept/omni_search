# Changelog
All notable changes to the Omni Search package will be documented in this file.

##  0.0.2 - 2025-04-30

### Added
- New `initialShowLocalList` parameter to allow displaying local results immediately on widget initialization
- Improved stream initialization to ensure consistent behavior across different usage scenarios
- Better handling of empty searches and stream activation

### Fixed
- Stream synchronization issues that could prevent initial results from displaying
- More reliable state management for search results

## 0.0.1 - 2025-04-27

### Initial Release
- Core search functionality with hybrid local-remote capability
- Instant local search with zero loading time
- Smart remote search fallback when local results aren't found
- Debounced API calls to minimize network usage
- Results caching for better performance
- Generic implementation for any data type
- Ready-to-use UI components with customization options
- Comprehensive documentation and examples