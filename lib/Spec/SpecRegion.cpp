#include "dmc/Spec/SpecRegion.h"
#include "dmc/Spec/SpecRegionSwitch.h"
#include "dmc/Spec/SpecSuccessor.h"
#include "dmc/Spec/Parsing.h"

#include <mlir/IR/Builders.h>
#include <mlir/IR/Diagnostics.h>
#include <mlir/IR/Operation.h>
#include <mlir/IR/OpImplementation.h>

using namespace mlir;

namespace dmc {

namespace SpecRegion {

bool is(Attribute base) {
  return Any <= base.getKind() && base.getKind() <= LAST_SPEC_REGION;
}

LogicalResult delegateVerify(Attribute base, Region *region) {
  VerifyAction<Region *> action{region};
  return SpecRegion::kindSwitch(action, base);
}

std::string toString(Attribute opRegion) {
  std::string ret;
  llvm::raw_string_ostream os{ret};
  impl::printOpRegion(os, opRegion);
  return std::move(os.str());
}

} // end namespace SpecRegion

namespace detail {

/// Store the number of blocks expected in the region.
struct SizedRegionAttrStorage : public AttributeStorage {
  using KeyTy = unsigned;

  explicit SizedRegionAttrStorage(KeyTy key) : numBlocks{key} {}
  bool operator==(KeyTy key) const { return key == numBlocks; }
  static llvm::hash_code hashKey(KeyTy key) { return llvm::hash_value(key); }

  static SizedRegionAttrStorage *construct(AttributeStorageAllocator &alloc,
                                           KeyTy key) {
    return new (alloc.allocate<SizedRegionAttrStorage>())
      SizedRegionAttrStorage{key};
  }

  KeyTy numBlocks;
};

} // end namespace detail

/// SizedRegion.
SizedRegion SizedRegion::getChecked(Location loc, unsigned size) {
  return Base::getChecked(loc, SpecRegion::Sized, size);
}

LogicalResult SizedRegion::verifyConstructionInvariants(Location loc,
                                                        unsigned size) {
  return success();
}

LogicalResult SizedRegion::verify(Region *region) {
  return success(std::size(region->getBlocks()) == getImpl()->numBlocks);
}

/// IsolatedFromAboveRegion.
LogicalResult IsolatedFromAboveRegion::verify(Region *region) {
  return success(region->isIsolatedFromAbove());
}

/// VariadicRegion.
VariadicRegion VariadicRegion::getChecked(Location loc,
                                          Attribute regionConstraint) {
  return Base::getChecked(loc, SpecRegion::Variadic, regionConstraint);
}

LogicalResult VariadicRegion::verifyConstructionInvariants(
    Location loc, Attribute regionConstraint) {
  if (!SpecRegion::is(regionConstraint))
    return emitError(loc) << "expected a valid region constraint";
  return success();
}

LogicalResult VariadicRegion::verify(Region *region) {
  return SpecRegion::delegateVerify(getImpl()->attr, region);
}

namespace impl {

/// Generic function for verifying a list where the last constraint may be
/// variadic. Used for region and successor verification.
template <typename VariadicT, typename ListT,
          typename VerifyFcn, typename StringifyFcn>
LogicalResult verifyConstraintsLastVariadic(
    Operation *op, ListT vars, mlir::ArrayAttr constraints,
    VerifyFcn &&verify, StringifyFcn &&toString) {
  auto varIt = std::begin(vars), varEnd = std::end(vars);
  auto attrIt = std::begin(constraints), attrEnd = std::end(constraints);
  for (unsigned idx = 0; attrIt != attrEnd; ++attrIt, ++varIt) {
    /// There can only be one variadic region, and it will always be the last
    /// region. Region counts are verified by another trait.
    assert(!attrIt->isa<VariadicT>() || attrIt == std::prev(attrEnd));
    assert(varIt != varEnd || attrIt->isa<VariadicT>());
    /// If the current constraint is not variadic, check one region, otherwise,
    /// iterate over the remaining regions and check the variadic constraint.
    for (auto it = varIt; it != varEnd &&
         (it == varIt || attrIt->isa<VariadicT>()); ++it, ++idx) {
      if (failed(verify(*attrIt, *it)))
        return op->emitOpError("region #") << idx << " expected "
            << toString(*attrIt);
    }
  }
  return success();
}

/// Region verification.
LogicalResult verifyRegionConstraints(Operation *op,
                                      mlir::ArrayAttr opRegions) {
  return verifyConstraintsLastVariadic<VariadicRegion>(
      op, op->getRegions(), opRegions,
      [](Attribute constraint, Region &region)
      { return SpecRegion::delegateVerify(constraint, &region); },
      [](Attribute constraint) { return SpecRegion::toString(constraint); });
}

/// Successor verification.
LogicalResult verifySuccessorConstraints(Operation *op,
                                         mlir::ArrayAttr opSuccs) {
  return verifyConstraintsLastVariadic<VariadicSuccessor>(
      op, op->getSuccessors(), opSuccs,
      [](Attribute constraint, Block *block)
      { return SpecSuccessor::delegateVerify(constraint, block); },
      [](Attribute constraint) { return SpecSuccessor::toString(constraint); });
}
} // end namespace impl

Attribute AnyRegion::parse(OpAsmParser &parser) {
  return get(parser.getBuilder().getContext());
}

Attribute SizedRegion::parse(OpAsmParser &parser) {
  if (parser.parseLess())
    return {};
  auto loc = parser.getEncodedSourceLoc(parser.getCurrentLocation());
  Attribute sizeAttr;
  if (impl::parseSingleAttribute(parser, sizeAttr))
    return {};
  auto intAttr = sizeAttr.dyn_cast<IntegerAttr>();
  if (!intAttr) {
    emitError(loc) << "expected an integer size";
    return {};
  }
  if (parser.parseGreater())
    return {};
  return getChecked(loc, intAttr.getValue().getZExtValue());
}

Attribute IsolatedFromAboveRegion::parse(OpAsmParser &parser) {
  return get(parser.getBuilder().getContext());
}

Attribute VariadicRegion::parse(OpAsmParser &parser) {
  Attribute opRegion;
  auto loc = parser.getEncodedSourceLoc(parser.getCurrentLocation());
  if (parser.parseLess() || impl::parseOpRegion(parser, opRegion) ||
      parser.parseGreater())
    return {};
  return getChecked(loc, opRegion);
}

void AnyRegion::print(llvm::raw_ostream &os) {
  os << getName();
}

void SizedRegion::print(llvm::raw_ostream &os) {
  os << getName() << '<' << getImpl()->numBlocks << '>';
}

void IsolatedFromAboveRegion::print(llvm::raw_ostream &os) {
  os << getName();
}

void VariadicRegion::print(llvm::raw_ostream &os) {
  os << getName() << '<';
  impl::printOpRegion(os, getImpl()->attr);
  os << '>';
}

} // end namespace dmc