module {
  // debugging
  func @print_one(%val: !lua.val) -> ()

  func @luac_check_float_type(%val: !lua.val) -> i1 {
    %alloca_val = luac.into_alloca %val
    %num_type = constant #luac.type_num
    %val_type = luac.get_type type(%alloca_val)
    %type_ok = cmpi "eq", %val_type, %num_type : !luac.type_enum

    return %type_ok : i1
  }

  func @luac_check_int_type(%val: !lua.val) -> i1 {
    %alloca_val = luac.into_alloca %val
    %num_type = constant #luallvm.type_int
    %val_type = luac.get_type type(%alloca_val)
    %type_ok = cmpi "eq", %val_type, %num_type : !luac.type_enum

    return %type_ok : i1
  }

  func @luac_assert_int_type(%val: !lua.val) {
    %is_int = call @luac_check_int_type(%val) : (!lua.val) -> i1
    scf.if %is_int {
      call @lua_abort() : () -> ()
    }
    return
  }

  func @convert_to_float(%val: !lua.val) -> !lua.val {
    %is_float = call @luac_check_float_type(%val) : (!lua.val) -> i1

    %res = scf.if %is_float -> !lua.val {
      scf.yield %val : !lua.val
    } else {
      %is_int = call @luac_check_int_type(%val) : (!lua.val) -> i1

      %retv = scf.if %is_int -> !lua.val {
        %alloca_val = luac.into_alloca %val

        %val_int = luac.get_int_val %alloca_val
        %val_float = std.sitofp %val_int : i64 to f64

        %ret_v = luac.wrap_real %val_float
        %retv = luac.load_from %ret_v
        scf.yield %retv : !lua.val
      } else {
        call @lua_abort() : () -> ()
        %ret_v = lua.nil
        %retv = luac.load_from %ret_v
        scf.yield %retv : !lua.val
      }
      scf.yield %retv : !lua.val
    }

    return %res : !lua.val
  }

  func @lua_add(%lhsv: !lua.val, %rhsv: !lua.val) -> !lua.val {
    %lhs_is_int = call @luac_check_int_type(%lhsv) : (!lua.val) -> i1
    %rhs_is_int = call @luac_check_int_type(%rhsv) : (!lua.val) -> i1
    %both_are_int = and %lhs_is_int, %rhs_is_int : i1

    %ret = scf.if %both_are_int -> !lua.val {
      %lhs = luac.into_alloca %lhsv
      %rhs = luac.into_alloca %rhsv
      %lhs_int = luac.get_int_val %lhs
      %rhs_int = luac.get_int_val %rhs
      %ret_int = addi %lhs_int, %rhs_int : i64
      %ret_v = luac.wrap_int %ret_int
      %retv = luac.load_from %ret_v
      scf.yield %retv : !lua.val 
    } else {
      %lhsv_float = call @convert_to_float(%lhsv) : (!lua.val) -> !lua.val
      %rhsv_float = call @convert_to_float(%rhsv) : (!lua.val) -> !lua.val
      %lhs_float = luac.into_alloca %lhsv_float
      %rhs_float = luac.into_alloca %rhsv_float
      %lhs_double = luac.get_double_val %lhs_float
      %rhs_double = luac.get_double_val %rhs_float
      %ret_double = addf %lhs_double, %rhs_double : f64
      %ret_v = luac.wrap_real %ret_double
      %retv = luac.load_from %ret_v
      scf.yield %retv : !lua.val 
    }

    return %ret : !lua.val
  }

  func @lua_sub(%lhsv: !lua.val, %rhsv: !lua.val) -> !lua.val {
    %lhs_is_int = call @luac_check_int_type(%lhsv) : (!lua.val) -> i1
    %rhs_is_int = call @luac_check_int_type(%rhsv) : (!lua.val) -> i1
    %both_are_int = and %lhs_is_int, %rhs_is_int : i1

    %ret = scf.if %both_are_int -> !lua.val {
      %lhs = luac.into_alloca %lhsv
      %rhs = luac.into_alloca %rhsv
      %lhs_int = luac.get_int_val %lhs
      %rhs_int = luac.get_int_val %rhs
      %ret_int = subi %lhs_int, %rhs_int : i64
      %ret_v = luac.wrap_int %ret_int
      %retv = luac.load_from %ret_v
      scf.yield %retv : !lua.val 
    } else {
      %lhsv_float = call @convert_to_float(%lhsv) : (!lua.val) -> !lua.val
      %rhsv_float = call @convert_to_float(%rhsv) : (!lua.val) -> !lua.val
      %lhs_float = luac.into_alloca %lhsv_float
      %rhs_float = luac.into_alloca %rhsv_float
      %lhs_double = luac.get_double_val %lhs_float
      %rhs_double = luac.get_double_val %rhs_float
      %ret_double = subf %lhs_double, %rhs_double : f64
      %ret_v = luac.wrap_real %ret_double
      %retv = luac.load_from %ret_v
      scf.yield %retv : !lua.val 
    }

    return %ret : !lua.val
  }

  func @lua_mul(%lhsv: !lua.val, %rhsv: !lua.val) -> !lua.val {
    %lhs_is_int = call @luac_check_int_type(%lhsv) : (!lua.val) -> i1
    %rhs_is_int = call @luac_check_int_type(%rhsv) : (!lua.val) -> i1
    %both_are_int = and %lhs_is_int, %rhs_is_int : i1

    %ret = scf.if %both_are_int -> !lua.val {
      %lhs = luac.into_alloca %lhsv
      %rhs = luac.into_alloca %rhsv
      %lhs_int = luac.get_int_val %lhs
      %rhs_int = luac.get_int_val %rhs
      %ret_int = muli %lhs_int, %rhs_int : i64
      %ret_v = luac.wrap_int %ret_int
      %retv = luac.load_from %ret_v
      scf.yield %retv : !lua.val 
    } else {
      %lhsv_float = call @convert_to_float(%lhsv) : (!lua.val) -> !lua.val
      %rhsv_float = call @convert_to_float(%rhsv) : (!lua.val) -> !lua.val
      %lhs_float = luac.into_alloca %lhsv_float
      %rhs_float = luac.into_alloca %rhsv_float
      %lhs_double = luac.get_double_val %lhs_float
      %rhs_double = luac.get_double_val %rhs_float
      %ret_double = mulf %lhs_double, %rhs_double : f64
      %ret_v = luac.wrap_real %ret_double
      %retv = luac.load_from %ret_v
      scf.yield %retv : !lua.val 
    }

    return %ret : !lua.val
  }

  func @lua_div(%lhsv: !lua.val, %rhsv: !lua.val) -> !lua.val {
    %lhsv_float = call @convert_to_float(%lhsv) : (!lua.val) -> !lua.val
    %rhsv_float = call @convert_to_float(%rhsv) : (!lua.val) -> !lua.val
    %lhs_float = luac.into_alloca %lhsv_float
    %rhs_float = luac.into_alloca %rhsv_float
    %lhs_double = luac.get_double_val %lhs_float
    %rhs_double = luac.get_double_val %rhs_float
    %ret_double = divf %lhs_double, %rhs_double : f64
    %retv = luac.wrap_real %ret_double
    %ret = luac.load_from %retv
    return %ret : !lua.val
  }

  func @lua_mod(%lhsv: !lua.val, %rhsv: !lua.val) -> !lua.val {
    %lhs = luac.into_alloca %lhsv
    %rhs = luac.into_alloca %rhsv
    %lhs_int = luac.get_int_val %lhs
    %rhs_int = luac.get_int_val %rhs
    %ret_int = remi_signed %lhs_int, %rhs_int : i64
    %retv = luac.wrap_int %ret_int
    %ret = luac.load_from %retv
    return %ret : !lua.val
  }

  // double pow(double x, double y) from <math.h>
  func @pow(%x: f64, %y: f64) -> f64
  func @ipow(%x: i64, %y : i64) -> i64
  func @lua_pow(%lhsv: !lua.val, %rhsv: !lua.val) -> !lua.val {
    %lhs = luac.into_alloca %lhsv
    %rhs = luac.into_alloca %rhsv

      %lhs_num = luac.get_int_val %lhs
      %rhs_num = luac.get_int_val %rhs
      %ret_num = call @ipow(%lhs_num, %rhs_num) : (i64, i64) -> i64
      %ret_v = luac.wrap_int %ret_num
      %ret = luac.load_from %ret_v
    return %ret : !lua.val
  }

  func @lua_neg(%valv: !lua.val) -> !lua.val {

    %val_is_int = call @luac_check_int_type(%valv) : (!lua.val) -> i1

    %ret = scf.if %val_is_int -> !lua.val {
      %val = luac.into_alloca %valv
      %inv = constant -1 : i64
      %num = luac.get_int_val %val
      %ret_num = muli %inv, %num : i64
      %ret_v = luac.wrap_int %ret_num
      %ret = luac.load_from %ret_v
      scf.yield %ret : !lua.val
    } else {
      %valv_float = call @convert_to_float(%valv) : (!lua.val) -> !lua.val
      %val_float = luac.into_alloca %valv_float
      %val_double = luac.get_double_val %val_float
      %inv_double = constant -1.0 : f64
      %ret_double = mulf %inv_double, %val_double : f64
      %ret_v = luac.wrap_real %ret_double
      %retv = luac.load_from %ret_v
      scf.yield %retv : !lua.val 
    }

    return %ret : !lua.val
  }

  func @lua_lt(%lhsv: !lua.val, %rhsv: !lua.val) -> !lua.val {
    %lhs = luac.into_alloca %lhsv
    %rhs = luac.into_alloca %rhsv

      %lhs_num = luac.get_int_val %lhs
      %rhs_num = luac.get_int_val %rhs
      %ret_b = cmpi "slt", %lhs_num, %rhs_num : i64
      %ret_v = luac.wrap_bool %ret_b
      %ret = luac.load_from %ret_v
    return %ret : !lua.val
  }

  func @lua_gt(%lhsv: !lua.val, %rhsv: !lua.val) -> !lua.val {
    %lhs = luac.into_alloca %lhsv
    %rhs = luac.into_alloca %rhsv

      %lhs_num = luac.get_int_val %lhs
      %rhs_num = luac.get_int_val %rhs
      %ret_b = cmpi "sgt", %lhs_num, %rhs_num : i64
      %ret_v = luac.wrap_bool %ret_b
      %ret = luac.load_from %ret_v
    return %ret : !lua.val
  }

  func @lua_le(%lhsv: !lua.val, %rhsv: !lua.val) -> !lua.val {
    %lhs = luac.into_alloca %lhsv
    %rhs = luac.into_alloca %rhsv

      %lhs_num = luac.get_int_val %lhs
      %rhs_num = luac.get_int_val %rhs
      %ret_b = cmpi "sle", %lhs_num, %rhs_num : i64
      %ret_v = luac.wrap_bool %ret_b
      %ret = luac.load_from %ret_v
    return %ret : !lua.val
  }

  func @lua_ge(%lhsv: !lua.val, %rhsv: !lua.val) -> !lua.val {
    %lhs = luac.into_alloca %lhsv
    %rhs = luac.into_alloca %rhsv

      %lhs_num = luac.get_int_val %lhs
      %rhs_num = luac.get_int_val %rhs
      %ret_b = cmpi "sge", %lhs_num, %rhs_num : i64
      %ret_v = luac.wrap_bool %ret_b
      %ret = luac.load_from %ret_v
    return %ret : !lua.val
  }

  func @lua_bool_and(%lhsv: !lua.val, %rhsv: !lua.val) -> !lua.val {
    %lhs_b = call @lua_convert_bool_like(%lhsv) : (!lua.val) -> i1
    %rhs_b = call @lua_convert_bool_like(%rhsv) : (!lua.val) -> i1

    %ret_b = and %lhs_b, %rhs_b : i1
    %ret = luac.wrap_bool %ret_b

    %retv = luac.load_from %ret
    return %retv : !lua.val
  }

  func @lua_bool_not(%valv: !lua.val) -> !lua.val {
    %b = call @lua_convert_bool_like(%valv) : (!lua.val) -> i1
    %const1 = constant 1 : i1

    %not_b = xor %b, %const1 : i1
    %ret = luac.wrap_bool %not_b

    %retv = luac.load_from %ret
    return %retv : !lua.val
  }

  func @lua_list_size_impl(%impl: !luac.void_ptr) -> i64
  func @lua_list_size(%valv: !lua.val) -> !lua.val {
    %val = luac.into_alloca %valv

    %table_type = constant #luac.type_tbl
    %type = luac.get_type type(%val)
    %type_ok = cmpi "eq", %type, %table_type : !luac.type_enum

    %ret = scf.if %type_ok -> !lua.val {
      %impl = luac.get_impl %val
      %sz = call @lua_list_size_impl(%impl) : (!luac.void_ptr) -> i64
      %ret_v = luac.wrap_int %sz
      %retv = luac.load_from %ret_v
      scf.yield %retv : !lua.val
    } else {
      %ret_v = lua.nil
      %retv = luac.load_from %ret_v
      scf.yield %retv : !lua.val
    }

    return %ret : !lua.val
  }

  func @lua_strcat_impl(%lhs: !luac.void_ptr,
                        %rhs: !luac.void_ptr) -> !lua.val
  func @lua_strcat(%lhsv: !lua.val, %rhsv: !lua.val) -> !lua.val {
    %lhs = luac.into_alloca %lhsv
    %rhs = luac.into_alloca %rhsv

    %lhs_type = luac.get_type type(%lhs)
    %rhs_type = luac.get_type type(%rhs)
    %str_type = constant #luac.type_str
    %lhs_ok = cmpi "eq", %lhs_type, %str_type : !luac.type_enum
    %rhs_ok = cmpi "eq", %rhs_type, %str_type : !luac.type_enum
    %types_ok = and %lhs_ok, %rhs_ok : i1

    %ret = scf.if %types_ok -> !lua.val {
      %lhs_impl = luac.get_impl %lhs
      %rhs_impl = luac.get_impl %rhs
      %ret_v = call @lua_strcat_impl(%lhs_impl, %rhs_impl)
          : (!luac.void_ptr, !luac.void_ptr) -> !lua.val
      scf.yield %ret_v : !lua.val
    } else {
      %ret_v = lua.nil
      %retv = luac.load_from %ret_v
      scf.yield %retv : !lua.val
    }

    return %ret : !lua.val
  }

  func @lua_eq_impl(%lhs: !lua.val, %rhs: !lua.val) -> i1
  func @lua_eq(%lhsv: !lua.val, %rhsv: !lua.val) -> !lua.val {
    %lhs = luac.into_alloca %lhsv
    %rhs = luac.into_alloca %rhsv
    %lhs_num = luac.get_int_val %lhs
    %rhs_num = luac.get_int_val %rhs
    %b = cmpi "eq", %lhs_num, %rhs_num : i64
    %ret = luac.wrap_bool %b
    %retv = luac.load_from %ret
    return %retv : !lua.val
    //%lhs = luac.into_alloca %lhsv
    //%rhs = luac.into_alloca %rhsv

    //%lhs_type = luac.get_type type(%lhs)
    //%rhs_type = luac.get_type type(%rhs)
    //%same_type = cmpi "eq", %lhs_type, %rhs_type : !luac.type_enum

    //%ret_b = scf.if %same_type -> i1 {
    //  %result = call @lua_eq_impl(%lhsv, %rhsv)
    //      : (!lua.val, !lua.val) -> i1
    //  scf.yield %result : i1
    //} else {
    //  %false = constant 0 : i1
    //  scf.yield %false : i1
    //}
    //%ret = luac.wrap_bool %ret_b

    //%retv = luac.load_from %ret
    //return %retv : !lua.val
  }

  func @lua_ne(%lhsv: !lua.val, %rhsv: !lua.val) -> !lua.val {
    %lhs = luac.into_alloca %lhsv
    %rhs = luac.into_alloca %rhsv
    %lhs_num = luac.get_int_val %lhs
    %rhs_num = luac.get_int_val %rhs
    %b = cmpi "ne", %lhs_num, %rhs_num : i64
    %ret = luac.wrap_bool %b
    %retv = luac.load_from %ret
    return %retv : !lua.val
    //%are_eqv = call @lua_eq(%lhsv, %rhsv) : (!lua.val, !lua.val) -> !lua.val
    //%are_eq = luac.into_alloca %are_eqv

    //%are_eq_b = luac.get_bool_val %are_eq
    //%const1 = constant 1 : i1
    //%are_ne_b = xor %are_eq_b, %const1 : i1

    //%ret = luac.wrap_bool %are_ne_b

    //%retv = luac.load_from %ret
    //return %retv : !lua.val
  }

  func @lua_convert_bool_like(%valv: !lua.val) -> i1 {
    %val = luac.into_alloca %valv

    %type = luac.get_type type(%val)

    %nil_type = constant #luac.type_nil
    %is_nil = cmpi "eq", %type, %nil_type : !luac.type_enum

    %ret_b = scf.if %is_nil -> i1 {
      %false = constant 0 : i1
      scf.yield %false : i1
    } else {
      %bool_type = constant #luac.type_bool
      %is_bool = cmpi "eq", %type, %bool_type : !luac.type_enum
      %ret = scf.if %is_bool -> i1 {
        %b = luac.get_bool_val %val
        scf.yield %b : i1
      } else {
        %true = constant 1 : i1
        scf.yield %true : i1
      }
      scf.yield %ret : i1
    }

    return %ret_b : i1
  }

  func @lua_pack_insert_all(%pack: !lua.pack, %tail: !lua.pack, %idx: i32) {
    %zero = constant 0 : index
    %step = constant 1 : index

    %tailSz = luac.pack_get_size %tail
    %upper = index_cast %tailSz : i32 to index
    scf.for %i = %zero to %upper step %step {
      %tailIdx = index_cast %i : index to i32
      %obj = luac.pack_get_unsafe %tail[%tailIdx]
      %packIdx = addi %idx, %tailIdx : i32
      luac.pack_insert %pack[%packIdx] = %obj
    }
    return
  }

  func @lua_pack_get(%pack: !lua.pack, %idx: i32) -> !lua.val {
    %sz = luac.pack_get_size %pack
    %inside = cmpi "slt", %idx, %sz : i32

    %ret = scf.if %inside -> !lua.val {
      %ret_v = luac.pack_get_unsafe %pack[%idx]
      %retv = luac.load_from %ret_v
      scf.yield %retv : !lua.val
    } else {
      %ret_v = lua.nil
      %retv = luac.load_from %ret_v
      scf.yield %retv : !lua.val
    }
    return %ret : !lua.val
  }

  func @lua_table_get_impl(!luallvm.impl, !luallvm.value) -> !luallvm.value
  func @lua_table_set_impl(!luallvm.impl, !luallvm.value, !luallvm.value)
  func @lua_table_get_prealloc_impl(!luallvm.impl, i64) -> !luallvm.value
  func @lua_table_set_prealloc_impl(!luallvm.impl, i64, !luallvm.value)
  func @lua_make_fcn_impl(!luallvm.fcn, !luallvm.capture) -> !luallvm.impl
  func @lua_load_string_impl(!llvm.ptr<i8>, !llvm.i64) -> !luallvm.impl
  func @lua_new_table_impl() -> !luallvm.impl
  func @lua_abort()
}
