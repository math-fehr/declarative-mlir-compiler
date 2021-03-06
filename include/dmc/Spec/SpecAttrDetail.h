#pragma once

#include "SpecAttrImplementation.h"
#include "SpecTypeDetail.h"

namespace dmc {

/// Place full declaration in header to allow template usage.
namespace detail {

struct TypedAttrStorage : public mlir::AttributeStorage {
  using KeyTy = mlir::Type;

  explicit TypedAttrStorage(KeyTy key);
  bool operator==(const KeyTy &key) const;
  static llvm::hash_code hashKey(const KeyTy &key);
  static TypedAttrStorage *construct(
      mlir::AttributeStorageAllocator &alloc, const KeyTy &key);

  KeyTy type;
};

} // end namespace detail

/// AttrConstraint on an IntegerAttr with a specified underlying Type.
template <typename ConcreteType, unsigned Kind,
          typename AttrT, typename UnderlyingT>
class TypedAttrBase
    : public SpecAttr<ConcreteType, Kind, detail::TypedAttrStorage> {
public:
  using Base = TypedAttrBase<ConcreteType, Kind, AttrT, UnderlyingT>;
  using Parent = SpecAttr<ConcreteType, Kind, detail::TypedAttrStorage>;
  using Underlying = UnderlyingT;
  using Parent::Parent;

  static ConcreteType getChecked(
      mlir::Location loc, UnderlyingT ty) {
    return Parent::getChecked(loc, Kind, ty);
  }

  static mlir::LogicalResult verifyConstructionInvariants(
      mlir::Location loc, UnderlyingT ty) {
    if (!ty)
      return mlir::emitError(loc) << "Type cannot be null";
    return mlir::success();
  }

  mlir::LogicalResult verify(mlir::Attribute attr) {
    return mlir::success(attr.isa<AttrT>() &&
        mlir::succeeded(this->getImpl()->type.template cast<UnderlyingT>()
            .verify(attr.cast<AttrT>().getType())));
  }

  static mlir::Attribute parse(mlir::DialectAsmParser &parser) {
    auto loc = parser.getEncodedSourceLoc(parser.getCurrentLocation());
    unsigned width;
    if (parser.parseLess() || parser.parseInteger(width) ||
        parser.parseGreater())
      return {};
    return getChecked(loc, UnderlyingT::getChecked(loc, width));
  }

  void print(mlir::DialectAsmPrinter &printer) {
    printer << ConcreteType::getAttrName() << '<'
        << this->getImpl()->type.template cast<UnderlyingT>().getWidth() << '>';
  }
};

} // end namespace dmc
