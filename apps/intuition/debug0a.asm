
     MODULE Intuition_8Klower

     ORG $2000

     ; Empty module - used only for ORIGIN and name purposes...

; define subroutines in external bank, globally available for this bank:

     XDEF Switch_bitnumber
     XDEF DisplayRegisters
     XDEF DZ_Z80pc, Display_OZ_Mnemonic
     XDEF Write_err_msg, Get_errmsg
     XDEF Debugger_version
     XDEF GetRegister
     XDEF Flagreg_changes
     XDEF Disp_window_ID, View_ApplScreen
     XDEF Hex_binary_disp, Binary_hex_disp, Ascii_hex_disp
     XDEF Hex_ascii_disp, Dec_hex_disp
     XDEF Mem_View, Mem_Edit, Mem_Search, Memory_free, ViewStack
     XDEF Toggle_TraceMode, Toggle_KbIntMode, Toggle_PauseMode, Toggle_DasmMode, Toggle_RegDump
     XDEF Toggle_brkpdump, Disp_toggleStat, Stack_boundary, Tracesubr_flag
     XDEF ToggleBreakPoint, Breakpoint_list, Toggle_BrkOZ, Toggle_DZopc
     XDEF Memory_dump, Segment_dump, Bank_dump
     XDEF Syntax_Error
     XDEF Disasm_param
     XDEF DefInstrBreak, InstrBreakList
     XDEF Command_line, Disp_RTM_Error
     XDEF SV_appl_window, RST_appl_window, Disp_monitor_win

     INCLUDE "debug0b.def"
