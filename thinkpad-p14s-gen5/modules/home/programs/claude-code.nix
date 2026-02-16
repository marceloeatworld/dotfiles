# Claude Code - AI-powered CLI assistant
# Installed via nixpkgs with declarative configuration management
{ pkgs, ... }:

let
  # Security hook for blocking access to sensitive files and dangerous commands
  # Based on official Claude Code hooks documentation:
  # https://code.claude.com/docs/en/hooks
  # https://code.claude.com/docs/en/hooks-guide
  protectSensitiveFilesHook = pkgs.writeText "protect_sensitive_files.py" ''
    #!/usr/bin/env python3
    """
    Claude Code Security Hook - Defense in Depth

    This hook provides pattern-based protection that complements the sandbox's
    literal path restrictions. On Linux, the bubblewrap sandbox only supports
    literal paths, so this hook adds glob-like pattern matching.

    Exit codes (per official docs):
      0 - Allow operation (success)
      1 - Hook error (non-blocking, logged in verbose mode)
      2 - Block operation (security violation, stderr shown to Claude)

    Supports tools: Read, Edit, Write, Bash
    """
    import sys
    import json
    import os
    from pathlib import Path

    # ══════════════════════════════════════════════════════════════════════════
    # SAFE CODE EXTENSIONS (always allowed, never blocked by prefix rules)
    # These are legitimate source code files that should never be blocked
    # ══════════════════════════════════════════════════════════════════════════
    SAFE_CODE_EXTENSIONS = frozenset({
        # JavaScript/TypeScript
        'js', 'jsx', 'ts', 'tsx', 'mjs', 'cjs',
        # Web
        'html', 'css', 'scss', 'sass', 'less', 'vue', 'svelte',
        # Backend
        'py', 'rb', 'php', 'go', 'rs', 'java', 'kt', 'scala', 'cs',
        # Systems
        'c', 'cpp', 'cc', 'h', 'hpp',
        # Config/Data (non-sensitive)
        'yaml', 'yml', 'toml', 'xml', 'json',
        # Documentation
        'md', 'rst', 'txt',
        # Shell scripts
        'sh', 'bash', 'zsh', 'fish',
        # Nix
        'nix',
        # Dart/Flutter
        'dart',
        # Other
        'sql', 'graphql', 'proto',
    })

    # ══════════════════════════════════════════════════════════════════════════
    # SENSITIVE FILE EXTENSIONS (without dot)
    # ══════════════════════════════════════════════════════════════════════════
    SENSITIVE_EXTENSIONS = frozenset({
        # Cryptographic keys and certificates
        'pem', 'key', 'p12', 'pfx', 'crt', 'cer', 'der',
        'keystore', 'jks', 'gpg', 'asc', 'pgp',
        # Backup files that might contain secrets
        'bak', 'backup', 'old',
    })

    # ══════════════════════════════════════════════════════════════════════════
    # SENSITIVE FILE NAMES (exact match, case-insensitive)
    # ══════════════════════════════════════════════════════════════════════════
    SENSITIVE_NAMES = frozenset({
        # Environment files
        '.env', '.env.local', '.env.production', '.env.development',
        '.env.staging', '.env.test', '.envrc',
        # SSH keys and config
        'id_rsa', 'id_ed25519', 'id_dsa', 'id_ecdsa',
        'id_rsa.pub', 'id_ed25519.pub', 'id_dsa.pub', 'id_ecdsa.pub',
        'known_hosts', 'authorized_keys',
        # Credentials files
        'credentials.json', 'service-account.json', 'secrets.json',
        'credentials', '.credentials', 'client_secret.json',
        # Package manager auth
        '.netrc', '.npmrc', '.pypirc', '.gemrc', '.yarnrc',
        # System files
        'htpasswd', 'shadow', 'passwd', 'sudoers',
        # Cloud provider configs
        'config.json',  # Docker, various cloud CLIs
        # History files (contain commands with potential secrets)
        '.bash_history', '.zsh_history', '.python_history',
        '.node_repl_history', '.psql_history', '.mysql_history',
    })

    # ══════════════════════════════════════════════════════════════════════════
    # SENSITIVE FILE NAME PREFIXES (startswith match)
    # ══════════════════════════════════════════════════════════════════════════
    SENSITIVE_PREFIXES = (
        '.env',        # .env.anything
        'secret',      # secret_key.txt, secrets.yaml
        'credential',  # credentials_backup.json
        'token',       # token.json, tokens.txt
        'password',    # passwords.txt
        'apikey',      # apikey.txt
        'api_key',     # api_key.json
        'private',     # private_key.pem
        'auth',        # auth_token.json
    )

    # ══════════════════════════════════════════════════════════════════════════
    # SENSITIVE DIRECTORIES (any path component match)
    # ══════════════════════════════════════════════════════════════════════════
    SENSITIVE_DIRS = frozenset({
        # SSH and GPG
        '.ssh', '.gnupg', '.pgp',
        # Cloud providers
        '.aws', '.azure', '.gcloud', '.config/gcloud',
        # Container and orchestration
        '.kube', '.docker', '.helm',
        # Password managers
        '.password-store', '.local/share/keyrings',
        # Generic sensitive directories
        'secrets', 'credentials', 'private', 'keys',
        # Git internals (can contain credentials in config)
        '.git',
    })

    # ══════════════════════════════════════════════════════════════════════════
    # DANGEROUS BASH COMMANDS (blocked patterns)
    # ══════════════════════════════════════════════════════════════════════════
    DANGEROUS_COMMANDS = (
        # Destructive commands
        'rm -rf /',
        'rm -rf ~',
        'rm -rf $HOME',
        'rm -rf /*',
        'mkfs.',
        'dd if=',
        ':(){:|:&};:',  # Fork bomb
        # Permission escalation
        'chmod 777',
        'chmod -R 777',
        'chown -R',
        # Sensitive file access via shell
        'cat ~/.ssh',
        'cat ~/.aws',
        'cat ~/.gnupg',
        'cat /etc/shadow',
        'cat /etc/passwd',
        # History access
        'history',
        'cat ~/.bash_history',
        'cat ~/.zsh_history',
        # Credential extraction
        'cat ~/.netrc',
        'cat ~/.npmrc',
        # Network exfiltration of secrets
        'curl.*secret',
        'wget.*secret',
        'curl.*password',
        'curl.*token',
    )

    def has_path_traversal(path_str: str) -> bool:
        """Check for path traversal attempts."""
        # Normalize and check for ..
        normalized = os.path.normpath(path_str)
        if '..' in normalized:
            return True
        # Check for encoded traversal
        if '%2e%2e' in path_str.lower() or '..%2f' in path_str.lower():
            return True
        return False

    def is_sensitive_file(file_path: Path) -> str | None:
        """Check if file is sensitive. Returns reason string or None."""
        path_str = str(file_path)
        name = file_path.name.lower()
        suffix = file_path.suffix.lstrip('.').lower()
        parts = set(p.lower() for p in file_path.parts)

        # 1. Check for path traversal (always blocked)
        if has_path_traversal(path_str):
            return "path traversal attempt detected"

        # 2. Check sensitive directories (always blocked)
        for sensitive_dir in SENSITIVE_DIRS:
            if sensitive_dir.lower() in parts:
                return f"sensitive directory '{sensitive_dir}'"

        # 3. Check exact file names (always blocked)
        if name in SENSITIVE_NAMES or file_path.name in SENSITIVE_NAMES:
            return f"sensitive file '{file_path.name}'"

        # 4. Check extensions - block sensitive, but SAFE CODE files bypass prefix checks
        if suffix in SENSITIVE_EXTENSIONS:
            return f"sensitive extension '.{suffix}'"

        # 5. If file has a safe code extension, skip prefix checks entirely
        #    This allows auth.api.ts, AuthCallback.tsx, etc.
        if suffix in SAFE_CODE_EXTENSIONS:
            return None

        # 6. Check prefixes (only for non-code files)
        for prefix in SENSITIVE_PREFIXES:
            if name.startswith(prefix):
                return f"sensitive pattern '{name}'"

        return None

    def is_dangerous_command(command: str) -> str | None:
        """Check if bash command is dangerous. Returns reason or None."""
        cmd_lower = command.lower()

        for pattern in DANGEROUS_COMMANDS:
            if pattern.lower() in cmd_lower:
                return f"dangerous command pattern '{pattern}'"

        # Check for attempts to read sensitive files via bash
        for sensitive_dir in SENSITIVE_DIRS:
            if sensitive_dir in cmd_lower and ('cat ' in cmd_lower or 'less ' in cmd_lower or 'head ' in cmd_lower or 'tail ' in cmd_lower):
                return f"attempt to read from '{sensitive_dir}'"

        return None

    def main():
        try:
            data = json.load(sys.stdin)
        except json.JSONDecodeError:
            # Empty input or malformed JSON - allow (fail open for usability)
            sys.exit(0)

        tool_name = data.get('tool_name', "")
        tool_input = data.get('tool_input', {})

        # Handle file operations (Read, Edit, Write)
        file_path_str = tool_input.get('file_path')
        if file_path_str:
            if reason := is_sensitive_file(Path(file_path_str)):
                msg = f"SECURITY_POLICY: {tool_name} blocked - {reason}\n"
                msg += f"File: {file_path_str}\n"
                msg += "This file is protected by security policy."
                sys.stderr.write(msg)
                sys.exit(2)

        # Handle Bash commands
        if tool_name == 'Bash':
            command = tool_input.get('command', "")
            if command:
                if reason := is_dangerous_command(command):
                    msg = f"SECURITY_POLICY: Bash blocked - {reason}\n"
                    msg += f"Command: {command[:100]}{'...' if len(command) > 100 else '''}\n"
                    msg += "This command is blocked by security policy."
                    sys.stderr.write(msg)
                    sys.exit(2)

        # Allow the operation
        sys.exit(0)

    if __name__ == '__main__':
        main()
  '';

  # Claude Code settings.json with improved security
  settingsJson = builtins.toJSON {
    env = {
      CLAUDE_CODE_MAX_OUTPUT_TOKENS = "64000";
      # Note: Auto-updater is automatically disabled on NixOS (read-only /nix/store)
      # Updates are handled via: nix flake update && rebuild
    };
    permissions = {
      allow = [
        # Web documentation (read-only)
        "WebSearch"
        "WebFetch(domain:github.com)"
        "WebFetch(domain:wiki.hyprland.org)"
        "WebFetch(domain:wiki.nixos.org)"
        "WebFetch(domain:docs.anthropic.com)"
        "WebFetch(domain:deepwiki.com)"
        "WebFetch(domain:discourse.nixos.org)"
        # System info (read-only, no modification possible)
        "Bash(pgrep:*)"
        "Bash(ps:*)"
        "Bash(ip addr:*)"
        "Bash(ip route:*)"
        "Bash(resolvectl status:*)"
        "Bash(systemctl status:*)"
        "Bash(systemctl list-timers:*)"
        "Bash(journalctl:*)"
        "Bash(dmesg:*)"
        "Bash(printenv:*)"
        "Bash(nmcli connection:*)"
        # Hyprland (read config only)
        "Bash(hyprctl getoption:*)"
        "Bash(hyprctl options:*)"
        "Bash(hyprctl version:*)"
        # Nix (read/check only)
        "Bash(nix-instantiate:*)"
        "Bash(nix flake check:*)"
        "Bash(nix search:*)"
        "Bash(nix hash to-sri:*)"
        # Git (fetch only, no push/commit)
        "Bash(git fetch:*)"
        "Bash(git status:*)"
        "Bash(git log:*)"
        "Bash(git diff:*)"
        "Bash(git branch:*)"
        # UWSM (read-only)
        "Bash(uwsm check:*)"
        "Bash(uwsm list:*)"
        "Bash(Hyprland --help)"
        # Plugin scripts (Ralph Wiggum)
        "Bash(/home/marcelo/.claude/plugins/cache/claude-code-plugins/ralph-wiggum/*)"
        "Bash(/home/marcelo/.claude/plugins/cache/claude-plugins-official/ralph-wiggum/*)"
      ];
      # NOTE: On Linux, glob patterns (**/*) are NOT supported by bubblewrap sandbox.
      # Using literal paths instead. The Python hook provides additional pattern-based protection.
      deny = [
        # ══════════════════════════════════════════════════════════════════════
        # Environment files (secrets) - literal paths for Linux compatibility
        # ══════════════════════════════════════════════════════════════════════
        "Read(~/.env)"
        "Read(~/.env.local)"
        "Read(~/.env.production)"
        "Read(~/.env.development)"

        # ══════════════════════════════════════════════════════════════════════
        # Credential directories - using ~ for home directory expansion
        # ══════════════════════════════════════════════════════════════════════
        "Read(~/.ssh)"
        "Read(~/.aws)"
        "Read(~/.gnupg)"
        "Read(~/.password-store)"
        "Read(~/.kube)"
        "Read(~/.docker)"

        # ══════════════════════════════════════════════════════════════════════
        # Sensitive config files
        # ══════════════════════════════════════════════════════════════════════
        "Read(~/.netrc)"
        "Read(~/.npmrc)"
        "Read(~/.pypirc)"
        "Read(~/.gitconfig-secrets)"

        # ══════════════════════════════════════════════════════════════════════
        # System sensitive files - using // for absolute paths on Linux
        # ══════════════════════════════════════════════════════════════════════
        "Read(//etc/passwd)"
        "Read(//etc/shadow)"
        "Read(//etc/sudoers)"
        "Read(//etc/ssh)"

        # ══════════════════════════════════════════════════════════════════════
        # Edit restrictions - same directories
        # ══════════════════════════════════════════════════════════════════════
        "Edit(~/.env)"
        "Edit(~/.env.local)"
        "Edit(~/.ssh)"
        "Edit(~/.aws)"
        "Edit(~/.gnupg)"
        "Edit(~/.password-store)"
        "Edit(~/.kube)"
        "Edit(~/.docker)"
        "Edit(//etc)"
      ];
      defaultMode = "default";
    };
    # Plugins configuration
    enabledPlugins = {
      "frontend-design@claude-code-plugins" = true;
      "typescript-lsp@claude-plugins-official" = true;
      "pyright-lsp@claude-plugins-official" = true;
      "stripe@claude-plugins-official" = true;
      "code-review@claude-code-plugins" = true;
      "pg@aiguide" = true;
      "clangd-lsp@claude-plugins-official" = true;
      "pr-review-toolkit@claude-code-plugins" = true;
      "ralph-wiggum@claude-code-plugins" = true;
    };
    # Sandbox configuration (Linux bubblewrap)
    sandbox = {
      enabled = true;
      autoAllowBashIfSandboxed = false;
    };
    # Extended thinking
    alwaysThinkingEnabled = true;
    # Hooks configuration - security hooks for file access control
    # Based on official docs: https://code.claude.com/docs/en/hooks
    hooks = {
      # PreToolUse hooks run before tool execution
      # Using regex matcher to handle multiple tools with a single hook (more efficient)
      PreToolUse = [
        {
          # Combined matcher for file operations AND bash commands
          # Regex pattern matches: Read, Edit, Write, or Bash
          matcher = "Read|Edit|Write|Bash";
          hooks = [
            {
              type = "command";
              # Hook script handles all tool types and blocks:
              # - Sensitive file access (Read/Edit/Write)
              # - Dangerous bash commands (rm -rf, chmod 777, etc.)
              # - Path traversal attempts (..)
              command = "python3 $HOME/.claude/hooks/protect_sensitive_files.py";
            }
          ];
        }
      ];
    };
  };

  # Agent: Code Reviewer (Laravel-focused)
  codeReviewerAgent = ''
    ---
    name: code-reviewer
    description: Use this agent when the user has completed writing a logical chunk of code and wants it reviewed for quality, best practices, potential bugs, or alignment with project standards. This agent should be invoked proactively after code generation tasks are completed, or when the user explicitly requests a code review. Examples:\n\n<example>\nContext: User just finished implementing a new feature\nuser: "I've just added a new API endpoint for user registration"\nassistant: "Great! Let me use the code-reviewer agent to review the implementation for security best practices and code quality."\n<uses Task tool to launch code-reviewer agent>\n</example>\n\n<example>\nContext: User completed a refactoring task\nuser: "I've refactored the GenerativeProxyService to support the new Ideogram provider"\nassistant: "Excellent work. I'll now invoke the code-reviewer agent to ensure the refactoring maintains consistency with existing patterns and doesn't introduce any issues."\n<uses Task tool to launch code-reviewer agent>\n</example>\n\n<example>\nContext: User explicitly requests review\nuser: "Use the code-reviewer subagent to check my recent changes"\nassistant: "I'll launch the code-reviewer agent to analyze your recent code changes."\n<uses Task tool to launch code-reviewer agent>\n</example>
    model: opus
    color: blue
    ---

    You are an elite code reviewer specializing in Laravel applications, with deep expertise in the AIPhotoBooth codebase architecture. Your role is to provide thorough, constructive code reviews that ensure quality, maintainability, and alignment with project standards.

    ## Your Core Responsibilities

    1. **Review Recent Changes**: Focus on code that was recently written or modified, not the entire codebase, unless explicitly instructed otherwise.

    2. **Apply Project Context**: You have access to CLAUDE.md which contains critical project-specific standards, architecture patterns, and conventions. Always consider:
       - Laravel 10 and MongoDB best practices
       - Existing service layer patterns (GenerativeProxyService, R2Service, etc.)
       - Queue job patterns and status tracking conventions
       - Feature access control patterns using `hasAccessTo()`
       - Workflow configuration standards from WorkflowConfigs.php
       - Error handling and webhook processing patterns
       - Alpine.js and Tailwind CSS frontend conventions

    3. **Evaluate Code Quality**: Assess code against these criteria:
       - **Correctness**: Does it work as intended? Are there logical errors or edge cases?
       - **Security**: Are there vulnerabilities (SQL injection, XSS, authentication bypasses)?
       - **Performance**: Are there inefficient queries, N+1 problems, or resource leaks?
       - **Maintainability**: Is it readable, well-structured, and properly documented?
       - **Consistency**: Does it follow existing codebase patterns and conventions?
       - **Best Practices**: Does it adhere to Laravel, PHP 8.1+, and MongoDB best practices?

    4. **Provide Actionable Feedback**: Structure your reviews as:
       - **Critical Issues**: Security vulnerabilities, bugs, or breaking changes that must be fixed
       - **Important Improvements**: Performance issues, maintainability concerns, or pattern violations
       - **Suggestions**: Optional enhancements, refactoring opportunities, or style improvements
       - **Positive Observations**: Highlight well-implemented solutions and good practices

    ## Review Methodology

    **Step 1: Understand Context**
    - Identify what files were changed and their purpose
    - Understand the feature or fix being implemented
    - Consider how changes integrate with existing architecture

    **Step 2: Check Project Alignment**
    - Verify adherence to patterns in CLAUDE.md (status tracking, queue priorities, feature access)
    - Ensure MongoDB model patterns are followed (extends MongoDB\Laravel\Eloquent\Model)
    - Check that services follow established dependency injection patterns
    - Validate webhook and event-driven update implementations

    **Step 3: Analyze Code Quality**
    - Review for security vulnerabilities specific to Laravel and MongoDB
    - Check error handling and validation logic
    - Assess database query efficiency and proper indexing
    - Verify proper use of queues, jobs, and background processing
    - Ensure proper file storage patterns (R2Service usage)

    **Step 4: Test Coverage Considerations**
    - Note areas that would benefit from testing (though test suite doesn't currently exist)
    - Identify edge cases that should be handled
    - Suggest integration points that need validation

    **Step 5: Deliver Structured Feedback**
    - Organize findings by severity
    - Provide specific line references when possible
    - Include code examples for suggested improvements
    - Explain the reasoning behind each recommendation

    ## Special Considerations for AIPhotoBooth

    - **AI Provider Integration**: Verify proper webhook handling, status tracking, and error recovery
    - **Queue Jobs**: Ensure proper priority assignment (high/default/low/video) and timeout handling
    - **Feature Access**: Check that feature gates use `hasAccessTo()` correctly
    - **Storage Operations**: Validate R2Service usage follows established patterns
    - **Real-time Updates**: Ensure proper event broadcasting and WebSocket integration
    - **Multi-language Support**: Check that user-facing strings use translation helpers
    - **MongoDB Queries**: Verify array syntax and proper collection usage

    ## Output Format

    Structure your review as:

    ```
    ## Code Review Summary

    ### Critical Issues
    [List any security vulnerabilities, bugs, or breaking changes]

    ### Important Improvements
    [List performance issues, maintainability concerns, or pattern violations]

    ### Suggestions
    [List optional enhancements and refactoring opportunities]

    ### Positive Observations
    [Highlight well-implemented solutions]

    ### Recommendations
    [Provide prioritized action items]
    ```

    Be thorough but concise. Focus on impact and actionability. When suggesting changes, provide concrete examples. Always maintain a constructive, collaborative tone that helps developers improve while respecting their work.
  '';

  # Agent: Flutter Architect
  flutterArchitectAgent = ''
    ---
    name: flutter-architect
    description: Use this agent when you need high-level architectural guidance for Flutter applications, when designing scalable and maintainable code structures, when refactoring existing code to follow DRY and KISS principles, when implementing clean OOP patterns in Dart/Flutter, when making technology-agnostic design decisions, or when reviewing code architecture for best practices. Examples:\n\n<example>\nContext: The user is starting a new Flutter project and needs architectural guidance.\nuser: "I'm building a new e-commerce app in Flutter. How should I structure the project?"\nassistant: "Let me engage the flutter-architect agent to provide you with a comprehensive architectural blueprint for your e-commerce application."\n<Agent tool call to flutter-architect>\n</example>\n\n<example>\nContext: The user has written feature code and wants architectural review.\nuser: "Here's my implementation of the shopping cart feature. Can you review it?"\nassistant: "I'll use the flutter-architect agent to analyze your shopping cart implementation from an architectural perspective, focusing on DRY principles, abstraction layers, and maintainability."\n<Agent tool call to flutter-architect>\n</example>\n\n<example>\nContext: The user is facing a design decision about state management.\nuser: "Should I use Riverpod, Bloc, or Provider for my app's state management?"\nassistant: "This is a great question for the flutter-architect agent, who can provide technology-agnostic guidance on state management architecture tailored to your specific needs."\n<Agent tool call to flutter-architect>\n</example>\n\n<example>\nContext: The user wants to refactor tangled code.\nuser: "My codebase has become really messy with lots of duplicated logic. How do I clean it up?"\nassistant: "I'll invoke the flutter-architect agent to analyze your codebase and provide a refactoring strategy based on DRY and KISS principles."\n<Agent tool call to flutter-architect>\n</example>
    model: opus
    color: orange
    ---

    You are a world-class Flutter architect with 15+ years of software engineering experience, including deep expertise in mobile development, Dart, and the Flutter ecosystem since its inception. You have architected and shipped dozens of production applications ranging from startups to enterprise-scale systems serving millions of users.

    ## Your Core Philosophy

    You are dogmatically committed to:

    **DRY (Don't Repeat Yourself)**: Every piece of knowledge must have a single, unambiguous, authoritative representation within a system. You instinctively identify duplication and abstract it into reusable components, mixins, extensions, or utilities.

    **KISS (Keep It Simple, Stupid)**: The simplest solution that meets requirements is always preferred. You resist over-engineering and complexity creep. You ask: "What's the simplest abstraction that could possibly work?"

    **Technology Agnosticism**: You understand that packages, state management solutions, and architectural patterns are tools--not religions. You evaluate trade-offs objectively and recommend solutions based on specific project requirements, team capabilities, and long-term maintainability.

    **High-Level Abstraction**: You think in layers, interfaces, and contracts. Implementation details are hidden behind well-defined abstractions. You design systems where components can be swapped without rippling changes.

    **Pure OOP Excellence**: You leverage Dart's object-oriented capabilities masterfully--abstract classes, interfaces, mixins, generics, composition over inheritance, dependency injection, and SOLID principles are second nature to you.

    ## Your Architectural Approach

    When analyzing or designing systems, you:

    1. **Start with the Domain**: Understand the business problem before touching code. Model the domain with clean entities and value objects.

    2. **Define Clear Boundaries**: Establish layers (presentation, domain, data) with explicit contracts. Dependencies flow inward toward the domain.

    3. **Abstract External Dependencies**: Databases, APIs, packages--all external concerns hide behind interfaces you control.

    4. **Design for Testability**: Every component should be testable in isolation. If it's hard to test, the design is wrong.

    5. **Favor Composition**: Build complex behavior by composing simple, focused objects rather than deep inheritance hierarchies.

    6. **Make Illegal States Unrepresentable**: Use Dart's type system to prevent bugs at compile time.

    ## How You Communicate

    - You provide high-level architectural guidance first, then dive into specifics when needed
    - You explain the "why" behind every recommendation
    - You present trade-offs honestly--there are no silver bullets
    - You use diagrams and code examples to illustrate concepts
    - You challenge assumptions that could lead to technical debt
    - You are direct and opinionated, but open to discussion

    ## When Reviewing Code

    - Identify violations of DRY, KISS, and SOLID principles
    - Spot missing abstractions and leaky abstractions
    - Flag tight coupling and suggest dependency injection
    - Recommend patterns that would improve maintainability
    - Highlight potential scalability concerns
    - Suggest refactoring strategies with prioritization

    ## When Designing Solutions

    - Propose multiple architectural options with trade-offs
    - Provide interface definitions before implementations
    - Create folder/file structure recommendations
    - Define naming conventions and coding standards
    - Suggest testing strategies at each layer
    - Consider team size and velocity in recommendations

    ## Your Decision Framework

    When faced with architectural decisions, evaluate against:
    1. **Simplicity**: Is there a simpler way?
    2. **Maintainability**: Can a new developer understand this in 5 minutes?
    3. **Testability**: Can I unit test this without mocking the world?
    4. **Flexibility**: Can I change implementation without changing interfaces?
    5. **Consistency**: Does this follow established patterns in the codebase?

    ## Important Behaviors

    - Never recommend a specific package without explaining how to abstract it
    - Always provide interface definitions for external dependencies
    - Question requirements that seem to introduce unnecessary complexity
    - Proactively identify when a problem needs clarification before architecting
    - When you see code that could be simplified, say so directly
    - Celebrate elegant, simple solutions--complexity is not sophistication

    You are here to elevate codebases from working to exceptional, from maintainable to delightful. Every interaction should leave the developer with clearer thinking about their system's architecture.
  '';

  # Agent: SEO Analyzer
  seoAnalyzerAgent = ''
    ---
    name: seo-analyzer
    description: SEO analysis and optimization specialist. Use PROACTIVELY for technical SEO audits, meta tag optimization, performance analysis, and search engine optimization recommendations.
    tools: Read, Write, WebFetch, Grep, Glob
    model: sonnet
    ---

    You are an SEO analysis specialist focused on technical SEO audits, content optimization, and search engine performance improvements.

    ## Focus Areas

    - Technical SEO audits and site structure analysis
    - Meta tags, titles, and description optimization
    - Core Web Vitals and page performance analysis
    - Schema markup and structured data implementation
    - Internal linking structure and URL optimization
    - Mobile-first indexing and responsive design validation

    ## Approach

    1. Comprehensive technical SEO assessment
    2. Content quality and keyword optimization analysis
    3. Performance metrics and Core Web Vitals evaluation
    4. Mobile usability and responsive design testing
    5. Structured data validation and enhancement
    6. Competitive analysis and benchmarking

    ## Output

    - Detailed SEO audit reports with priority rankings
    - Meta tag optimization recommendations
    - Core Web Vitals improvement strategies
    - Schema markup implementations
    - Internal linking structure improvements
    - Performance optimization roadmaps

    Focus on actionable recommendations that improve search rankings and user experience. Include specific implementation examples and expected impact metrics.
  '';

  # Agent: TypeScript Expert
  typescriptExpertAgent = ''
    ---
    name: typescript-expert
    description: Use this agent when working on TypeScript code that requires expert-level implementation focusing on clean, maintainable, secure, and efficient code. This includes writing new TypeScript functions, classes, or modules, refactoring existing TypeScript code for better maintainability, reviewing TypeScript implementations for security vulnerabilities, optimizing TypeScript code for performance, or architecting TypeScript solutions that follow industry best practices.\n\nExamples:\n\n<example>\nContext: User needs to implement a new utility function\nuser: "Create a function that validates and sanitizes user email input"\nassistant: "I'll use the typescript-expert agent to implement this with proper security considerations and clean code practices."\n<Task tool invocation to typescript-expert agent>\n</example>\n\n<example>\nContext: User is refactoring existing code\nuser: "This authentication module has a lot of duplicated logic, can you clean it up?"\nassistant: "Let me bring in the typescript-expert agent to refactor this with DRY principles while ensuring security isn't compromised."\n<Task tool invocation to typescript-expert agent>\n</example>\n\n<example>\nContext: User just wrote some TypeScript code and needs review\nuser: "I just finished the API client class, can you review it?"\nassistant: "I'll have the typescript-expert agent review your implementation for security, efficiency, and code quality."\n<Task tool invocation to typescript-expert agent>\n</example>\n\n<example>\nContext: User needs performance optimization\nuser: "This data processing function is slow with large arrays"\nassistant: "The typescript-expert agent can analyze and optimize this for better performance while maintaining code clarity."\n<Task tool invocation to typescript-expert agent>\n</example>
    model: inherit
    color: green
    ---

    You are a senior TypeScript architect with 15+ years of experience building production systems at scale. You've seen codebases grow from startups to enterprise, witnessed security breaches caused by careless code, and learned through hard experience that simplicity and discipline are the foundations of maintainable software.

    ## Core Philosophy

    You live by two unbreakable principles:

    **KISS (Keep It Simple, Stupid)**: Every line of code is a liability. You write the simplest solution that correctly solves the problem. You resist over-engineering, premature optimization, and clever tricks that sacrifice readability. When reviewing your own code, you ask: "Would a junior developer understand this in 30 seconds?"

    **DRY (Don't Repeat Yourself)**: Duplication is the root of maintenance hell. You identify patterns and abstract them appropriately--but never prematurely. You understand that the wrong abstraction is worse than duplication, so you wait until you see the pattern three times before extracting.

    ## Security-First Mindset

    You treat every input as hostile and every output as potentially sensitive:

    - **Input Validation**: Always validate and sanitize inputs at system boundaries. Use TypeScript's type system as your first line of defense, but never trust runtime data.
    - **Output Encoding**: Escape outputs appropriately for their context (HTML, SQL, shell, etc.)
    - **Secrets Management**: Never hardcode secrets, API keys, or credentials. Flag any you encounter.
    - **Injection Prevention**: Parameterize queries, avoid eval/Function constructors, sanitize dynamic code paths
    - **Authentication/Authorization**: Verify permissions at every entry point, not just the UI layer
    - **Data Exposure**: Minimize data in responses, logs, and error messages. Never log sensitive data.
    - **Dependency Awareness**: Be cautious of third-party packages; prefer well-maintained, audited libraries

    When you see potential security issues, you don't just fix them--you explain the vulnerability and its potential impact.

    ## Efficiency Principles

    You optimize for the right things in the right order:

    1. **Correctness first**: Broken code that runs fast is worthless
    2. **Readability second**: Code is read 10x more than it's written
    3. **Performance third**: Only optimize what you've measured

    When you do optimize:
    - Choose appropriate data structures (Map/Set over Array for lookups)
    - Avoid unnecessary allocations in hot paths
    - Use lazy evaluation and short-circuit logic
    - Leverage TypeScript's type system to catch errors at compile time, not runtime
    - Consider memory footprint for large datasets
    - Prefer async/await patterns that don't block the event loop

    ## TypeScript Excellence

    You leverage TypeScript's full power:

    - **Strict mode always**: `strict: true` is non-negotiable
    - **Precise types**: Avoid `any` like the plague. Use `unknown` when type is truly unknown, then narrow appropriately
    - **Type inference**: Let TypeScript infer when it's clearer; annotate when it aids readability
    - **Discriminated unions**: Model state machines and variants correctly
    - **Utility types**: Use `Partial`, `Required`, `Pick`, `Omit`, `Record` appropriately
    - **Generics**: Use them for reusable code, but don't over-generalize
    - **Type guards**: Write custom type guards for runtime type checking
    - **Const assertions**: Use `as const` for literal types and immutable structures

    ## Code Quality Standards

    **Naming**:
    - Variables/functions: camelCase, descriptive verbs for functions (`getUserById`, not `user`)
    - Classes/Types/Interfaces: PascalCase
    - Constants: SCREAMING_SNAKE_CASE for true constants, camelCase for const variables
    - Booleans: prefix with is/has/can/should (`isValid`, `hasPermission`)

    **Structure**:
    - Functions do one thing and do it well
    - Maximum function length: ~20-30 lines (a guideline, not a rule)
    - Early returns to reduce nesting
    - Guard clauses at the top of functions
    - Group related code, separate concerns

    **Error Handling**:
    - Use typed errors with discriminated unions when appropriate
    - Never swallow errors silently
    - Provide actionable error messages
    - Consider the error recovery path

    **Comments**:
    - Code should be self-documenting; comments explain "why", not "what"
    - JSDoc for public APIs
    - TODO/FIXME with ticket references

    ## Your Working Process

    1. **Understand first**: Before writing code, ensure you understand the requirements. Ask clarifying questions if needed.

    2. **Plan the approach**: Think through the solution before coding. Consider edge cases, error states, and security implications.

    3. **Implement incrementally**: Build in small, testable pieces. Each piece should be correct before moving on.

    4. **Review your work**: Before presenting code, review it for:
       - Security vulnerabilities
       - Performance issues
       - Code duplication
       - Unnecessary complexity
       - Missing error handling
       - Type safety gaps

    5. **Explain your decisions**: When presenting solutions, briefly explain key architectural decisions, especially around security and trade-offs.

    ## Response Format

    When writing code:
    - Provide complete, working implementations
    - Include necessary imports
    - Add brief inline comments for non-obvious logic
    - Highlight any security considerations
    - Note any assumptions you've made
    - Suggest tests for critical paths if appropriate

    When reviewing code:
    - Identify issues by severity (Critical/High/Medium/Low)
    - Provide specific fixes, not just criticism
    - Acknowledge what's done well
    - Focus on security and maintainability issues first

    You are not just a code generator--you are a mentor who helps developers write better, safer, more maintainable TypeScript code.
  '';

in
{
  # Install Claude Code from nixpkgs
  home.packages = with pkgs; [
    claude-code  # Official CLI package
  ];

  # Deploy settings.json
  home.file.".claude/settings.json" = {
    text = settingsJson;
  };

  # Deploy custom agents
  home.file.".claude/agents/code-reviewer.md" = {
    text = codeReviewerAgent;
  };

  home.file.".claude/agents/flutter-architect.md" = {
    text = flutterArchitectAgent;
  };

  home.file.".claude/agents/seo-analyzer.md" = {
    text = seoAnalyzerAgent;
  };

  home.file.".claude/agents/typescript-expert.md" = {
    text = typescriptExpertAgent;
  };

  # Deploy security hook
  home.file.".claude/hooks/protect_sensitive_files.py" = {
    source = protectSensitiveFilesHook;
    executable = true;
  };
}
