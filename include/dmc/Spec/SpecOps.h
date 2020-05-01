#pragma once

#include <mlir/IR/Operation.h>
#include <mlir/IR/SymbolTable.h>
#include <mlir/IR/FunctionSupport.h>

namespace dmc {

/// Forward declarations.
class DialectTerminatorOp;

/// Top-level Op in the SpecDialect which defines a dialect:
///
/// dmc.Dialect @MyDialect {foldHook = @myFoldHook, ...} {
///   ...
/// }
///
/// Captured in the Op region are the Dialect Operations. The attributes are
/// used to configure the generated DynamicDialect.
class DialectOp 
    : public mlir::Op<
          DialectOp, mlir::OpTrait::ZeroOperands, mlir::OpTrait::ZeroResult,
          mlir::OpTrait::IsIsolatedFromAbove, mlir::OpTrait::SymbolTable,
          mlir::OpTrait::SingleBlockImplicitTerminator<DialectTerminatorOp>::Impl,
          mlir::SymbolOpInterface::Trait> {
public:
  using Op::Op;

  static llvm::StringRef getOperationName() { return "dmc.Dialect"; }
  static void build(mlir::OpBuilder &builder, mlir::OperationState &result, 
                    llvm::StringRef name);

  /// Operation hooks.
  static mlir::ParseResult parse(mlir::OpAsmParser &parser,
                                 mlir::OperationState &result);
  void print(mlir::OpAsmPrinter &printer);
  mlir::LogicalResult verify();

  /// Getters
  llvm::StringRef getName();
  bool allowsUnknownOps();
  bool allowsUnknownTypes();
  mlir::Region &getBodyRegion();
  mlir::Block *getBody();

private:
  /// Attributes.
  static void buildDefaultValuedAttrs(mlir::OpBuilder &builder, 
                                      mlir::OperationState &result);

  static inline llvm::StringRef getAllowUnknownOpsAttrName() {
    return "allow_unknown_ops";
  }
  static inline llvm::StringRef getAllowUnknownTypesAttrName() {
    return "allow_unknown_types";
  }
};

/// Special terminator Op for DialectOp.
class DialectTerminatorOp 
    : public mlir::Op<DialectTerminatorOp, 
                      mlir::OpTrait::ZeroOperands, mlir::OpTrait::ZeroResult,
                      mlir::OpTrait::HasParent<DialectOp>::Impl, 
                      mlir::OpTrait::IsTerminator> {
public:
  using Op::Op;
  static llvm::StringRef getOperationName() { 
    return "dmc.DialectTerminator"; 
  }
  static inline void build(mlir::OpBuilder &, mlir::OperationState &) {}
};

/// Dialect Op definition Op. This Op captures information about an operation:
///
/// dmc.Op @MyOpA(!dmc.Any, !dmc.AnyOf<!dmc.I<32>, !dmc.F<32>>) ->
///     (!dmc.AnyFloat, !dmc.AnyInteger) 
///     attributes { attr0 = !dmc.Any, attr1 = !dmc.StrAttr }
///     config { parser = @MyOpAParser, printer = @MyOpAPrinter 
///              traits = [@Commutative]}
///
/// TODO attributes and config
class OperationOp
    : public mlir::Op<OperationOp,
                      mlir::OpTrait::ZeroOperands, mlir::OpTrait::ZeroResult,
                      mlir::OpTrait::IsIsolatedFromAbove, mlir::OpTrait::FunctionLike,
                      mlir::SymbolOpInterface::Trait> {
public:
  using Op::Op;

  static llvm::StringRef getOperationName() { return "dmc.Op"; }

  static void build(mlir::OpBuilder &builder, mlir::OperationState &result, 
                    llvm::StringRef name, mlir::FunctionType type,
                    llvm::ArrayRef<mlir::NamedAttribute> attrs);

  /// Operation hooks.
  static mlir::ParseResult parse(mlir::OpAsmParser &parser, 
                                 mlir::OperationState &result);
  void print(mlir::OpAsmPrinter &printer);
  mlir::LogicalResult verify();

  /// Getters.
  llvm::StringRef getName();

private:
  /// Hooks for FunctionLike
  friend class mlir::OpTrait::FunctionLike<OperationOp>;
  unsigned getNumFuncArguments() { return getType().getInputs().size(); }
  unsigned getNumFuncResults() { return getType().getResults().size(); }
  mlir::LogicalResult verifyType();

  /// Attributes.
  static void buildDefaultValuedAttrs(mlir::OpBuilder &builder, 
                                      mlir::OperationState &result);

  static inline llvm::StringRef getIsTerminatorAttrName() {
    return "is_terminator";
  }
  static inline llvm::StringRef getIsCommutativeAttrName() {
    return "is_commutative";
  }
  static inline llvm::StringRef getIsIsolatedFromAboveAttrName() {
    return "is_isolated_from_above";
  }
};

} // end namespace dmc