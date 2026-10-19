# Traject Runner (Zig 0.16)

The first Zig runner for T-DD executes the `intent.buy-product` scenario and emits a JSON Trajectory Artifact. It records the full ordered path even after a divergence so a repair agent can inspect downstream effects.

## Execution path

`Customer → Sales → Financial → Stock → Delivery`

The artifact records each step's sequence, entity, action, expected observation, actual observation, status, and causal parent. Entity snapshots capture before/after state. `first_divergence` points to the earliest failed invariant in this scenario; it is a diagnostic boundary, not proof of root cause.

## Entities

- `Intent`: customer, product, quantity, unit price.
- `Customer`: customer identity and active state.
- `Product`: product identity and unit price.
- `SalesOrder`: persisted sale and total.
- `FinancialTransaction`: recorded financial amount.
- `StockItem`: before, expected-after, and observed-after quantity.
- `Delivery`: delivery record linked to the sale.

## Stock divergence fixture

The diagnostic run injects one controlled defect at Stock: selling 2 units from stock 10 should leave 8, but the fixture deducts only 1 and observes 9. The runner marks sequence 3 as the first divergence and continues recording Delivery so the artifact retains the complete action trajectory.

This is an intentionally injected test defect, not a defect in a real inventory service.

## Run locally

Requires Zig 0.16.0:

```sh
zig test zig/traject_runner.zig
mkdir -p artifacts
zig run zig/main.zig 2> artifacts/trajectory.json
```

The CI validates the JSON artifact and uploads it as `traject-buy-product-stock-divergence`.

## Scope and next increment

This is a deterministic in-memory reference runner. It establishes the artifact contract and diagnostic test; it does not yet instrument external services, distributed traces, real database transactions, or wall-clock timestamps.
