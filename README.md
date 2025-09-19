<div align="center">
    <img src="assets/header.svg"></br>
    <img src="https://img.shields.io/badge/Swift-5.9-f05318.svg" />
    <img src="https://img.shields.io/badge/tuist-template-blue.svg" />
    <img alt="GitHub" src="https://img.shields.io/github/license/jihoonahn/designtuist">
</div>

# DesignTuist

**DesignTuist** is a Tuist template for modular architecture. It provides CLI tools to design projects according to your current situation.

## 🚀 Key Features

- **Modular Architecture**: Feature, Domain, Core, Shared layer structure
- **CLI Tools**: 5 commands for project generation, module management, and dependency management
- **Interactive UI**: User-friendly terminal-based interface
- **Multi-Environment Support**: Environment-specific configurations for Default, CI, CD

## 📋 Requirements

- macOS 13.0+
- Swift 6.1+
- Tuist

## 🛠 Installation

1. Clone the repository:

```bash
git clone https://github.com/jihoonme/designtuist.git
cd designtuist
```

2. Build with Swift Package Manager:

```bash
swift build -c release
```

3. Run commands:

```bash
# Direct execution with swift run (recommended)
swift run generate

# Or run built executables directly
.build/release/generate

# Add to PATH for global use (optional)
cp .build/release/* /usr/local/bin/
```

## 📚 Command Usage

> **Note:** All commands should be executed in the format `swift run [command-name]`.

### 1. `generate` - Workspace Generation

Generates an Xcode workspace.

```bash
swift run generate [type] [options]
```

**Parameters:**

- `type`: `default`, `CI`, `CD` (default: default)
- `--path, -p`: Project directory path

**Usage Examples:**

```bash
swift run generate                    # Generate default workspace
swift run generate CI                 # Generate workspace for CI environment
swift run generate --path ./MyProject # Generate workspace at specific path
```

### 2. `module` - Module Generation

Creates a new module through an interactive UI.

```bash
swift run module
```

**Features:**

- Enter module name
- Select layer (Feature, Domain, Core, Shared)
- Select components (Sources, Interface, Example, Tests, UITests)
- Automatic generation via Tuist scaffold

**Usage Flow:**

1. Enter module name
2. Select layer (Feature/Domain/Core/Shared)
3. Select components to generate
4. Execute automatic generation

### 3. `install` - Dependency Installation

Installs Swift Package Manager dependencies.

```bash
swift run install <package-name> --version <version> [options]
```

**Parameters:**

- `package-name`: GitHub package name (owner/repo format)
- `--version, -v`: Version to install
- `--path, -p`: Project directory path

**Usage Examples:**

```bash
swift run install alamofire/alamofire --version 5.8.1
swift run install --path ./MyProject rxswift/rxswift --version 6.7.1
```

### 4. `uninstall` - Dependency Removal

Removes Swift Package Manager dependencies.

```bash
swift run uninstall <package-name> [options]
```

**Parameters:**

- `package-name`: Package name to remove
- `--path, -p`: Project directory path

**Usage Examples:**

```bash
swift run uninstall alamofire
swift run uninstall --path ./MyProject rxswift
```

### 5. `clean` - Project Cleanup

Cleans Tuist project.

```bash
swift run clean [options]
```

**Parameters:**

- `--path, -p`: Project directory path

**Usage Examples:**

```bash
swift run clean                      # Clean current directory
swift run clean --path ./MyProject   # Clean specific path
```

## 🏗 Project Structure

```
designtuist/
├── Commands/              # CLI command implementations
│   ├── Clean/            # clean command
│   ├── Generate/         # generate command
│   ├── Install/          # install command
│   ├── Module/           # module command
│   ├── Uninstall/        # uninstall command
│   └── CommandKit/       # Common services and utilities
├── Configuration/        # Environment-specific configuration files
├── Projects/            # Project templates
│   ├── App/             # App project
│   ├── Core/            # Core layer
│   ├── Domain/          # Domain layer
│   ├── Feature/         # Feature layer
│   └── Shared/          # Shared layer
└── Tuist/               # Tuist configuration and templates
    ├── Templates/       # Module templates
    └── ProjectDescriptionHelpers/
```

## 🔧 Development

### Dependencies

This project uses the following Swift packages:

- [swift-argument-parser](https://github.com/apple/swift-argument-parser): CLI argument parsing
- [swift-log](https://github.com/apple/swift-log): Logging
- [swift-command](https://github.com/pelagornis/swift-command): Command execution
- [swift-file](https://github.com/pelagornis/swift-file): File system operations
- [swift-cli](https://github.com/pelagornis/swift-cli): CLI UI components

### Build and Test

```bash
# Debug build
swift build

# Release build
swift build -c release

# Run tests
swift test
```

## 🤝 Contributing

1. Fork this repository
2. Create a new branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Create a Pull Request

## 📄 License

**DesignTuist** is distributed under the MIT license. See the [LICENSE](/LICENSE) file for more info.
