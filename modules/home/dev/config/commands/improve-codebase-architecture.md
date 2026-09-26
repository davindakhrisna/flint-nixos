---
description: Scan codebase for deepening opportunities, present a visual HTML report, and grill through candidate refactors.
---

You are executing the `/improve-codebase-architecture` command. Follow the `improve-codebase-architecture` skill instructions.

Target area / module / pain point: $1
Directives: $@[2]

Workflow:
1. Explore the codebase using the `codebase-design` vocabulary (module, interface, depth, seam, adapter, leverage, locality).
2. Identify hot spots and apply the deletion test to spot shallow modules and leaked seams.
3. Generate a self-contained visual HTML report in the OS temp directory with Tailwind and Mermaid before/after diagrams.
4. Open the report for the user and prompt them to select which candidate to grill through.
5. Walk through the decision tree with the user to plan the deepened architecture.
