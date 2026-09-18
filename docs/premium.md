# Premium foundation

Confirmed features: **projects, sharing and collaboration**. Notes, folders,
standalone tasks and import/export remain free. Other boundaries and the payment
model will be decided later; no pricing, product IDs or subscription terms exist.

`PremiumAccess` is a read-only entitlement snapshot and central feature policy.
The current production tier is free. Future paid commands must call `require`
at their boundary, as well as adapting navigation. Do not treat a hidden button
as enforcement. Feature availability and possession of an entitlement are separate:
a Premium snapshot does not make unfinished projects/collaboration operational.

The About action now opens a Premium information page. It clearly states that the
features are in development and purchases are unavailable. No fake checkout,
local unlock switch, fabricated receipt or nonfunctional restore button is exposed.

## Future billing adapter

Before enabling purchases, select one-time purchase or subscription, configure
products in both stores and implement purchase, pending, cancellation, failure,
verification, restoration and revocation. A stored boolean is not purchase evidence.
Only a verified store adapter may produce the trusted entitlement snapshot.
Avoid creating a central user account merely for billing. Decide offline access,
refund behavior and cross-platform portability explicitly; do not assume an Apple
purchase automatically grants a Google Play entitlement.

Open-source client enforcement is not tamper-proof DRM. Keep purchase records out
of crash payloads. Store receipt verification and retention must be reviewed against
the no-central-user-storage requirement before selecting an implementation.

Reference for later integration: [Flutter in-app purchase API](https://pub.dev/documentation/in_app_purchase/latest/).
