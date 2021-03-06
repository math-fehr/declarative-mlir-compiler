#include "dmc/Spec/SpecDialect.h"
#include "dmc/Spec/DialectGen.h"
#include "dmc/Traits/Registry.h"

#include <mlir/Parser.h>
#include <mlir/IR/Diagnostics.h>
#include <mlir/IR/Verifier.h>
#include <mlir/Pass/Pass.h>
#include <mlir/Pass/PassManager.h>
#include <mlir/Dialect/StandardOps/IR/Ops.h>
#include <mlir/Dialect/SCF/SCF.h>
#include <mlir/Dialect/LLVMIR/LLVMDialect.h>
#include <mlir/Conversion/SCFToStandard/SCFToStandard.h>
#include <mlir/Conversion/StandardToLLVM/ConvertStandardToLLVMPass.h>

#include <llvm/Support/ErrorOr.h>
#include <llvm/Support/MemoryBuffer.h>
#include <llvm/Support/SourceMgr.h>

using namespace mlir;
using namespace llvm;
using namespace dmc;

static DialectRegistration<SpecDialect> specDialectRegistration;
static DialectRegistration<TraitRegistry> registerTraits;
static DialectRegistration<StandardOpsDialect> registerStdOps;
static DialectRegistration<scf::SCFDialect> registerScfOps;
static DialectRegistration<LLVM::LLVMDialect> registerLlvmOps;

int main(int argc, char *argv[]) {
  if (argc != 3) {
    llvm::errs() << "Usage: gen <dialect_mlir> <module_mlir>\n";
    return -1;
  }

  MLIRContext ctx;
  auto *dynCtx = ctx.getOrCreateDialect<DynamicContext>();

  SourceMgr dialectSrcMgr;
  SourceMgrDiagnosticHandler dialectDiag{dialectSrcMgr, &ctx};
  auto dialectModule = mlir::parseSourceFile(argv[1], dialectSrcMgr, &ctx);
  if (!dialectModule) {
    llvm::errs() << "Failed to load dialect module: " << argv[1] << "\n";
    return -1;
  }
  if (failed(verify(*dialectModule))) {
    llvm::errs() << "Failed to verify dialect module: " << argv[1] << "\n";
    return -1;
  }

  if (failed(registerAllDialects(*dialectModule, dynCtx))) {
    llvm::errs() << "Failed to register dynamic dialects\n";
    return -1;
  }

  SourceMgr mlirSrcMgr;
  SourceMgrDiagnosticHandler mlirDiag{mlirSrcMgr, &ctx};
  auto mlirModule = mlir::parseSourceFile(argv[2], mlirSrcMgr, &ctx);
  if (!mlirModule) {
    llvm::errs() << "Failed to load MLIR module: " << argv[2] << "\n";
    return -1;
  }
  if (failed(verify(*mlirModule))) {
    llvm::errs() << "Failed to verify MLIR module: " << argv[2] << "\n";
    return -1;
  }

  mlirModule->print(llvm::outs());
  llvm::outs() << "\n";

  return 0;
}
