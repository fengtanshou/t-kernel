/*
 *----------------------------------------------------------------------
 *    T-Kernel 2.0 Software Package
 *
 *    Copyright 2011 by Ken Sakamura.
 *    This software is distributed under the latest version of T-License 2.x.
 *----------------------------------------------------------------------
 *
 *    Released by T-Engine Forum(http://www.t-engine.org/) at 2011/05/17.
 *    Modified by TRON Forum(http://www.tron.org/) at 2015/06/01.
 *
 *----------------------------------------------------------------------
 */

/*
 *	@(#)sysdef_common.h (tk)
 *
 *	System dependencies definition.
 *	Included also from assembler program.
 */

#ifndef __TK_SYSDEF_COMMON_H__
#define __TK_SYSDEF_COMMON_H__

#ifdef STD_SH7727
#  include <tk/sysdepend/std_sh7727/sysdef_depend.h>
#endif
#ifdef STD_SH7751R
#  include <tk/sysdepend/std_sh7751r/sysdef_depend.h>
#endif
#ifdef MIC_M32104
#  include <tk/sysdepend/mic_m32104/sysdef_depend.h>
#endif
#ifdef STD_S1C38K
#  include <tk/sysdepend/std_s1c38k/sysdef_depend.h>
#endif
#ifdef STD_MC9328
#  include <tk/sysdepend/std_mc9328/sysdef_depend.h>
#endif
#ifdef MIC_VR4131
#  include <tk/sysdepend/mic_vr4131/sysdef_depend.h>
#endif
#ifdef STD_VR5500
#  include <tk/sysdepend/std_vr5500/sysdef_depend.h>
#endif
#ifdef STD_MB87Q1100
#  include <tk/sysdepend/std_mb87q1100/sysdef_depend.h>
#endif
#ifdef STD_SH7760
#  include <tk/sysdepend/std_sh7760/sysdef_depend.h>
#endif
#ifdef TEF_EM1D
#  include <tk/sysdef_depend.h>
#endif

#endif /* __TK_SYSDEF_COMMON_H__ */
