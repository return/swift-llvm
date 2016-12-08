; RUN: llc -filetype=asm -O0 -mtriple=x86_64-linux-gnu < %s -dwarf-version 2 | FileCheck -check-prefixes=CHECK,ELF-ASM %s
; RUN: llc -filetype=obj -O0 %s -mtriple=x86_64-linux-gnu -o %t-2 -dwarf-version 2
; RUN: llvm-dwarfdump %t-2 | FileCheck %s -check-prefix=CHECK-DWARF
; RUN: llc -filetype=obj -O0 %s -mtriple=x86_64-linux-gnu -o %t-4 -dwarf-version 2
; RUN: llvm-dwarfdump %t-4 | FileCheck %s -check-prefix=CHECK-DWARF

; RUN: llc -filetype=asm -O0 -mtriple=x86_64-apple-darwin < %s -dwarf-version 2 | FileCheck -check-prefixes=CHECK,DARWIN-ASM2 %s
; RUN: llc -filetype=asm -O0 -mtriple=x86_64-apple-darwin < %s -dwarf-version 4 | FileCheck -check-prefixes=CHECK,DARWIN-ASM4 %s
; RUN: llc -filetype=obj %s -mtriple=x86_64-apple-darwin -o %t2-2 -dwarf-version 2
; RUN: llvm-dwarfdump %t2-2 | FileCheck %s -check-prefix=CHECK-DWARF
; RUN: llc -filetype=obj %s -mtriple=x86_64-apple-darwin -o %t2-4 -dwarf-version 4
; RUN: llvm-dwarfdump %t2-4 | FileCheck %s -check-prefix=CHECK-DWARF

; RUN: llc -filetype=asm -O0 -mtriple=x86_64-pc-win32 < %s -dwarf-version 2 | FileCheck -check-prefixes=CHECK,COFF-ASM %s
; RUN: llc -filetype=asm -O0 -mtriple=x86_64-pc-win32 < %s -dwarf-version 4 | FileCheck -check-prefixes=CHECK,COFF-ASM %s
; RUN: llc -filetype=obj -O0 %s -mtriple=x86_64-pc-win32 -o %t3-2 -dwarf-version 2
; RUN: llvm-dwarfdump %t3-2 | FileCheck %s -check-prefix=CHECK-DWARF2
; RUN: llc -filetype=obj -O0 %s -mtriple=x86_64-pc-win32 -o %t3-4 -dwarf-version 4
; RUN: llvm-dwarfdump %t3-4 | FileCheck %s -check-prefix=CHECK-DWARF

; Testing case generated from:
; clang++ tu1.cpp tu2.cpp -g -emit-llvm -c
; llvm-link tu1.bc tu2.bc -o tu12.ll -S
; cat hdr.h
; struct foo {
; };
; cat tu1.cpp
; #include "hdr.h"
; foo f;
; cat tu2.cpp
; #include "hdr.h"
; foo g;

; Make sure we use relocation for ref_addr on non-darwin platforms.
; CHECK: DW_TAG_compile_unit
; CHECK: DW_TAG_variable
; ELF-ASM: .long [[TYPE:.*]] # DW_AT_type
; DARWIN-ASM2: .long [[TYPE:.*]] ## DW_AT_type
; DARWIN-ASM4: .long [[TYPE:.*]] ## DW_AT_type
; COFF-ASM: .long [[TYPE:.*]] # DW_AT_type
; CHECK: DW_TAG_structure_type
; CHECK: cu_begin1
; CHECK: DW_TAG_compile_unit
; CHECK-NOT: DW_TAG_structure_type
; This variable's type is in the 1st CU.
; CHECK: DW_TAG_variable
; Make sure this is relocatable.
; and test that we don't create the labels to emit a correct COFF relocation
; ELF-ASM: .quad .Lsection_info+[[TYPE]] # DW_AT_type
; COFF-ASM: .secrel32 .Lsection_info+[[TYPE]] # DW_AT_type
; DARWIN-ASM2: .quad [[TYPE]] ## DW_AT_type
; DARWIN-ASM4: .long [[TYPE]] ## DW_AT_type
; CHECK-NOT: DW_TAG_structure_type
; CHECK: .section

; CHECK-DWARF: DW_TAG_compile_unit
; CHECK-DWARF: 0x[[ADDR:.*]]: DW_TAG_structure_type
; CHECK-DWARF: DW_TAG_compile_unit
; CHECK-DWARF: DW_TAG_variable
; CHECK-DWARF: DW_AT_type [DW_FORM_ref_addr] {{.*}}[[ADDR]])

; CHECK-DWARF2: DW_TAG_compile_unit
; CHECK-DWARF2: DW_TAG_variable
; CHECK-DWARF2: DW_AT_type [DW_FORM_ref4] {{.*}} => {[[ADDR:.*]]})
; CHECK-DWARF2: [[ADDR]]: DW_TAG_structure_type

%struct.foo = type { i8 }

@f = global %struct.foo zeroinitializer, align 1, !dbg !7
@g = global %struct.foo zeroinitializer, align 1, !dbg !12

!llvm.dbg.cu = !{!0, !9}
!llvm.module.flags = !{!14, !15}

!0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, producer: "clang version 3.4 (trunk 191799)", isOptimized: false, emissionKind: FullDebug, file: !1, enums: !2, retainedTypes: !3, globals: !6, imports: !2)
!1 = !DIFile(filename: "tu1.cpp", directory: "/Users/manmanren/test-Nov/type_unique_air/ref_addr")
!2 = !{}
!3 = !{!4}
!4 = !DICompositeType(tag: DW_TAG_structure_type, name: "foo", line: 1, size: 8, align: 8, file: !5, elements: !2, identifier: "_ZTS3foo")
!5 = !DIFile(filename: "./hdr.h", directory: "/Users/manmanren/test-Nov/type_unique_air/ref_addr")
!6 = !{!7}
!7 = !DIGlobalVariable(name: "f", line: 2, isLocal: false, isDefinition: true, scope: null, file: !8, type: !4)
!8 = !DIFile(filename: "tu1.cpp", directory: "/Users/manmanren/test-Nov/type_unique_air/ref_addr")
!9 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, producer: "clang version 3.4 (trunk 191799)", isOptimized: false, emissionKind: FullDebug, file: !10, enums: !2, retainedTypes: !3, globals: !11, imports: !2)
!10 = !DIFile(filename: "tu2.cpp", directory: "/Users/manmanren/test-Nov/type_unique_air/ref_addr")
!11 = !{!12}
!12 = !DIGlobalVariable(name: "g", line: 2, isLocal: false, isDefinition: true, scope: null, file: !13, type: !4)
!13 = !DIFile(filename: "tu2.cpp", directory: "/Users/manmanren/test-Nov/type_unique_air/ref_addr")
!14 = !{i32 2, !"Dwarf Version", i32 2}
!15 = !{i32 1, !"Debug Info Version", i32 3}
