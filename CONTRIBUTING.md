# Contributing to DocVault

Thank you for your interest in contributing to DocVault! This guide will help you understand our development workflow, coding standards, and pull request process.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing Requirements](#testing-requirements)
- [Pull Request Process](#pull-request-process)
- [Code Review Expectations](#code-review-expectations)
- [Release Process](#release-process)

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive experience for everyone. We expect all contributors to:

- Be respectful and considerate in communication
- Accept constructive criticism gracefully
- Focus on what is best for the community
- Show empathy towards other community members

### Unacceptable Behavior

- Harassment, discriminatory jokes, or derogatory comments
- Personal attacks or trolling
- Publishing others' private information without permission
- Other conduct inappropriate in a professional setting

## Getting Started

### Prerequisites

- Git 2.30+
- Docker 20.10+ and Docker Compose 2.0+
- Basic understanding of the tech stack (Symfony, React, Python, FastAPI)
- GitHub account

### Fork and Clone

1. **Fork the repository** you want to contribute to on GitHub
2. **Clone your fork:**

```bash
# For infrastructure repository
git clone --recursive https://github.com/YOUR_USERNAME/docvault-infrastructure.git

# For service repositories
git clone https://github.com/YOUR_USERNAME/docvault-backend.git
git clone https://github.com/YOUR_USERNAME/docvault-frontend.git
git clone https://github.com/YOUR_USERNAME/docvault-ocr-service.git
```

3. **Add upstream remote:**

```bash
git remote add upstream https://github.com/private-doc-vault/REPO_NAME.git
```

4. **Verify remotes:**

```bash
git remote -v
# origin    https://github.com/YOUR_USERNAME/REPO_NAME.git (fetch)
# origin    https://github.com/YOUR_USERNAME/REPO_NAME.git (push)
# upstream  https://github.com/private-doc-vault/REPO_NAME.git (fetch)
# upstream  https://github.com/private-doc-vault/REPO_NAME.git (push)
```

### Set Up Development Environment

Follow the setup instructions in the infrastructure repository's [README.md](README.md):

```bash
cd docvault-infrastructure
./setup.sh
docker-compose -f docker-compose.dev.yml up -d
```

## Development Workflow

### 1. Create a Feature Branch

Always create a new branch for your work:

```bash
# Update your local main branch
git checkout main
git pull upstream main

# Create and switch to a new branch
git checkout -b feature/my-awesome-feature

# Or for bug fixes
git checkout -b fix/issue-123
```

### Branch Naming Conventions

- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation changes
- `refactor/` - Code refactoring
- `test/` - Adding or updating tests
- `chore/` - Maintenance tasks

**Examples:**
- `feature/add-document-tagging`
- `fix/ocr-timeout-issue`
- `docs/update-api-documentation`
- `refactor/simplify-auth-logic`

### 2. Make Your Changes

- Write clean, readable code
- Follow the coding standards for the language you're working in
- Add tests for new functionality
- Update documentation as needed
- Keep commits focused and atomic

### 3. Commit Your Changes

Write clear, descriptive commit messages following the [Conventional Commits](https://www.conventionalcommits.org/) specification:

**Format:**
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style changes (formatting, missing semicolons, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(backend): add document tagging API endpoint

Implements POST /api/tags and PUT /api/documents/{id}/tags endpoints.
Includes validation, authorization checks, and unit tests.

Closes #123
```

```
fix(ocr): resolve timeout on large PDF files

Increased processing timeout from 60s to 300s and added progress
tracking for files larger than 10MB.

Fixes #456
```

```
docs(readme): update installation instructions

Added troubleshooting section for common Docker issues.
```

### 4. Push to Your Fork

```bash
git push origin feature/my-awesome-feature
```

### 5. Create a Pull Request

1. Go to the original repository on GitHub
2. Click "New Pull Request"
3. Select your fork and branch
4. Fill out the PR template (see below)
5. Submit the pull request

## Coding Standards

### Backend (Symfony/PHP)

- Follow [PSR-12](https://www.php-fig.org/psr/psr-12/) coding standard
- Use type hints for function parameters and return types
- Write PHPDoc comments for classes and public methods
- Keep methods focused and under 50 lines when possible
- Use dependency injection instead of static methods

**Code Style:**
```bash
# Check code style
vendor/bin/php-cs-fixer fix --dry-run --diff

# Fix code style issues
vendor/bin/php-cs-fixer fix
```

**Static Analysis:**
```bash
vendor/bin/phpstan analyse
```

### Frontend (React/JavaScript)

- Follow [Airbnb JavaScript Style Guide](https://github.com/airbnb/javascript)
- Use functional components with hooks
- Keep components under 200 lines
- Use meaningful variable and function names
- Add JSDoc comments for complex functions

**Linting:**
```bash
# Check for issues
npm run lint

# Auto-fix issues
npm run lint:fix
```

**Formatting:**
```bash
# Check formatting
npm run format:check

# Format code
npm run format
```

### OCR Service (Python)

- Follow [PEP 8](https://peps.python.org/pep-0008/) style guide
- Use type hints for function signatures
- Write docstrings for all public functions and classes
- Keep functions under 50 lines
- Use meaningful variable names (no single-letter variables except in loops)

**Code Quality:**
```bash
# Format code
black app/ tests/

# Lint
flake8 app/ tests/

# Type check
mypy app/

# Sort imports
isort app/ tests/
```

## Testing Requirements

### Backend Tests

- **Minimum Coverage:** 70% for new code
- **Test Types:** Unit tests, functional tests for API endpoints
- **Run Tests:**
  ```bash
  composer test
  ```

**Writing Tests:**
```php
use PHPUnit\Framework\TestCase;

class DocumentServiceTest extends TestCase
{
    public function testCreateDocument(): void
    {
        // Arrange
        $service = new DocumentService();

        // Act
        $document = $service->create(['title' => 'Test']);

        // Assert
        $this->assertInstanceOf(Document::class, $document);
        $this->assertEquals('Test', $document->getTitle());
    }
}
```

### Frontend Tests

- **Minimum Coverage:** 70% for new code
- **Test Types:** Component tests, integration tests
- **Run Tests:**
  ```bash
  npm test
  npm run test:coverage
  ```

**Writing Tests:**
```javascript
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { DocumentCard } from './DocumentCard';

test('renders document card', () => {
  const document = { id: 1, title: 'Test Doc' };
  render(<DocumentCard document={document} />);
  expect(screen.getByText('Test Doc')).toBeInTheDocument();
});

test('handles click event', async () => {
  const handleClick = jest.fn();
  render(<DocumentCard document={{...}} onClick={handleClick} />);

  await userEvent.click(screen.getByRole('button'));
  expect(handleClick).toHaveBeenCalledTimes(1);
});
```

### OCR Service Tests

- **Minimum Coverage:** 70% for new code
- **Test Types:** Unit tests, integration tests
- **Run Tests:**
  ```bash
  pytest
  pytest --cov=app
  ```

**Writing Tests:**
```python
import pytest
from app.ocr_service import OCRService

def test_process_document():
    ocr = OCRService()
    result = ocr.process_document('test.pdf')

    assert result['text'] is not None
    assert result['confidence'] > 0
    assert result['pages'] > 0
```

## Pull Request Process

### Before Submitting

1. **Rebase on upstream main:**
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Run all tests:**
   ```bash
   # Backend
   composer test

   # Frontend
   npm test

   # OCR Service
   pytest
   ```

3. **Check code quality:**
   ```bash
   # Backend
   vendor/bin/php-cs-fixer fix

   # Frontend
   npm run lint:fix
   npm run format

   # OCR Service
   black app/ tests/
   flake8 app/ tests/
   ```

4. **Verify coverage meets requirements:**
   ```bash
   # Backend
   vendor/bin/phpunit --coverage-text

   # Frontend
   npm run test:coverage

   # OCR Service
   pytest --cov=app --cov-report=term
   ```

### PR Template

When creating a pull request, include:

```markdown
## Description
Brief description of the changes and why they're needed.

## Type of Change
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Related Issues
Closes #123
Fixes #456

## Changes Made
- Added document tagging API endpoint
- Updated frontend to display tags
- Added tests for tag functionality
- Updated API documentation

## Testing
- [ ] Tests pass locally
- [ ] New tests added for new features
- [ ] Coverage meets requirements (≥70%)
- [ ] Manual testing completed

## Screenshots (if applicable)
[Add screenshots for UI changes]

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review of code completed
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] No new warnings generated
- [ ] Tests added and passing
- [ ] Dependent changes merged
```

### PR Size Guidelines

- Keep PRs focused on a single feature or fix
- Aim for PRs under 500 lines of code
- Split large features into multiple PRs when possible
- Consider creating a tracking issue for large features

## Code Review Expectations

### For Authors

- **Respond promptly** to review comments (within 2-3 days)
- **Be open to feedback** and willing to make changes
- **Explain your decisions** when you disagree with feedback
- **Update the PR** based on feedback and mark conversations as resolved
- **Notify reviewers** when you've addressed all comments

### For Reviewers

- **Review promptly** (within 2-3 days of submission)
- **Be constructive** and specific in feedback
- **Explain the "why"** behind your suggestions
- **Approve when satisfied** or request changes clearly
- **Test the changes** locally when appropriate

### Review Checklist

**Functionality:**
- [ ] Code works as described in the PR
- [ ] Edge cases are handled appropriately
- [ ] Error handling is implemented

**Code Quality:**
- [ ] Code is readable and maintainable
- [ ] No code duplication
- [ ] Functions/methods have single responsibility
- [ ] Naming is clear and consistent

**Testing:**
- [ ] Tests are included for new functionality
- [ ] Tests cover edge cases
- [ ] Coverage requirements are met

**Documentation:**
- [ ] README updated if needed
- [ ] API documentation updated if needed
- [ ] Code comments added for complex logic

**Security:**
- [ ] No sensitive data exposed
- [ ] Input validation implemented
- [ ] Authentication/authorization checked
- [ ] No SQL injection or XSS vulnerabilities

## Release Process

### Service Repositories

1. **Ensure all tests pass:**
   ```bash
   # CI workflow must be green
   ```

2. **Update version numbers:**
   - Update `package.json` (frontend)
   - Update relevant version constants

3. **Create a GitHub Release:**
   ```bash
   gh release create v1.0.1 \
     --title "v1.0.1" \
     --notes "### Features
     - Added document tagging
     - Improved search performance

     ### Bug Fixes
     - Fixed OCR timeout issues
     - Resolved CORS errors"
   ```

4. **Automated workflow:**
   - Release workflow builds and pushes Docker image
   - Infrastructure repository receives automated PR
   - Review and merge the infrastructure PR

### Infrastructure Repository

The infrastructure repository is updated automatically via PRs from service releases.

1. **Review the automated PR** from service release
2. **Test locally** if needed:
   ```bash
   git fetch origin
   git checkout update-backend-v1.0.1
   docker-compose up -d
   ```
3. **Merge the PR** when satisfied

## Questions?

- **Documentation:** Check the [README.md](README.md) first
- **Issues:** Search existing issues before creating new ones
- **Discussions:** Use GitHub Discussions for general questions
- **Urgent Matters:** Tag maintainers in relevant issues

## License

By contributing to DocVault, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to DocVault! 🎉
