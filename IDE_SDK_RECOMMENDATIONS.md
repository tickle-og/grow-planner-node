# Recommended SDK & IDE Setup for AI-Assisted Development with Amp

## TL;DR - Quick Answer

**Primary IDE:** VS Code with AI extensions  
**Secondary IDE:** JetBrains WebStorm (if budget allows)  
**SDK:** Node.js 22 LTS + pnpm (already have both)  
**Best Workflow:** VS Code + Amp Agent + Terminal

---

## Primary Recommendation: Visual Studio Code

### Why VS Code is Best for Working with Amp

1. **AI Integration Ecosystem**
   - Native Copilot support (can use alongside Amp)
   - Multiple AI extension marketplaces
   - Works seamlessly with Amp's code suggestions
   - Easy to apply diffs and changes from AI

2. **Lightweight & Fast**
   - Loads instantly
   - Minimal resource overhead
   - Perfect for rapid iteration
   - Allows AI to focus on code logic, not IDE overhead

3. **Excellent TypeScript Support**
   - Built-in TS language server
   - Real-time error detection
   - Type checking as you code
   - Perfect for strict-mode SvelteKit project

4. **Svelte/SvelteKit Native Support**
   - Svelte for VS Code extension available
   - Excellent syntax highlighting
   - Component navigation
   - HMR (Hot Module Reload) integration

5. **Git Integration Built-in**
   - Source Control panel
   - Diff viewing (critical for reviewing AI changes)
   - Staging/committing without leaving IDE
   - Branch management

6. **Perfect for Amp Workflow**
   - Easy to open multiple files referenced in conversations
   - Can quickly navigate to errors Amp identifies
   - Terminal integrated (run tests, typecheck, etc.)
   - Problem panel shows TypeScript/ESLint errors in real-time

### VS Code Configuration for Your Project

**Recommended Extensions:**

```json
// Extensions to install (Ctrl+Shift+X)
1. Svelte for VS Code (official)
   - ID: svelte.svelte-vscode
   - Language support for Svelte components
   - Essential for SvelteKit development

2. TypeScript Vue Plugin (Volar)
   - ID: Vue.volar
   - Alternative TS support for SvelteKit
   - Better type checking in .svelte files

3. Drizzle ORM
   - ID: drizzle.drizzle-studio
   - Query builder autocomplete
   - Database schema visualization

4. ESLint
   - ID: dbaeumer.vscode-eslint
   - Real-time linting feedback
   - Auto-fix on save

5. Prettier - Code formatter
   - ID: esbenp.prettier-vscode
   - Auto-format on save
   - Consistent code style

6. Git Graph
   - ID: mhutchie.git-graph
   - Visual git history
   - Helpful for tracking changes from AI suggestions

7. REST Client (optional)
   - ID: humao.rest-client
   - Test API endpoints without Postman
   - Good for testing /api/* routes

8. Thunder Client (optional)
   - ID: rangav.vscode-thunder-client
   - Lightweight HTTP client
   - Alternative to Postman

9. Error Lens
   - ID: usernamehw.errorlens
   - Inline error display
   - Catch issues instantly

10. Better Comments
    - ID: aaron-bond.better-comments
    - Highlight TODO, BUG, HACK comments
    - Helps track incomplete work Amp identifies

11. Database Clients (optional)
    - ID: cweijan.vscode-database-client2
    - Browse SQLite database
    - Verify Amp's changes to database

12. Github Copilot (optional, complements Amp)
    - ID: GitHub.copilot
    - Can use alongside Amp for quick suggestions
    - Good for boilerplate code

13. Postman (optional)
    - ID: Postman.postman-for-vscode
    - Full API testing capabilities
```

**VS Code Settings (`.vscode/settings.json`):**

```json
{
  // TypeScript
  "typescript.tsdk": "node_modules/typescript/lib",
  "typescript.enablePromptUseWorkspaceTsdk": true,
  "typescript.preferences.autoImportFileExcludePatterns": ["**/node_modules/**"],
  
  // Formatting
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.fixAll.eslint": "explicit"
    }
  },
  "[svelte]": {
    "editor.defaultFormatter": "svelte.svelte-vscode",
    "editor.formatOnSave": true
  },
  "[json]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },
  
  // Editor behavior
  "editor.wordWrap": "on",
  "editor.lineNumbers": "on",
  "editor.rulers": [100, 120],
  "editor.tabSize": 2,
  "editor.insertSpaces": true,
  "files.trimTrailingWhitespace": true,
  
  // Search & exclude
  "search.exclude": {
    "**/node_modules": true,
    "**/.svelte-kit": true,
    "**/dist": true,
    "**/build": true
  },
  "files.exclude": {
    "**/node_modules": true,
    "**/.svelte-kit": true,
    "**/*.bak.*": true
  },
  
  // Svelte
  "svelte.enable-ts-plugin": true,
  
  // Styling
  "editor.theme": "One Dark Pro" // or your preference
}
```

**VS Code Keybindings for Amp Workflow:**

```json
// Add to keybindings.json
[
  {
    "key": "ctrl+shift+p",
    "command": "workbench.action.quickOpen",
    "when": "!inputFocus"
  },
  {
    "key": "ctrl+l",
    "command": "editor.action.selectCurrentLine"
  },
  {
    "key": "ctrl+k ctrl+t",
    "command": "workbench.action.terminal.toggleTerminal"
  },
  {
    "key": "ctrl+shift+d",
    "command": "workbench.view.debug"
  }
]
```

---

## Secondary Recommendation: JetBrains WebStorm

### Why Consider WebStorm

**Pros:**
- More intelligent code analysis than VS Code
- Better refactoring tools
- Superior TypeScript support
- Integrated debugging
- Better for large codebases
- Excellent SvelteKit plugin support

**Cons:**
- Costs $15/month or $150/year (VS Code is free)
- Heavier IDE (slower startup)
- Overkill for this project size
- IDE overhead reduces AI efficiency

### When to Choose WebStorm
- If working with large teams
- If you need advanced refactoring
- If your company has licenses
- For complex debugging scenarios

### WebStorm Extensions for Amp
- Copilot (GitHub.copilot equivalent)
- Rest Client plugin (built-in)
- Database Tools & SQL (excellent for SQLite)
- BashSupport Pro (for shell scripts)

---

## Alternative IDEs (Not Recommended)

### Sublime Text
**Pros:** Fast, lightweight  
**Cons:** Limited AI integration, weak TypeScript support  
**Best For:** Text editing, not primary development  

### Vim/Neovim
**Pros:** Powerful for experts, lightweight  
**Cons:** Steep learning curve, hard to review AI changes visually  
**Best For:** Server-side development, not collaborative AI work  

### Cursor (Built on VS Code)
**Pros:** Cursor IDE has native AI integration (Copilot-like)  
**Cons:** Different from VS Code, learning curve  
**Best For:** If you want AI baked into IDE (alternative to Amp)  

### GitHub Codespaces
**Pros:** Browser-based, cloud development, no setup  
**Cons:** Needs internet, can be slower, limited offline capability  
**Best For:** Quick cloud development, pair programming  

---

## SDK Setup (Node.js + Tools)

### Current Setup (Already Good)
```
✅ Node.js 22 LTS (implied from package.json)
✅ pnpm (faster than npm, good choice)
✅ TypeScript 5.9.2
✅ Vite 7.1.7 (excellent bundler)
✅ Vitest 2.1.9 (testing)
✅ SvelteKit 2.43.2 (framework)
```

### Recommended Global Tools
```bash
# Install these globally for maximum efficiency
npm install -g \
  pnpm@latest \
  typescript@latest \
  tsx \
  @types/node@latest \
  drizzle-kit \
  vite
```

### Node.js Version Check
```bash
node --version  # Should be v20.x or v22.x
npm --version   # Comes with Node
pnpm --version  # v9.x or later
```

### Verify Development Setup
```bash
cd /home/tickle/grow-planner-node
pnpm --version
node --version
pnpm list typescript
pnpm list svelte
```

---

## Best Workflow for Working with Amp

### Recommended Process

1. **Open Project in VS Code**
   ```bash
   cd /home/tickle/grow-planner-node
   code .
   ```

2. **Open Terminal in VS Code** (Ctrl+`)
   ```bash
   pnpm install  # if first time
   pnpm run dev  # start dev server
   ```

3. **Keep These Tabs Open**
   - Terminal running `pnpm run dev` (watches for changes)
   - File explorer on left
   - Problem panel at bottom (shows errors)
   - Git panel for commit tracking

4. **When Working with Amp**
   - Ask Amp to fix specific files
   - Copy suggested code into VS Code
   - Let ESLint/Prettier auto-format (saves time)
   - Run `pnpm run typecheck` to verify
   - Review git diffs before committing

5. **Rapid Iteration Loop**
   ```
   Ask Amp → Get Suggestion → Paste in VS Code → Save 
   → TypeScript checks → Review → Commit → Ask next question
   ```

### Keyboard Shortcuts to Master

| Action | Shortcut |
|--------|----------|
| Open file | Ctrl+P |
| Go to definition | F12 or Ctrl+Click |
| Find all references | Shift+F12 |
| Rename symbol | F2 |
| Format document | Shift+Alt+F |
| Toggle sidebar | Ctrl+B |
| Toggle terminal | Ctrl+` |
| Quick fix/actions | Ctrl+. |
| Go to line | Ctrl+G |
| Comment line | Ctrl+/ |
| Search all files | Ctrl+Shift+F |
| Open git diff | Ctrl+Shift+G |

---

## Commands to Keep Handy

### For Testing Changes
```bash
# Type-check
pnpm run typecheck

# Lint & format check
pnpm run lint

# Auto-fix formatting
pnpm run format

# Run tests
pnpm run test

# Watch tests
pnpm run test:watch

# Build for production
pnpm run build

# Preview build
pnpm run preview

# Database operations
pnpm drizzle:generate   # Generate migration
pnpm drizzle:migrate    # Run migrations
pnpm drizzle:studio     # GUI database browser
```

### Terminal Shortcuts in VS Code
```bash
# Create new terminal tab
Ctrl+Shift+`

# Kill terminal
Ctrl+Shift+X

# Switch between terminals
Ctrl+PageUp / Ctrl+PageDown
```

---

## Development Workflow Diagram

```
┌─────────────────────────────────────────┐
│         VS Code + Amp Integration       │
├─────────────────────────────────────────┤
│                                         │
│  1. Ask Amp in Browser/Chat             │
│     ↓                                   │
│  2. Get Code Suggestion                 │
│     ↓                                   │
│  3. Paste into VS Code Editor           │
│     ↓                                   │
│  4. ESLint + Prettier Auto-Fix          │
│     ↓                                   │
│  5. TypeScript Real-Time Check          │
│     ↓                                   │
│  6. HMR Reloads Dev Server (auto)       │
│     ↓                                   │
│  7. See Changes in Browser              │
│     ↓                                   │
│  8. Run `pnpm run test` to Verify       │
│     ↓                                   │
│  9. Review Git Diff                     │
│     ↓                                   │
│  10. Commit & Ask Next Question         │
│                                         │
└─────────────────────────────────────────┘
```

---

## Expected Developer Experience

### Before (Without Setup)
- Manually editing files in text editor
- Running commands separately
- Hunting for errors in console output
- Manual formatting
- Slow iteration

### After (With Recommended Setup)
```
Time to implement Amp suggestion: ~30 seconds
  - Paste code (5s)
  - Save file (1s)
  - Auto-format (2s)
  - See errors in panel (5s)
  - TypeScript verification (5s)
  - Test in browser via HMR (10s)
  - Commit (2s)

Ready for next question: ~1 minute total
```

---

## Troubleshooting Common Issues

### TypeScript Errors Not Showing
```
VS Code → Command Palette (Ctrl+Shift+P) → "TypeScript: Restart TS Server"
```

### Formatting Not Working
```
Check: settings.json has formatOnSave enabled
Check: Prettier installed (pnpm list prettier)
Run: pnpm run format manually
```

### Svelte Not Recognized
```
Install: Svelte for VS Code extension
Run: npm install -D svelte-check
Check: tsconfig.json includes svelte-kit/tsconfig.json
```

### HMR Not Working
```
Check: pnpm run dev is running
Check: Browser console for errors
Restart dev server: Ctrl+C then pnpm run dev
```

### Git Changes Not Showing
```
VS Code → Source Control (Ctrl+Shift+G)
Run: git status in terminal to verify
Refresh: Click refresh icon in Source Control panel
```

---

## Summary Table

| Aspect | Recommendation | Reason |
|--------|-----------------|--------|
| **IDE** | VS Code | Free, AI-friendly, TypeScript support, Svelte native |
| **SDK** | Node.js 22 + pnpm | Already using, optimal for this stack |
| **Runtime** | pnpm | Fast, good hoisting, already configured |
| **Database GUI** | drizzle-kit studio | Built-in, no extra tools needed |
| **Testing** | Vitest (built-in) | Already configured, single-threaded for SQLite |
| **Source Control** | Git in VS Code | Integrated, easy diff review |
| **API Testing** | REST Client extension | Lightweight, in-IDE testing |
| **Budget** | $0 | Everything free (VS Code + extensions) |
| **Learning Curve** | Low | VS Code is industry standard |
| **AI Collaboration** | Excellent | Best workflow for Amp + human developer |

---

## Final Recommendation

**Setup:** VS Code + the recommended extensions  
**Cost:** $0  
**Time to Setup:** 15 minutes  
**Efficiency Gain:** 3-5x faster iteration with Amp  
**Best For:** This project and most Node.js development

**Commands to Start Now:**
```bash
# Install VS Code extensions
code --install-extension svelte.svelte-vscode
code --install-extension esbenp.prettier-vscode
code --install-extension dbaeumer.vscode-eslint

# Start development
cd /home/tickle/grow-planner-node
code .
pnpm run dev
```

That's it. You're ready to work efficiently with Amp.
