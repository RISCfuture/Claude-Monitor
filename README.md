# Claude Monitor

A macOS menu bar application that displays your Claude API usage limits.

## Features

- Menu bar icon showing current usage status
- Popover with detailed usage breakdown by limit type
- Automatic background refresh
- Native macOS notifications when usage thresholds are reached
- Secure token storage in macOS Keychain

## Requirements

- macOS 14.0+
- Xcode 16.0+

## Installation

### From Source

1. Clone the repository
2. Open `Claude Monitor.xcodeproj` in Xcode
3. Build and run

## Configuration

On first launch, you'll need to provide your Claude session token:

1. Click the menu bar icon
2. Click "Settings" or press `Cmd+,`
3. Enter your session token

## Development

### Formatting

This project uses [swift-format](https://github.com/swiftlang/swift-format) for code formatting:

```bash
swift format format --in-place --recursive "Claude Monitor"
```

### Linting

This project uses [SwiftLint](https://github.com/realm/SwiftLint) for linting:

```bash
swiftlint lint "Claude Monitor"
```

### Building

```bash
xcodebuild -scheme "Claude Monitor" -configuration Release build
```

## License

MIT License. See [LICENSE](LICENSE) for details.
