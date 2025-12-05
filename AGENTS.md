# Multi-Agent Copilot Support

## Overview

Laundry Logger uses specialized Copilot agent profiles for different aspects of development.

## Agent Profiles

### 1. Flutter Developer Agent

**Location:** `/agents/flutter-developer.md`

**Responsibilities:**
- Flutter widget development
- State management with BLoC
- Platform-specific implementations
- UI/UX best practices

**Context:**
- Flutter 3.16+ conventions
- Material 3 design system
- Dart best practices

### 2. Database Agent

**Location:** `/agents/database-agent.md`

**Responsibilities:**
- SQLite schema design
- Query optimization
- Migration strategies
- Data integrity

**Context:**
- sqflite patterns
- Offline-first architecture
- Backup/restore logic

### 3. Testing Agent

**Location:** `/agents/testing-agent.md`

**Responsibilities:**
- Test case generation
- Coverage improvement
- Mock creation
- E2E test scenarios

**Context:**
- flutter_test framework
- mocktail patterns
- Integration testing

### 4. Security Agent

**Location:** `/agents/security-agent.md`

**Responsibilities:**
- Encryption implementation
- Secure storage patterns
- PIN/biometric auth
- Data privacy

**Context:**
- flutter_secure_storage
- Encryption best practices
- OWASP mobile guidelines

### 5. Documentation Agent

**Location:** `/agents/documentation-agent.md`

**Responsibilities:**
- Code documentation
- API documentation
- User guides
- Architecture docs

**Context:**
- Dart doc comments
- README standards
- Changelog format

## Usage

Reference agents in your prompts:

```
@flutter-developer Create a new widget for displaying laundry items in a grid
```

```
@database-agent Design the migration for adding household members
```

```
@testing-agent Generate unit tests for the ItemBloc
```

## Agent Configuration

Each agent profile contains:

1. **Role description** — What the agent specializes in
2. **Context files** — Relevant code and documentation
3. **Coding standards** — Style and pattern preferences
4. **Examples** — Sample outputs and templates

## Best Practices

1. **Use specific agents** for specialized tasks
2. **Provide context** about what you're building
3. **Reference existing code** when extending functionality
4. **Review agent outputs** for project consistency
