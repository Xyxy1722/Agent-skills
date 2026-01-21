[[_TOC_]]

# Summary

目前 FIX tag17 ExecId 的生成逻辑为：

1. 成交类（有成交编号）：委托号加成交编号
2. 非成交类：委托号加唯一自增数字

这样如果出现重复的比如交易所确认，会对应不同的 ExecId，对去重逻辑造成影响。

详细参见：`com.citics.itst.xiangliu.bootstrap.transport.fix.StdExecIdSequence`

需要实现新的逻辑，为逻辑上相同的回报生成相同的 ExecId。

# Goals

1. 实现新的 ExecId 生成逻辑，为逻辑上相同的回报生成相同的 ExecId

# Non-Goals

1. 根据 ExecId 去重

# Motivation

已有的 ExecId 生成逻辑会对重复的回报生成不同的 ExecId，对去重逻辑造成影响。

# Description

## Interface `com.citics.itst.xiangliu.bootstrap.transport.fix.NextExecIdSupplier`

ExecId 的生成逻辑定义在 `NextExecIdSupplier` 中。目前只有一个实现类 `com.citics.itst.xiangliu.bootstrap.transport.fix.StdExecIdSequence`。

```java
public interface NextExecIdSupplier {
  String generate(final FixBeginString fix, final long orderId, @Nullable final String emsExecId);
}
```

对于成交类回报，`emsExecId != null`；非成交类回报，`emsExecId == null` 。

需要改造该接口:

```java
public interface NextExecIdSupplier {
  String generate(final FixBeginString fix, final long orderId, final char execType, @Nullable final String emsExecId);
}
```

## New Implementation Class `StableExecIdSequence`

新增实现类 `StableExecIdSequence`:

- 对于成交类回报(`emsExecId != null`)，保持当前逻辑不变
- 非成交类回报，`emsExecId == null`
    - FIX.4.0 由于协议要求 ExecId 必须数字，故暂不实现本需求
    - FIX > 4.0 -> orderId + execType + '-0'

# Testing

## 单元测试

1. 非成交类 ExecType 对应的 ExecId 不重复
2. 成交类 emsExecId(0,non-zero) 不同对应的 ExecId 不重复
3. 非成交类与成交类(emsExecId=0) 对应的 ExecId 不重复

# Impact

## FIX Client

如果客户端依赖了 ExecId 的逻辑，则需进行对应变更；否则无影响。

## CIFIX Gateway

需要开发测试验证。

## HTS Proxy

无影响。

## HTS

无影响。

## Rootnet

无影响。

<!-- vim:set cuc cul nu ts=4 sw=4 ai si sr list ft=markdown: -->
