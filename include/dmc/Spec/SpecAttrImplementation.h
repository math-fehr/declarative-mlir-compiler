#pragma once

#include "dmc/Kind.h"

#include <mlir/IR/Operation.h>
#include <mlir/IR/DialectImplementation.h>
#include <mlir/IR/Builders.h>

namespace dmc {

namespace SpecAttrs {
enum Kinds {
  Any = Kind::FIRST_SPEC_ATTR,
  Bool,
  Index,
  APInt,

  AnyI,
  I,
  SI,
  UI,
  F,

  String,
  Type,
  Unit,
  Dictionary,
  Elements,
  DenseElements,
  ElementsOf,
  RankedElements,
  StringElements,
  Array,
  ArrayOf,

  SymbolRef,
  FlatSymbolRef,

  Constant,
  AnyOf,
  AllOf,
  OfType,

  Optional,
  Default,

  Isa,

  /// Generic Python attribute constraint.
  Py,

  /// Non-attribute-constraint kinds.
  OpTrait,
  OpTraits,

  NUM_ATTRS
};

bool is(mlir::Attribute base);
mlir::LogicalResult delegateVerify(mlir::Attribute base,
                                   mlir::Attribute attr);

} // end namespace SpecAttrs

template <typename ConcreteType, unsigned SpecKind,
          typename StorageType = mlir::AttributeStorage>
class SpecAttr
    : public mlir::Attribute::AttrBase<ConcreteType, mlir::Attribute,
                                                     StorageType> {
public:
  static constexpr auto Kind = SpecKind;

  using Parent = mlir::Attribute::AttrBase<ConcreteType, mlir::Attribute,
                                           StorageType>;
  using Base = SpecAttr<ConcreteType, Kind, StorageType>;
  using Parent::Parent;

  static bool kindof(unsigned kind) { return kind == Kind; }
};

template <typename ConcreteType, unsigned Kind>
class SimpleAttr : public SpecAttr<ConcreteType, Kind> {
public:
  using Parent = SpecAttr<ConcreteType, Kind>;
  using Base = SimpleAttr<ConcreteType, Kind>;
  using Parent::Parent;

  static ConcreteType get(mlir::MLIRContext *ctx) {
    return Parent::get(ctx, Kind);
  }
  static mlir::Attribute parse(mlir::DialectAsmParser &parser) {
    return get(parser.getBuilder().getContext());
  }
  void print(mlir::DialectAsmPrinter &printer) {
    printer << ConcreteType::getAttrName();
  }
};

/// Verify Attribute constraints.
namespace impl {
mlir::LogicalResult verifyAttrConstraints(
    mlir::Operation *op, mlir::DictionaryAttr opAttrs);
} // end namespace impl

} // end namespace dmc
