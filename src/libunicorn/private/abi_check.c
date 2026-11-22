/* Build-time check that the Unicorn headers the C compiler sees agree with
 * the Nim bindings and with the version pkg-config reported. raw.nim passes
 * what the bindings assume as LUN_* macros. The bindings are generated from
 * the newest supported headers and serve every Unicorn 2: headers of another
 * release may declare fewer or more registers, constants and functions, but
 * never other numbers for the same names or other struct layouts, and that
 * is what is checked here. Valid as C and as C++. */

#include <stddef.h>

#if defined(__has_include)
#  if !__has_include(<unicorn/unicorn.h>) && __has_include(<unicorn.h>)
#    include <unicorn.h>
#  else
#    include <unicorn/unicorn.h>
#  endif
#else
#  include <unicorn/unicorn.h>
#endif

/* Two releases install a unicorn.pc that is one patch level behind their
 * unicorn.h: the tag 2.0.1 says 2.0.0 there and the tag 2.1.2 says 2.1.1.
 * (The build then takes the library for the older one, which is harmless:
 * nothing in the bindings depends on the patch level within 2.0.0 to 2.0.1
 * or within 2.1.1 to 2.1.2.) */
#define LUN_PC_ONE_BEHIND \
  ((UC_API_MINOR == 0 && UC_API_PATCH == 1 && LUN_LIB_PATCH == 0) || \
   (UC_API_MINOR == 1 && UC_API_PATCH == 2 && LUN_LIB_PATCH == 1))

#if UC_API_MAJOR != LUN_LIB_MAJOR || UC_API_MINOR != LUN_LIB_MINOR || \
    (UC_API_PATCH != LUN_LIB_PATCH && !LUN_PC_ONE_BEHIND)
#  error "libunicorn: unicorn.h is not the Unicorn version this build was configured for"
#endif

#if defined(__cplusplus) && __cplusplus >= 201103L
#  define LUN_CHECK(cond, msg) static_assert(cond, msg)
#elif defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
#  define LUN_CHECK(cond, msg) _Static_assert(cond, msg)
#else
#  define LUN_JOIN2(a, b) a##b
#  define LUN_JOIN(a, b) LUN_JOIN2(a, b)
#  define LUN_CHECK(cond, msg) typedef char LUN_JOIN(lun_check_, __LINE__)[(cond) ? 1 : -1]
#endif

LUN_CHECK(sizeof(uc_mem_region) == LUN_SIZEOF_MEM_REGION,
          "libunicorn: uc_mem_region layout differs from the Nim bindings");
LUN_CHECK(sizeof(uc_x86_mmr) == LUN_SIZEOF_X86_MMR,
          "libunicorn: uc_x86_mmr layout differs from the Nim bindings");
LUN_CHECK(sizeof(uc_x86_msr) == LUN_SIZEOF_X86_MSR,
          "libunicorn: uc_x86_msr layout differs from the Nim bindings");
LUN_CHECK(sizeof(uc_arm_cp_reg) == LUN_SIZEOF_ARM_CP_REG,
          "libunicorn: uc_arm_cp_reg layout differs from the Nim bindings");
LUN_CHECK(sizeof(uc_arm64_cp_reg) == LUN_SIZEOF_ARM64_CP_REG,
          "libunicorn: uc_arm64_cp_reg layout differs from the Nim bindings");
LUN_CHECK(sizeof(uc_tb) == LUN_SIZEOF_TB,
          "libunicorn: uc_tb layout differs from the Nim bindings");
#if UC_API_MINOR >= 1 /* uc_tlb_entry came with Unicorn 2.1.0 */
LUN_CHECK(sizeof(uc_tlb_entry) == LUN_SIZEOF_TLB_ENTRY &&
          offsetof(uc_tlb_entry, perms) == LUN_OFFSETOF_TLB_ENTRY_PERMS,
          "libunicorn: uc_tlb_entry layout differs from the Nim bindings");
#endif
LUN_CHECK(UC_ERR_EXCEPTION == LUN_ERR_EXCEPTION && UC_HOOK_TCG_OPCODE == LUN_HOOK_TCG_OPCODE &&
          UC_MEM_READ_AFTER == LUN_MEM_READ_AFTER,
          "libunicorn: enum numbering differs from the Nim bindings");
