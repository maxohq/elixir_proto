# ElixirProto: Context-Scoped Serialization for Elixir

If you've ever worked with event sourcing or audit logs, you know the pain: thousands of events piling up in storage, each carrying redundant schema names and field information. A simple `OrderCreated` event becomes 80+ bytes when it could be 30.

ElixirProto borrows Protobuf's core insight—use numeric schema IDs and positional fields instead of names. But it stays in Elixir-land, using the robust `:erlang.term_to_binary` format you already trust.

The key innovation: context-scoped registries that eliminate global index collisions while keeping teams autonomous.

```elixir
defmodule OrderCreated do
  use ElixirProto.Schema, name: "orders.created"
  defschema [:order_id, :customer_id, :total, :currency, :timestamp]
end

defmodule OrderEvents.PayloadConverter do
  use ElixirProto.PayloadConverter,
    mapping: [
      {1, "orders.created"},
      {2, "orders.updated"},
      {3, "orders.cancelled"}
    ]
end

event = %OrderCreated{order_id: "123", customer_id: "456", total: 99.99}
encoded = OrderEvents.PayloadConverter.encode(event)  # ~40% smaller typically
```

## When It Matters

- **Event stores**: Those millions of domain events add up fast in storage costs
- **Message queues**: Smaller payloads mean better throughput and lower AWS bills
- **Audit logs**: Compliance data you can't delete but rarely access
- **Analytics pipelines**: Moving lots of similar events between services

Like Protobuf, you get schema evolution for free—append new fields and old data still works.

## The Trade-offs

**More setup**: You manage schema indices per context (like Protobuf field numbers). Each team maintains their own PayloadConverter mapping.

**Another dependency**: Sometimes `Jason.encode!` or plain `:erlang.term_to_binary` is simpler and good enough.

**Context discipline**: Teams need to coordinate within their domain contexts, though isolation prevents cross-team conflicts.

**Overkill for small volumes**: If you're not storing thousands of events daily and watching storage costs climb, the built-ins work fine.

## Worth It?

If you're storing thousands of events daily and watching storage costs climb, probably yes. If you're building a simple CRUD app, probably no.

The context-scoped approach shines in larger systems where multiple teams work on different domains. Each team gets Protobuf's space efficiency without stepping on each other's schema indices.

It's Protobuf's space efficiency without leaving Elixir's type system, plus team autonomy without coordination overhead. Whether that trade-off makes sense depends on how much you're paying for those extra bytes and coordination meetings.