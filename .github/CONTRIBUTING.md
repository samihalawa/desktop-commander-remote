# Contributing to DC Remote

Thanks for your interest in contributing!

## Getting Started

1. Fork the repo and clone locally
2. `npm install && npm run build`
3. Compile the menubar app: `swiftc menubar/DCRemoteMenuBar.swift -framework Cocoa -framework WebKit -o /tmp/DCRemoteMenuBar`
4. Make your changes on a feature branch
5. Test thoroughly on macOS 12+
6. Open a PR against `main`

## Code Style

- TypeScript for the daemon (`src/`)
- Swift for the menubar app (`menubar/`)
- Follow existing patterns — no new abstractions without clear need

## Reporting Issues

Use the GitHub issue templates. Include macOS version, Node.js version, and reproduction steps.

## License

By contributing you agree your work will be licensed under the MIT License.
