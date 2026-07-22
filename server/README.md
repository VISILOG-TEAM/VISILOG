# VisiLog API

A single Spring Boot service (Java 21, Spring Boot 3, PostgreSQL, Flyway, JWT auth) backing the
`visipro` app. Replaces the frontend's mock in-memory data (`src/data/mockData.js`,
`src/context/DataContext.js`, `src/context/AuthContext.js`) with a real, persisted, multi-tenant
backend.

## The self-serve onboarding story

This is the core of how the app actually works as a product:

1. A company signs itself up — `POST /api/v1/companies/register` creates an `Organization`, a
   unique **company code**, and the first Administrator account, in one call. No manual/internal
   tooling needed.
2. The Administrator logs in and builds their **staff roster** (`POST/GET/PATCH/DELETE
   /api/v1/employees`) — each entry has a name, an employee code, and a **role**
   (`employee` / `receptionist` / `manager`).
3. The company hands out its company code (website, offer letters, etc.). Anyone can sign up with
   that code + their own email (`POST /api/v1/auth/signup`) — if their email matches a roster
   entry, they get that role automatically; if it doesn't, they become a `visitor`. **There is no
   free role-picker anywhere in this flow** — role is decided once, automatically, at signup.
4. From then on, `POST /api/v1/auth/login` just verifies the password and hands back a token with
   that already-fixed role.

## Running locally

Requires Java 21, Maven, and a local PostgreSQL instance.

```bash
# one-time: create the database
psql -U postgres -c "CREATE ROLE visipro WITH LOGIN PASSWORD 'visipro';"
psql -U postgres -c "CREATE DATABASE visipro OWNER visipro;"

# run (Flyway migrates the schema automatically on startup)
DB_URL=jdbc:postgresql://localhost:5432/visipro DB_USER=visipro DB_PASSWORD=visipro \
  mvn spring-boot:run
```

The app listens on `:8080`. Override `PORT`, `DB_URL`, `DB_USER`, `DB_PASSWORD`, `JWT_SECRET` via
environment variables (see `application.yml`) — defaults are dev-only and print a clear name
(`dev-only-secret-key-...`) so they're never mistaken for something safe to ship.

## Tests

```bash
mvn test
```

Runs Mockito-based unit tests for the core business rules (role resolution at signup, the
once-per-day clock-in limit, plan switching) plus a full `MockMvc` integration test
(`OnboardingFlowIntegrationTest`) against an in-memory H2 database that drives the entire
onboarding story end-to-end: register a company → add staff with roles → sign up matching/
non-matching emails → confirm the resolved roles → log back in → confirm a non-manager can't touch
the roster → confirm bad company codes and missing tokens are rejected.

## Architecture notes

- **One monolith, not microservices.** An earlier, abandoned attempt (see git history, branch
  `phase1-microservices-backend`) split this into three separate services with duplicated JWT
  logic and no shared library. This app has no real scale need for that — one well-layered service
  (`controller` → `service` → `repository`, DTOs, a global exception handler, JWT auth with
  role-based `@PreAuthorize`) is simpler to build, run, and reason about.
- **Every tenant-scoped table carries `organization_id`**, and every query is scoped to the
  caller's own org from their JWT — never trusted from the client. `EmployeeRepository`,
  `VisitorRepository`, etc. all take `organizationId` as their first parameter.
- **WiFi/GPS checks stay client-side.** An HTTP request can't verify which WiFi network a phone is
  on or its real-time GPS position — those checks live in the frontend
  (`src/data/wifiCheck.js`, `src/data/locationCheck.js`) before it ever calls `/clock-records/in`.
  What the backend *can* enforce reliably, and does, is one clock-in per employee per calendar day.
- **Flyway migrations** (`src/main/resources/db/migration/`) own the schema — Hibernate is set to
  `ddl-auto: validate`, not `update`, so the entities and the migrations are always checked against
  each other rather than one silently drifting from the other.

## Not in this pass

- The frontend still runs on mock data — wiring `DataContext`/`AuthContext` to call this API (with
  token storage, loading/error states, and new "Company Setup" screens for the admin flows above)
  is a deliberately separate follow-up, since it touches nearly every screen in the app.
- "Continue with Google" stays a frontend-only demo placeholder — no OAuth2 provider is wired up.
- No file upload for company logos yet — `Organization.logoUrl` is a plain text URL field.
