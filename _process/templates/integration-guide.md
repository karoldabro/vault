---
type: integration-guide
status: stub
tags: [integration, api, cross-project]
source_project: "<!-- project slug -->"
feature_slug: "<!-- kebab-case slug -->"
generated: "<!-- YYYY-MM-DD -->"
---

# [Feature Name] — Integration Guide

> Source project: `<!-- slug -->` | Feature: `<!-- slug -->` | Generated: `<!-- YYYY-MM-DD -->`
>
> This document describes the **external contract** — what other projects need to know to integrate this feature. No implementation details. No framework-specific code.

---

## Overview

<!-- 2–5 sentences: what this feature does, who uses it, what problem it solves. No "how it works internally". -->

---

## Data Flow

<!-- Prose or ASCII diagram showing the end-to-end sequence: who calls what, in what order, what flows back. -->

```
Client → POST /api/v1/<resource>
       ← 201 { id, status, ... }

Client → GET /api/v1/<resource>?filter=...
       ← 200 { data: [...], meta: { total, page, per_page } }
```

---

## Enums & Constants

<!-- One table per enum. Include every value the API can emit or accept. -->

### `<EnumName>`

| Value | Meaning |
|-------|---------|
| `value_a` | Description |
| `value_b` | Description |

---

## Data Structures

<!-- One subsection per entity. Use JSON shape notation — no types, no classes. Just the keys and their meaning. -->

### `<ResourceName>`

```json
{
  "id": "uuid",
  "status": "<EnumName>",
  "created_at": "ISO 8601",
  "updated_at": "ISO 8601"
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | uuid | yes | |
| `status` | `<EnumName>` | yes | See Enums above |
| `created_at` | ISO 8601 | yes | UTC |

---

## API Endpoints

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| `POST` | `/api/v1/<resource>` | Create | Bearer token |
| `GET` | `/api/v1/<resource>` | List (paginated) | Bearer token |
| `GET` | `/api/v1/<resource>/{id}` | Fetch single | Bearer token |
| `PATCH` | `/api/v1/<resource>/{id}` | Update | Bearer token |
| `DELETE` | `/api/v1/<resource>/{id}` | Delete | Bearer token |

Base URL: `$API_BASE_URL` (env var)

---

## Request & Response Shapes

<!-- One subsection per non-trivial endpoint. Skip CRUD-obvious ones if the data structure above covers it. -->

### `POST /api/v1/<resource>`

**Request body:**
```json
{
  "field_a": "string",
  "field_b": 0
}
```

**Response `201`:**
```json
{
  "data": { /* <ResourceName> */ }
}
```

**Error responses:**

| Status | Code | When |
|--------|------|------|
| `422` | `validation_error` | Invalid input |
| `409` | `already_exists` | Duplicate |

---

### `GET /api/v1/<resource>`

**Query params:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `page` | int | 1 | Page number |
| `per_page` | int | 15 | Max 100 |
| (see Filtering below) | | | |

**Response `200`:**
```json
{
  "data": [ /* <ResourceName>[] */ ],
  "meta": {
    "total": 0,
    "per_page": 15,
    "current_page": 1,
    "last_page": 1
  }
}
```

---

## Filtering & Pagination

<!-- Document every supported filter param. Be explicit — "not supported" is also valid. -->

| Param | Operator | Example | Notes |
|-------|----------|---------|-------|
| `filter[status]` | eq | `?filter[status]=active` | |
| `filter[created_at]` | range | `?filter[created_at][from]=2024-01-01` | ISO 8601 |
| `sort` | field name | `?sort=-created_at` | Prefix `-` = descending |

---

## Integration Checklist

Use this before marking the integration done in your project:

- [ ] `$API_BASE_URL` env var configured
- [ ] Bearer token auth wired to all requests
- [ ] All enum values handled (including future-unknown values)
- [ ] Pagination loop implemented (don't assume single-page responses)
- [ ] All documented error codes handled gracefully
- [ ] `422` validation errors surfaced to the user
- [ ] Retry / timeout strategy defined for network errors

---

## Changelog

| Date | Change |
|------|--------|
| `<!-- YYYY-MM-DD -->` | Initial guide |
