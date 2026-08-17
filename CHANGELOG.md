# Changelog

All notable changes to this project are documented here.
This file is auto-generated from conventional commits on each release.

## [v2.33.1] - 2026-08-16

### Added
- show live collection match counts on guided-flow steps

## [v2.32.1] - 2026-08-16

### Added
- surface top-mechanic chips in guided flow, quick picks, and mechanics section
- show top-mechanics chips above the mechanics filter
- add top-mechanics quick-filter chips
- retain collection analytics on AppModel
- parse top_mechanics from collection analytics

### Fixed
- clone Setting collection values instead of sharing them

## [v2.27.4] - 2026-08-16

### Added
- seed filter defaults from collection analytics on load
- add FilterSeeder for position-only default seeding
- add CollectionAnalyticsService
- add CollectionAnalytics parse model

### Fixed
- seed filter defaults without a manual refresh
- prevent inverted time range and align complexity floor in seeder
- harden CollectionAnalytics parsing against malformed labels

## [v2.23.3] - 2026-08-14

### Fixed
- stop shelf-of-shame infinite reload loop

## [v2.23.1] - 2026-08-14

### Fixed
- stop shelf of shame deep link reload loop and show linked user's shelf

## [v2.23.0] - 2026-08-13

### Added
- add dark mode with curated theme palettes

## [v2.22.0] - 2026-08-12

### Added
- recently viewed games history in drawer

## [v2.21.0] - 2026-08-12

### Added
- debounce slider persistence to reduce redundant writes

## [v2.20.1] - 2026-07-19

### Added
- replace tour tips with context-sensitive help page

## [v2.19.4] - 2026-07-02

### Added
- surface collection ownership date on shelf of shame

### Fixed
- restore parameters and primary player correctly from permalinks
- stop random roll from exhausting the collection

## [v2.18.1] - 2026-07-01

### Added
- add play log with local tracking and BGG history

## [v2.17.11] - 2026-06-30

### Added
- enable gzip encoding and add Bgg-Plays-Meta header for API calls
- add service worker for PWA image caching
- support partial plays loading with automatic background retry
- add clock injection to BggCache and time inference to Settings
- add service locator for dependency injection
- add request deduplication and test injection to API services

### Fixed
- deduplicate shelf of shame API calls and load plays asynchronously

## [v2.11.4] - 2026-06-28

### Fixed
- listing page now rebuilds when plays data loads asynchronously

## [v2.11.3] - 2026-06-28

### Fixed
- **ci:** resolve race condition between Flutter CI and Tag Release workflows

## [v2.11.1] - 2026-06-28

### Added
- add Shelf of Shame feature with play tracking and UX improvements

## [v2.10.3] - 2026-06-25

### Fixed
- prevent app title truncation and compact detail buttons on mobile

## [v2.10.1] - 2026-06-25

### Added
- add favourites and ignored games with swipe gestures

### Fixed
- tour tips scroll into view, consolidate app bar tip, reduce padding

## [v2.10.0] - 2026-06-25

### Added
- add Quick Pick for fast random game selection

## [v2.9.0] - 2026-06-24

### Added
- cache drawer preferences and hide empty game stats

## [v2.8.3] - 2026-06-24

### Fixed
- handle null fields in hot games API response
- guard null preference delete and cache StoredPreferences instance

## [v2.8.2] - 2026-06-19

### Fixed
- use GitHub Actions API for issues instead of HTTP request

## [v2.8.1] - 2026-06-19

### Added
- auto-generate about page data in CI on tag release
- add about page with version info, upcoming features, and contributors
- replace collection/geeklist toggle with auto-detected leading icon

### Fixed
- handle GitHub API timeout in about data generation
- load saved sources on refresh and show friendly empty state
- share button on random game page and remove false fallback dialog
- compact step 1 tabs to prevent text wrapping on mobile
- center loading screen on mobile viewports

## [v2.8.0] - 2026-06-18

### Added
- add tour tips, trending games, fun facts, and remove legacy mobile

## [v2.7.0] - 2026-06-17

### Added
- redesign list pages with thumbnails, stats, rating badges, and sort indicators

## [v2.6.0] - 2026-06-17

### Added
- add rating badge to game image overlay

## [v2.5.0] - 2026-06-17

### Added
- add game detail page with cached API, share permalink, and image alignment

## [v2.4.2] - 2026-06-15

### Fixed
- stale cache served after removing a collection/geeklist

## [v2.4.1] - 2026-06-15

### Fixed
- cache invalidation & url reload stopping user changes

## [v2.4.0] - 2026-06-14

### Added
- prefetch cache warming for collections and geeklists

## [v2.3.0] - 2026-06-14

### Added
- replace max complexity filter with around-complexity filter

## [v2.2.1] - 2026-06-13

### Added
- add Board Game News link to app bar

## [v2.2.0] - 2026-06-13

### Added
- swipe gestures, larger step hit targets, full-width advanced mode

## [v2.1.0] - 2026-06-13

### Added
- PWA install banner and home screen prompt
- add Finish button to guided flow for direct navigation to results
- UI consistency improvements

### Fixed
- update code to correct analysis warnings from flutter upgrade
- upgrade Flutter version in CI to 3.44.x for Dart 3.12 compatibility
- update GitHub Actions workflow for Flutter 3.0

## [v2.0.0] - 2026-06-05

### Added
- add mock BGG API server for development
- add BGG attribution and theme extensions
- add guided flow UI for game selection

### Fixed
- enable Add Source button when text is entered
- restore automatic ItemType detection for numeric IDs
- add missing null assertion in router path extraction
- handle unknown setting keys gracefully
- prevent race conditions in async data operations
