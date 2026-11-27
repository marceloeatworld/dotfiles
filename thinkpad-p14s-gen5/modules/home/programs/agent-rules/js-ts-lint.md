## JavaScript and TypeScript Linting

My standard linter for JavaScript and TypeScript is Oxlint with the `@cloudflare/oxlint-config` preset. Apply it without being asked whenever a task writes or changes JavaScript or TypeScript code:

- The project already uses the preset: run its lint command after your changes and fix every finding in the code you touched. Never disable a rule or lower its severity to make lint pass.
- New project, or a project of mine that has a `package.json` and no linter: add the preset as part of the task. Install `@cloudflare/oxlint-config` with the project's package manager, then follow `node_modules/@cloudflare/oxlint-config/README.md` for the peer packages, the config file and the lint script (Vite+ projects use the `vite-plus` entry). In an existing codebase, turn off the rules that fail on old code instead of rewriting that code, and tell me which rules are off.
- The project uses another linter or preset (ESLint, Biome, a different Oxlint config): keep it and follow it. Migrate only when I ask, with the `migrate-oxlint-config` skill.
- Never add the preset to a repository that is not mine: a dependency, a clone I am only reading, or an upstream project I contribute to.
