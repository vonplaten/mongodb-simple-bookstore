# mongodb-simple-bookstore

## Environment
- indata: DB is populated with json data through sh script "setup-database.sh". Also two users are created.
- outdata: bosondump, mongodump located in ./out
- JSON files are located in ./collections
- Docker container: mongo:debian:jessie-slim

## Collections
books, authors, category, publisher
books has reference to authors, category, publisher and embedded document for publishedDate

## Hierarchy
All - Category - Details
For showing details, query is done with the aggregation pipeline:
- match (filter one book)
- 3 lookup (multiple joins)
- project (pick field to return)