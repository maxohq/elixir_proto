# ElixirProto: Protobuf-Inspired Serialization for Elixir Events

If you've ever worked with event sourcing or audit logs, you know the pain: thousands of events piling up in storage, each carrying redundant schema names and field information. A simple `OrderCreated` event becomes 80+ bytes when it could be 30.

ElixirProto borrows Protobuf's core insight—use numeric schema IDs and positional fields instead of names. But it stays in Elixir-land, using the robust `:erlang.term_to_binary` format you already trust.

```elixir
defmodule OrderCreated do
  use ElixirProto.Schema, name: "orders.created", index: 1
  defschema [:order_id, :customer_id, :total, :currency, :timestamp]
end

event = %OrderCreated{order_id: "123", customer_id: "456", total: 99.99}
encoded = ElixirProto.encode(event)  # ~40% smaller typically
```

## When It Matters

- **Event stores**: Those millions of domain events add up fast in storage costs
- **Message queues**: Smaller payloads mean better throughput and lower AWS bills
- **Audit logs**: Compliance data you can't delete but rarely access
- **Analytics pipelines**: Moving lots of similar events between services

Like Protobuf, you get schema evolution for free—append new fields and old data still works.

## The Trade-offs

**More setup**: You manage schema indices manually (like Protobuf field numbers). Pick wrong and you're stuck with them.

**Another dependency**: Sometimes `Jason.encode!` or plain `:erlang.term_to_binary` is simpler and good enough.

**Overkill for small volumes**: If you're not storing thousands of events daily and watching storage costs climb, the built-ins work fine.

## Worth It?

If you're storing thousands of events daily and watching storage costs climb, probably yes. If you're building a simple CRUD app, probably no.

It's Protobuf's space efficiency without leaving Elixir's type system. Whether that trade-off makes sense depends on how much you're paying for those extra bytes.