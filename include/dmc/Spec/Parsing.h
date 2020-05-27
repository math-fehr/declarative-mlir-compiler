#pragma once

#include "dmc/Traits/OpTrait.h"

#include <mlir/IR/OpImplementation.h>
#include <mlir/IR/DialectImplementation.h>

namespace dmc {
namespace impl {

/// Parse a single attribute using an OpAsmParser.
mlir::ParseResult parseSingleAttribute(mlir::OpAsmParser &parser,
                                       mlir::Attribute &attr);

/// Parse an optional parameter list.
mlir::ParseResult parseOptionalParameterList(mlir::OpAsmParser &parser,
                                             mlir::ArrayAttr &attr);
mlir::ParseResult parseOptionalParameterList(mlir::DialectAsmParser &parser,
                                             mlir::ArrayAttr &attr);

/// Parse an optional parameter list with an on-the-fly parameter modifier.
using ParameterModifier = std::function<mlir::Attribute(mlir::Attribute)>;
mlir::ParseResult parseOptionalParameterList(
    mlir::OpAsmParser &parser, mlir::ArrayAttr &attr,
    ParameterModifier modifier);

/// Print a parameter list.
void printOptionalParameterList(mlir::OpAsmPrinter &printer,
                                llvm::ArrayRef<mlir::Attribute> params);
void printOptionalParameterList(mlir::DialectAsmPrinter &printer,
                                llvm::ArrayRef<mlir::Attribute> params);

/// Parse and print an op trait list attribute in pretty form.
mlir::ParseResult parseOptionalOpTraitList(mlir::OpAsmParser &parser,
                                           OpTraitsAttr &traitArr);
void printOptionalOpTraitList(mlir::OpAsmPrinter &printer,
                              OpTraitsAttr traitArr);

/// Parse and print an op region attribute list.
mlir::ParseResult parseOpRegion(mlir::OpAsmParser &parser,
                                mlir::Attribute &opRegion);
void printOpRegion(mlir::OpAsmPrinter &printer, mlir::Attribute opRegion);
void printOpRegion(llvm::raw_ostream &os, mlir::Attribute opRegion);
mlir::ParseResult parseOptionalRegionList(mlir::OpAsmParser &parser,
                                          mlir::ArrayAttr &regionsAttr);
void printOptionalRegionList(mlir::OpAsmPrinter &printer,
                             mlir::ArrayAttr regionsAttr);

/// Parse and print a list of integers, which may be empty.
/// int-list ::= (int (`,` int)*)?
template <typename ListT>
mlir::ParseResult parseIntegerList(mlir::DialectAsmParser &parser,
                                   ListT &ints) {
  std::remove_reference_t<decltype(std::declval<ListT>().front())> val;
  auto ret = parser.parseOptionalInteger(val);
  if (ret.hasValue()) { // tri-state
    if (*ret) // failed to parse integer
      return mlir::failure();
    ints.push_back(val);
    while (!parser.parseOptionalComma()) {
      if (parser.parseInteger(val))
        return mlir::failure();
      ints.push_back(val);
    }
  }
  return mlir::success();
}

template <typename ListT>
void printIntegerList(mlir::DialectAsmPrinter &printer,
                      ListT &ints) {
  llvm::interleaveComma(ints, printer, [&](auto val) { printer << val; });
}

} // end namespace impl
} // end namespace dmc
