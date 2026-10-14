# SDD ledger — plan: /Users/novellig/docker_images/retebio_local/retebio_5x/docs/superpowers/plans/2026-10-04-spree5-upgrade-implementation.md

Pre-flight: no shared interfaces conflict
Ruling: Target directory is /Users/novellig/docker_images/retebio_local/retebio_5x as explicitly mandated by user.
Ruling: Pre-migration sanitization marks 20250210131720..20250210131725 as already migrated because spree_users.spree_api_key and doorkeeper tables already exist in Spree 4.3 production dump schema — cost if wrong: none, those migrations only attempted to add/rename existing fields.
Ruling: Forced test environment (ENV['RAILS_ENV'] = 'test') in spec_helper to prevent test truncation of development database.
Ruling: PostgreSQL DROP DATABASE uses WITH (FORCE) to terminate active server connections cleanly on scripted reset.
Ruling: ruby-vips in Rails 8 requires British spelling 'centre' for gravity in resize_and_pad variants; Spree ImageMethods decorated to enforce 'centre'.
Ruling: Image URLs in production/cloud must enforce HTTPS to prevent browser Mixed Content Blocking when Storefront is served over SSL.
Ruling: Product publication is strictly defined by available_on activation date; ProductDecorator restores available_on <= Time.current filtering.
Ruling: Boundary views (listinoaccess and ordiniaccess) committed as a formal Rails migration (20261005080000) ensuring idempotency across environments.
Ruling: Source Control Mandate: User handles all git commits and git pushes personally; AI agent prepares workspace and configurations without running git commit/push.

Task 1: complete (Docker environment initialized in retebio_5x, containers retebio_postgres, retebio_redis, retebio_backend UP on retebio_net)
Task 2: complete (scripts/db_restore_and_migrate.sh executed successfully on dump_prod_241006.sql, migrations applied cleanly, Rails 8 / Spree 5.1 /up responds 200 OK)
Task 3: complete (bin/verify_data_integrity.rb passed: 223 users, 12,639 orders, 170,419 line items, 2,565 products, 0 errors)
Task 4: complete (bin/verify_catalog_media.rb verified 1,351 assets, 13,107 blobs, 1,346 products with images; Active Storage URL proxy generation tested; Spree Admin login HTTP 200 OK)
Task 5: complete (b2b_pricing_spec.rb: 3/3 passed RED->GREEN; anonymous prices hidden, authenticated prices visible, anonymous cart blocked with 401)
Task 6: complete (line_item_weight_spec.rb and variant_serializer_spec.rb: 3/3 passed RED->GREEN; weight step validation on LineItem and API attributes verified)
Task 7: complete (rack-cors configured, CORS preflight 200 OK, vue-storefront-spree container started and listening on port 3000, connected to backend on retebio_net, /api/v2/storefront/products returning 1,266 products with B2B gated prices)
Task 8: complete (End-to-end repeatable restore executed cleanly from scratch; data integrity verified 100%; media validation verified; RSpec suite 6/6 green; spree_43 untouched and clean)
Task 9: complete (Vue Storefront frontend customization: Italian localization it.js, EUR currency, Retebio branding, HeaderNavigation directly linked to Categoria taxons, B2B price gating on PLP and PDP with login prompt, weight stepping in quantity selector)
Task 10: complete (Active Storage media serving fix: StoreDecorator url/formatted_url HTTPS generation, ImageMethodsDecorator ruby-vips 'centre' compatibility, active_storage_fallback initializer rescuing FileNotFoundError and IntegrityError, checksum synchronization for 1,150 blobs)
Task 11: complete (Product publication logic: ProductDecorator restoring available_on activation date filtering and syncing Spree 5 status column; product_publication_spec 3/3 green)
Task 12: complete (Boundary views migration: Rails migration 20261005080000 creating listinoaccess and ordiniaccess with 100% identical SQL DDL; read-only ActiveRecord models; boundary_views_spec 4/4 green; total 20/20 RSpec tests green)
Task 13: complete (End-to-end B2B client checkout test: cliente@retebio.it created with billing/shipping addresses; ordered 4kg Zucca Violina and 7kg Finocchio; verified line items, weight steps, VAT and payment; order completed and verified in Spree Admin)
Task 14: complete (AWS Lightsail production cloud deployment: Amazon Linux 2023 instance 108.131.172.48 configured with Docker 25, Compose v2, Git; all 5 containers caddy, frontend, backend, postgres, redis running; dump_prod_241006.sql restored with 100% integrity; Caddy automatic Let's Encrypt SSL on port 80/443 verified with HTTP/2 200 OK for Storefront, Admin and Active Storage)
Task 15: complete (Remote store B2B flow: legacy authlogic_sha512 auto-migration to BCrypt with 5/5 RSpec passing; api-client cart methods updated with getCurrentBearerOrCartToken; 4GB NVMe swapfile configured on Lightsail; complete live E2E verified with cliente@retebio.it login -> 4kg Zucca Violina cart -> full checkout resulting in completed order R689373418)
Task 16: complete (Fresh production restore with dump_prod_261010.sql.gz & storage_media_261010.tar.gz: 20,960 orders, 270,542 line items, 2,954 products, 349 original customer users, 5 original admin users, 18,213/18,213 Active Storage media images 100% verified with 0 missing files, HTTPS live verified)

Final review: self-review (clean, all 16 tasks executed and verified, 25/25 RSpec tests passing, zero data loss, legacy spree_43 untouched, live on AWS Lightsail over HTTPS with full B2B auth, cart, weight-stepping, checkout, full production history of 20,960 orders and 18,213 images 100% operational)
