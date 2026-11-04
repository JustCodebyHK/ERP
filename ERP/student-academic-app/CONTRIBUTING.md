# Contributing to Student Academic App

Thank you for considering contributions to the Student Academic App!

## How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes (`git commit -m 'feat: add your feature'`)
4. Push to the branch (`git push origin feature/your-feature`)
5. Open a Pull Request

## Commit Convention

We follow conventional commits:

- feat: New feature
- fix: Bug fix
- docs: Documentation changes
- chore: Maintenance tasks
- refactor: Code refactoring
- style: Formatting changes
- test: Adding tests

## Code Style

### Backend (Node.js)
- Use CommonJS modules (require/module.exports)
- Follow existing middleware patterns
- Add validation using the validation.js module
- Handle errors with try/catch and next(err)

### Frontend (Flutter/Dart)
- Follow existing model patterns (fromJson/toJson/copyWith)
- Use ApiClient for all HTTP requests
- Use AuthStore for authentication state
- Add proper null safety

## Testing

- Run backend tests: npm test (in backend/)
- Run Flutter analysis: flutter analyze
- Run Flutter tests: flutter test

## Reporting Issues

Please use GitHub Issues to report bugs or suggest features. Include:
- Steps to reproduce
- Expected vs actual behavior
- Screenshots (if applicable)
- Device/OS version