const std = @import("std");

pub const StockMode = enum { correct, diverge };

pub const Intent = struct {
    id: []const u8 = "intent.buy-product",
    customer_id: []const u8 = "customer-001",
    product_id: []const u8 = "product-001",
    quantity: u32 = 2,
    unit_price_cents: u64 = 1250,
};

pub const Customer = struct {
    id: []const u8,
    active: bool,
};

pub const Product = struct {
    id: []const u8,
    unit_price_cents: u64,
};

pub const SalesOrder = struct {
    id: []const u8,
    customer_id: []const u8,
    product_id: []const u8,
    quantity: u32,
    total_cents: u64,
    persisted: bool,
};

pub const FinancialTransaction = struct {
    id: []const u8,
    sale_id: []const u8,
    amount_cents: u64,
    recorded: bool,
};

pub const StockItem = struct {
    product_id: []const u8,
    before: u32,
    expected_after: u32,
    observed_after: u32,
};

pub const Delivery = struct {
    id: []const u8,
    sale_id: []const u8,
    quantity: u32,
    created: bool,
};

pub const Step = struct {
    sequence: u8,
    entity: []const u8,
    action: []const u8,
    status: []const u8,
    expected: []const u8,
    observed: []const u8,
    causal_parent: ?u8,
};

pub const EntitySnapshot = struct {
    entity: []const u8,
    id: []const u8,
    state_before: []const u8,
    state_after: []const u8,
};

pub const Divergence = struct {
    sequence: u8,
    entity: []const u8,
    invariant: []const u8,
    expected: []const u8,
    observed: []const u8,
    diagnostic: []const u8,
};

pub const Artifact = struct {
    schema_version: u8 = 1,
    run_id: []const u8 = "run-buy-product-stock-divergence",
    intent: Intent,
    status: []const u8,
    steps: [5]Step,
    entities: [5]EntitySnapshot,
    first_divergence: ?Divergence,
};

pub fn runBuyProduct(mode: StockMode) Artifact {
    const intent = Intent{};
    const customer = Customer{ .id = intent.customer_id, .active = true };
    const product = Product{ .id = intent.product_id, .unit_price_cents = intent.unit_price_cents };
    const sale_total = product.unit_price_cents * intent.quantity;
    const sale = SalesOrder{
        .id = "sale-001",
        .customer_id = customer.id,
        .product_id = product.id,
        .quantity = intent.quantity,
        .total_cents = sale_total,
        .persisted = true,
    };
    const financial = FinancialTransaction{
        .id = "financial-001",
        .sale_id = sale.id,
        .amount_cents = sale.total_cents,
        .recorded = true,
    };

    const stock_before: u32 = 10;
    const expected_stock_after = stock_before - intent.quantity;
    // Inject one controlled defect for the diagnostic test: only one unit is deducted.
    const observed_stock_after = switch (mode) {
        .correct => expected_stock_after,
        .diverge => stock_before - (intent.quantity - 1),
    };
    const stock = StockItem{
        .product_id = product.id,
        .before = stock_before,
        .expected_after = expected_stock_after,
        .observed_after = observed_stock_after,
    };
    const delivery = Delivery{
        .id = "delivery-001",
        .sale_id = sale.id,
        .quantity = intent.quantity,
        .created = true,
    };

    const stock_diverged = stock.observed_after != stock.expected_after;
    const divergence: ?Divergence = if (stock_diverged) .{
        .sequence = 3,
        .entity = "Stock",
        .invariant = "stock_after == stock_before - sold_quantity",
        .expected = "8",
        .observed = "9",
        .diagnostic = "Sale and financial record exist, but inventory deduction is short by one unit.",
    } else null;

    const steps = [5]Step{
        .{
            .sequence = 0,
            .entity = "Customer",
            .action = "validate_customer",
            .status = if (customer.active) "passed" else "failed",
            .expected = "active == true",
            .observed = if (customer.active) "active == true" else "active == false",
            .causal_parent = null,
        },
        .{
            .sequence = 1,
            .entity = "Sales",
            .action = "persist_sale",
            .status = if (sale.persisted) "passed" else "failed",
            .expected = "sale persisted; quantity == 2; total_cents == 2500",
            .observed = if (sale.persisted) "sale persisted; quantity == 2; total_cents == 2500" else "sale not persisted",
            .causal_parent = 0,
        },
        .{
            .sequence = 2,
            .entity = "Financial",
            .action = "record_transaction",
            .status = if (financial.recorded) "passed" else "failed",
            .expected = "recorded == true; amount_cents == 2500",
            .observed = if (financial.recorded) "recorded == true; amount_cents == 2500" else "transaction not recorded",
            .causal_parent = 1,
        },
        .{
            .sequence = 3,
            .entity = "Stock",
            .action = "deduct_inventory",
            .status = if (stock_diverged) "diverged" else "passed",
            .expected = "stock_after == 8",
            .observed = if (stock_diverged) "stock_after == 9" else "stock_after == 8",
            .causal_parent = 2,
        },
        .{
            .sequence = 4,
            .entity = "Delivery",
            .action = "create_delivery",
            .status = "executed_after_divergence",
            .expected = "delivery created for 2 units",
            .observed = if (delivery.created) "delivery created for 2 units" else "delivery not created",
            .causal_parent = 3,
        },
    };

    const entities = [5]EntitySnapshot{
        .{ .entity = "Customer", .id = customer.id, .state_before = "unknown", .state_after = "active" },
        .{ .entity = "Sales", .id = sale.id, .state_before = "not_created", .state_after = if (sale.persisted) "persisted" else "not_persisted" },
        .{ .entity = "Financial", .id = financial.id, .state_before = "not_recorded", .state_after = if (financial.recorded) "recorded" else "not_recorded" },
        .{
            .entity = "Stock",
            .id = stock.product_id,
            .state_before = "quantity=10",
            .state_after = if (stock_diverged) "quantity=9" else "quantity=8",
        },
        .{ .entity = "Delivery", .id = delivery.id, .state_before = "not_created", .state_after = if (delivery.created) "created" else "not_created" },
    };

    return .{
        .intent = intent,
        .status = if (stock_diverged) "diverged" else "passed",
        .steps = steps,
        .entities = entities,
        .first_divergence = divergence,
    };
}

pub fn serializeArtifact(allocator: std.mem.Allocator, artifact: Artifact) ![]u8 {
    return std.json.Stringify.valueAlloc(allocator, artifact, .{ .whitespace = .indent_2 });
}

test "buy-product traverses Customer -> Sales -> Financial -> Stock -> Delivery" {
    const artifact = runBuyProduct(.correct);
    try std.testing.expectEqualStrings("passed", artifact.status);
    try std.testing.expect(artifact.first_divergence == null);
    try std.testing.expectEqualStrings("Customer", artifact.steps[0].entity);
    try std.testing.expectEqualStrings("Sales", artifact.steps[1].entity);
    try std.testing.expectEqualStrings("Financial", artifact.steps[2].entity);
    try std.testing.expectEqualStrings("Stock", artifact.steps[3].entity);
    try std.testing.expectEqualStrings("Delivery", artifact.steps[4].entity);
    try std.testing.expectEqual(@as(u32, 8), 10 - artifact.intent.quantity);
}

test "stock divergence preserves full trajectory and pinpoints first divergence" {
    const allocator = std.testing.allocator;
    const artifact = runBuyProduct(.diverge);
    try std.testing.expectEqualStrings("diverged", artifact.status);
    try std.testing.expect(artifact.first_divergence != null);
    const divergence = artifact.first_divergence.?;
    try std.testing.expectEqual(@as(u8, 3), divergence.sequence);
    try std.testing.expectEqualStrings("Stock", divergence.entity);
    try std.testing.expectEqualStrings("8", divergence.expected);
    try std.testing.expectEqualStrings("9", divergence.observed);
    // Runner keeps recording downstream steps so the artifact explains the complete action.
    try std.testing.expectEqualStrings("Delivery", artifact.steps[4].entity);
    try std.testing.expectEqualStrings("executed_after_divergence", artifact.steps[4].status);

    const json = try serializeArtifact(allocator, artifact);
    defer allocator.free(json);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"first_divergence\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"entity\": \"Stock\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"observed\": \"9\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, json, "\"Delivery\"") != null);
}
