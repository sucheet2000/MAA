# API Design Standards

**Version:** 1.0.0
**Last updated:** 2026-03-05
**Domain:** API Design
**Status:** Approved
**Origin:** seed
**Sources:** none

---

## 1. API Specification

- All HTTP APIs must have an OpenAPI 3.x specification committed to the repository
- The spec is the source of truth for the API contract — it must be kept in sync with the implementation
- Swagger 2.x specs should be migrated to OpenAPI 3.x for new development
- The spec must include an `info` block with `title`, `version`, and `description`
- The spec file should live at a predictable location: `openapi.yaml` at the repo root, or `api/openapi.yaml` or `docs/openapi.yaml`

## 2. Versioning

- Version APIs from day one — retrofitting versioning is expensive
- Use URL path versioning: `/v1/users`, `/v2/orders` — it is explicit, cacheable, and visible in logs
- Increment the major version (`v2`) only for breaking changes; communicate this in a changelog
- The API version must appear in the spec `info.version` field and in the URL paths
- Do not use request headers (`Accept: application/vnd.api+json;version=2`) as the primary versioning mechanism — it is invisible in URLs and harder to route

## 3. Resource Naming

- Use nouns for resources, not verbs: `/users` not `/getUsers`, `/orders` not `/createOrder`
- Use plural nouns for collections: `/users`, `/products`, `/invoices`
- Use lowercase and kebab-case: `/payment-methods`, not `/paymentMethods` or `/PaymentMethods`
- Nest resources to express ownership, but limit nesting depth: `/users/{id}/orders` is fine; `/users/{id}/orders/{orderId}/items/{itemId}/reviews` is too deep — flatten it
- Avoid actions in paths; use HTTP verbs instead: `DELETE /sessions/{id}` not `POST /logout`

## 4. HTTP Methods and Status Codes

- Use HTTP verbs correctly:
  - `GET` — retrieve; must be idempotent and safe (no side effects)
  - `POST` — create a new resource or trigger an action
  - `PUT` — replace a resource entirely
  - `PATCH` — partial update
  - `DELETE` — remove a resource
- Use correct status codes:
  - `200 OK` — successful GET, PUT, PATCH
  - `201 Created` — successful POST that creates a resource; include a `Location` header
  - `204 No Content` — successful DELETE or action with no response body
  - `400 Bad Request` — invalid input; include a clear error body
  - `401 Unauthorized` — not authenticated
  - `403 Forbidden` — authenticated but not authorized
  - `404 Not Found` — resource does not exist
  - `409 Conflict` — state conflict (duplicate, optimistic lock failure)
  - `422 Unprocessable Entity` — input is well-formed but semantically invalid
  - `500 Internal Server Error` — unexpected server fault
- Never return `200 OK` with an error body — use the appropriate 4xx or 5xx code

## 5. Request and Response Shapes

- Be consistent across all endpoints — success and error responses follow the same envelope if one is used
- Never return raw database objects: map to a response schema, omit internal fields
- For collection endpoints, always return an object with a named array key (`{ "users": [...] }`), not a bare array — bare arrays cannot be extended without breaking clients
- Use `null` for absent optional fields, not absent keys — absent keys are harder to handle in typed clients
- Prefer flat response shapes over deeply nested ones for the top-level resource

## 6. Error Responses

- All error responses must follow a consistent format across the entire API:
  ```
  { "error": { "code": "INVALID_INPUT", "message": "...", "details": [...] } }
  ```
- `code` — machine-readable string constant, stable across versions
- `message` — human-readable description for developers, not end users
- `details` — optional array for field-level validation errors
- Never expose stack traces, internal error messages, or database errors in API responses
- Error codes must be documented in the spec — clients should be able to handle them programmatically

## 7. Documentation

- Every endpoint must have a `description` (not just a `summary`) explaining what it does, its side effects, and any preconditions
- Every request parameter and body field must have a `description`
- Every response schema field must have a `description`
- Use `example` or `examples` on request bodies and responses — concrete examples are more useful than schema definitions alone
- Document error responses explicitly for each endpoint — do not assume clients will guess at possible error codes

## 8. Reusable Schemas

- Define shared types in `components/schemas` and reference them with `$ref` — do not duplicate schema definitions across endpoints
- Common types to always define as components: pagination envelopes, error response shape, timestamps, identifiers
- Component names should be PascalCase: `UserResponse`, `ErrorResponse`, `PaginatedList`
- Avoid `additionalProperties: true` on response schemas — it signals that the shape is not fully specified

## 9. Authentication

- Document all auth schemes in `components/securitySchemes`
- Declare security requirements on each endpoint explicitly — do not rely on a blanket global security setting without also noting exceptions
- Never include credentials, tokens, or secrets as example values in the spec — use placeholder strings: `"YOUR_API_KEY"`, `"Bearer <token>"`
- Document which endpoints are public (no auth required) explicitly using `security: []`

## 10. Pagination and Filtering

- All collection endpoints that may return more than a handful of results must support pagination
- Use cursor-based pagination for large or frequently-updated datasets; use offset/limit for simple admin use cases
- Pagination parameters must be documented in the spec with defaults and maximum values
- Filtering parameters should use consistent naming: `?status=active`, `?created_after=2024-01-01`
- Sorting parameters: `?sort=created_at&order=desc` — document supported sort fields

---

## Changelog

| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-03-05 | Initial version — HTTP/REST and OpenAPI scope |
