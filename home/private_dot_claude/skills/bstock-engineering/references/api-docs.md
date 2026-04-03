# Microservice API Documentation

## Standard Convention

All B-Stock 3MP microservices following the `@b-stock/SERVICE_NAME-api-client` naming convention have `swagger.json` documentation in their GitLab repositories.

| Component | Pattern |
|-----------|---------|
| API client package | `@b-stock/SERVICE_NAME-api-client` |
| GitLab repository | `b-stock/code/three-mp/svc/SERVICE_NAME` |
| Swagger file path | `swagger.json` at repository root |
| Branch | `main` |

## Retrieving Swagger Documentation

Use cached project IDs from `references/project-ids.md` when available:

```javascript
mcp__gitlab__get_file_contents({
  project_id: "PROJECT_ID_FROM_CACHE",
  file_path: "swagger.json",
  ref: "main"
})
```

If the service is not in the cache:

1. Search for the repository:
   ```javascript
   mcp__gitlab__search_repositories({ search: "SERVICE_NAME" })
   ```
2. Extract the `project_id` from results
3. Add the new project_id to `references/project-ids.md` for future use
4. Retrieve swagger using the project_id

## Naming Convention Exceptions

| Service | Exception |
|---------|-----------|
| `ingestion` | Uses `ingestion-nestjs` (ID: `661`) as the active service. `ingestion-old` is archived. |
| `saved-search` | Uses the 3MP version (ID: `798`) at `b-stock/code/three-mp/svc/saved-search`, NOT the legacy version at `b-stock/code/svc/saved-search` |
| `payments-methods` | Located at `b-stock/code/three-mp/svc/payments/methods` (nested path) |
| `payments-transactions` | Located at `b-stock/code/three-mp/svc/payments/transactions` (nested path) |

All services use the same `swagger.json` at repository root regardless of these path variations.

## Full Service Project ID Table

See `references/project-ids.md` for the complete mapping of all 19 service names to GitLab project IDs.
