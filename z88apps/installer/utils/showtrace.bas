
 *NAME ShowTrace# dcfst=&06:dclast=&24:dccode=&0C#( gnfst=&06:gnlast=&78:gncode=&09#2 osfst=&CA:oslast=&FE:oscode=&06< othfst=&21:othlast=&8DF � DC$((dclast-dcfst)/2)P � GN$((gnlast-gnfst)/2)Z � OS$((oslast-osfst)/2)d � OT$((othlast-othfst)/3)n � I%=0 � (dclast-dcfst)/2x � DC$(I%)� � I%� � I%=0 � (gnlast-gnfst)/2� � GN$(I%)� � I%� � I%=0 � (oslast-osfst)/2� � OS$(I%)� � I%� � I%=0 � (othlast-othfst)/3� � OT$(I%)� � I%*� � X$:� X$<>"***" � � "Error in data":�� �-� � �(1);"3+UBTracefile Lister";�(1);"3-UB"�9� "Trace filename (default is :ram.-/oztrace.dat)";F$%� F$="" � F$=":ram.-/oztrace.dat""X%=�(F$)(,� F$="" � � "File not found!":� �TDA@�JA%=�_getvalueTB%=A% � 256:C%=A% � 256S^� B%=dccode � C%>=dcfst � C%<=dclast � (C% � 2)=0 � D$=DC$((C%-dcfst)/2):� �tPASh� B%=gncode � C%>=gnfst � C%<=gnlast � (C% � 2)=0 � D$=GN$((C%-gnfst)/2):� �tPASr� B%=oscode � C%>=osfst � C%<=oslast � (C% � 2)=0 � D$=OS$((C%-osfst)/2):� �tPAJ|� B%>=othfst � B%<=othlast � (B% � 3)=0 � D$=OT$((B%-othfst)/3):� �tPA�D$="??"�� D$;�8);�� "PC=";~�_getvalue;4�� �18);"AF=";~�_getvalue;�26);"BC=";~�_getvalue;4�� �34);"DE=";~�_getvalue;�42);"HL=";~�_getvalue;4�� �50);"IX=";~�_getvalue;�58);"IY=";~�_getvalue;�� �(0)<>-1 � �:� �=32��
�� �#X%��#X%��G�� Function to get next two bytes from file & form into 16-bit value�� �_getvalue� N%,M%N%=�#X%:M%=�#X%=N%+(256*M%))�� Call IDs for $xx0c [$060c to $240c]1�� "dc_ini","dc_bye","dc_ent","dc_nam","dc_in"0�� "dc_out","dc_prt","dc_icl","dc_nq","dc_sp"2� "dc_alt","dc_rbd","dc_xin","dc_gen","dc_pol"� "dc_scn")� Call IDs for $xx09 [$0609 to $7809]2$� "gn_gdt","gn_pdt","gn_gtm","gn_ptm","gn_sdo"2.� "gn_gdn","gn_pdn","gn_die","gn_dei","gn_gmd"28� "gn_gmt","gn_pmd","gn_pmt","gn_msc","gn_flo"2B� "gn_flc","gn_flw","gn_flr","gn_flf","gn_fpb"2L� "gn_nln","gn_cls","gn_skc","gn_skd","gn_skt"2V� "gn_sip","gn_sop","gn_soe","gn_rbe","gn_wbe"2`� "gn_cme","gn_xnx","gn_xin","gn_xdl","gn_err"2j� "gn_esp","gn_fcm","gn_fex","gn_opw","gn_wcl"2t� "gn_wfn","gn_prs","gn_pfs","gn_wsm","gn_esa"1~� "gn_opf","gn_cl","gn_del","gn_ren","gn_aab"2�� "gn_fab","gn_lab","gn_uab","gn_alp","gn_m16" �� "gn_d16","gn_m24","gn_d24")�� Call IDs for $xx06 [$ca06 to $fe06]2�� "os_wtb","os_wrt","os_wsq","os_isq","os_axp"2�� "os_sci","os_dly","os_blp","os_bde","os_bhl"2�� "os_fth","os_vth","os_gth","os_ren","os_del"0�� "os_cl","os_op","os_off","os_use","os_epr"2�� "os_ht","os_map","os_exit","os_stk","os_ent"�� "os_poll","os_dom":�� Call IDs for 1-byte calls [$21 to $8d in steps of 3]1�� "os_bye","os_prt","os_out","os_in","os_tin"0�� "os_xin","os_pur","os_ugb","os_gb","os_pb"1 � "os_gbt","os_pbt","os_mv","os_frm","os_fwm"2
� "os_mop","os_mcl","os_mal","os_mfr","os_mgb"0� "os_mpb","os_bix","os_box","os_nq","os_sp"1� "os_sr","os_esc","os_erc","os_erh","os_ust"2(� "os_fn","os_wait","os_alm","os_cli","os_dor"2� "os_fc","os_si"<� "***" ��