/* Copyright (C) 2003, 2004, 2006, 2007  Matthijs van Duin <xmath@cpan.org>
 *
 * Copyright (C) 2010, 2011, 2013 Andrew Main (Zefram) <zefram@fysh.org>
 *
 * Parts from perl, which is Copyright (C) 1991-2013 Larry Wall and others
 *
 * You may distribute under the same terms as perl itself, which is either 
 * the GNU General Public License or the Artistic License.
 */

#define PERL_CORE
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


#ifdef USE_5005THREADS
#error "5.005 threads not supported by Data::Alias"
#endif


#ifndef PERL_COMBI_VERSION
#define PERL_COMBI_VERSION (PERL_REVISION * 1000000 + PERL_VERSION * 1000 + \
				PERL_SUBVERSION)
#endif

#if defined(USE_DTRACE) && defined(PERL_CORE)
#undef ENTRY_PROBE
#undef RETURN_PROBE
#if (PERL_COMBI_VERSION < 5013008)
#define ENTRY_PROBE(func, file, line)
#define RETURN_PROBE(func, file, line)
#else
#define ENTRY_PROBE(func, file, line, stash)
#define RETURN_PROBE(func, file, line, stash)
#endif
#endif

#if defined(PERL_CORE) && defined(MULTIPLICITY) && \
		(PERL_COMBI_VERSION < 5013006)
#undef PL_sv_placeholder
#define PL_sv_placeholder (*Perl_Gsv_placeholder_ptr(NULL))
#endif


#ifndef G_LIST
#define G_LIST G_ARRAY
#endif


#ifndef RenewOpc
#if defined(PL_OP_SLAB_ALLOC) || (PERL_COMBI_VERSION >= 5017002)
#define RenewOpc(m,v,n,t,c)		\
	STMT_START {			\
		t *tMp_;		\
		NewOp(m,tMp_,n,t);	\
		Copy(v,tMp_,n,t);	\
		FreeOp(v);		\
		v = (c*) tMp_;		\
	} STMT_END
#else
#if (PERL_COMBI_VERSION >= 5009004)
#define RenewOpc(m,v,n,t,c)		\
	(v = (MEM_WRAP_CHECK_(n,t)	\
	 (c*)PerlMemShared_realloc(v, (n)*sizeof(t))))
#else
#define RenewOpc(m,v,n,t,c)		\
	Renewc(v,n,t,c)
#endif
#endif
#endif

#ifndef RenewOp
#define RenewOp(m,v,n,t) \
	RenewOpc(m,v,n,t,t)
#endif


#ifdef avhv_keys
#define DA_FEATURE_AVHV 1
#endif

#if (PERL_COMBI_VERSION >= 5009003)
#define PL_no_helem PL_no_helem_sv
#endif

#ifndef SvPVX_const
#define SvPVX_const SvPVX
#endif

#ifndef SvREFCNT_inc_NN
#define SvREFCNT_inc_NN SvREFCNT_inc
#endif
#ifndef SvREFCNT_inc_simple_NN
#define SvREFCNT_inc_simple_NN SvREFCNT_inc_NN
#endif
#ifndef SvREFCNT_inc_simple_void_NN
#define SvREFCNT_inc_simple_void_NN SvREFCNT_inc_simple_NN
#endif

#ifndef GvGP_set
#define GvGP_set(gv, val) (GvGP(gv) = val)
#endif
#ifndef GvCV_set
#define GvCV_set(gv, val) (GvCV(gv) = val)
#endif

#if (PERL_COMBI_VERSION >= 5009003)
#define DA_FEATURE_MULTICALL 1
#endif

#if (PERL_COMBI_VERSION >= 5009002)
#define DA_FEATURE_RETOP 1
#endif

#define INT2SIZE(x) ((MEM_SIZE)(SSize_t)(x))
#define DA_ARRAY_MAXIDX ((IV) (INT2SIZE(-1) / (2 * sizeof(SV *))) )

#ifndef Nullsv
#define Nullsv ((SV*)NULL)
#endif

#ifndef Nullop
#define Nullop ((OP*)NULL)
#endif

#ifndef lex_end
#define lex_end() ((void) 0)
#endif

#ifndef op_lvalue
#define op_lvalue(o, t) mod(o, t)
#endif

#define DA_HAVE_OP_PADRANGE (PERL_COMBI_VERSION >= 5017006)

#if DA_HAVE_OP_PADRANGE
#define IS_PUSHMARK_OR_PADRANGE(op) \
	((op)->op_type == OP_PUSHMARK || (op)->op_type == OP_PADRANGE)
#else
#define IS_PUSHMARK_OR_PADRANGE(op) ((op)->op_type == OP_PUSHMARK)
#endif

#if (PERL_COMBI_VERSION >= 5011000) && !defined(SVt_RV)
#define SVt_RV SVt_IV
#endif

#if (PERL_COMBI_VERSION >= 5006000) && (PERL_COMBI_VERSION < 5011000)
#define case_OP_SETSTATE_ case OP_SETSTATE:
#else
#define case_OP_SETSTATE_
#endif

#if (PERL_COMBI_VERSION >= 5011002)
static char const msg_no_symref[] =
	"Can't use string (\"%.32s\") as %s ref while \"strict refs\" in use";
#else
#define msg_no_symref PL_no_symref
#endif

#if (PERL_COMBI_VERSION >= 5009005)
#ifdef PERL_MAD
#error "Data::Alias doesn't support Misc Attribute Decoration yet"
#endif
#define PL_lex_defer		(PL_parser->lex_defer)
#define PL_lex_expect		(PL_parser->lex_expect)
#define PL_linestr		(PL_parser->linestr)
#define PL_expect		(PL_parser->expect)
#define PL_bufptr		(PL_parser->bufptr)
#define PL_oldbufptr		(PL_parser->oldbufptr)
#define PL_oldoldbufptr		(PL_parser->oldoldbufptr)
#define PL_bufend		(PL_parser->bufend)
#define PL_last_uni		(PL_parser->last_uni)
#define PL_last_lop		(PL_parser->last_lop)
#define PL_lex_state		(PL_parser->lex_state)
#define PL_nexttoke		(PL_parser->nexttoke)
#define PL_nexttype		(PL_parser->nexttype)
#define PL_tokenbuf		(PL_parser->tokenbuf)
#define PL_yylval		(PL_parser->yylval)
#elif (PERL_COMBI_VERSION >= 5009001)
#define PL_yylval		(*PL_yylvalp)
#endif


#define OPpALIASAV  2
#define OPpALIASHV  4
#define OPpALIAS (OPpALIASAV | OPpALIASHV)

#define OPpUSEFUL 128

#define MOD(op) op_lvalue((op), OP_GREPSTART)

#ifndef SVs_PADBUSY
#define SVs_PADBUSY 0
#endif
#define SVs_PADFLAGS (SVs_PADBUSY|SVs_PADMY|SVs_PADTMP)

#ifdef pp_dorassign
#define DA_HAVE_OP_DORASSIGN 1
#else
#define DA_HAVE_OP_DORASSIGN (PERL_COMBI_VERSION >= 5009000)
#endif

#define DA_TIED_ERR "Can't %s alias %s tied %s"
#define DA_ODD_HASH_ERR "Odd number of elements in hash assignment"
#define DA_TARGET_ERR "Unsupported alias target"
#define DA_TARGET_ERR_AT "Unsupported alias target at %s line %"UVuf"\n"
#define DA_DEREF_ERR "Can't deref string (\"%.32s\")"
#define DA_OUTER_ERR "Aliasing of outer lexical variable has limited scope"

#define _PUSHaa(a1,a2) PUSHs((SV*)(Size_t)(a1));PUSHs((SV*)(Size_t)(a2))
#define PUSHaa(a1,a2) STMT_START { _PUSHaa(a1,a2); } STMT_END
#define XPUSHaa(a1,a2) STMT_START { EXTEND(sp,2); _PUSHaa(a1,a2); } STMT_END

#define DA_ALIAS_PAD	((Size_t) -1)
#define DA_ALIAS_RV	((Size_t) -2)
#define DA_ALIAS_GV	((Size_t) -3)
#define DA_ALIAS_AV	((Size_t) -4)
#define DA_ALIAS_HV	((Size_t) -5)

STATIC OP *(*da_old_ck_rv2cv)(pTHX_ OP *op);
STATIC OP *(*da_old_ck_entersub)(pTHX_ OP *op);

#ifdef USE_ITHREADS

#define DA_GLOBAL_KEY "Data::Alias::_global"
#define DA_FETCH(create) hv_fetch(PL_modglobal, DA_GLOBAL_KEY, \
					sizeof(DA_GLOBAL_KEY) - 1, create)
#define DA_ACTIVE ((_dap = DA_FETCH(FALSE)) && (_da = *_dap))
#define DA_INIT STMT_START { _dap = DA_FETCH(TRUE); _da = *_dap; \
		sv_upgrade(_da, SVt_PVLV); LvTYPE(_da) = 't'; } STMT_END

#define dDA SV *_da, **_dap
#define dDAforce SV *_da = *DA_FETCH(FALSE)

#define da_inside (*(I32 *) &SvIVX(_da))
#define da_iscope (*(PERL_CONTEXT **) &SvPVX(_da))
#define da_cv (*(CV **) &LvTARGOFF(_da))
#define da_cvc (*(CV **) &LvTARGLEN(_da))

#else

#define dDA dNOOP
#define dDAforce dNOOP
#define DA_ACTIVE 42
#define DA_INIT

STATIC CV *da_cv, *da_cvc;
STATIC I32 da_inside;
STATIC PERL_CONTEXT *da_iscope;

#endif

STATIC void (*da_old_peepp)(pTHX_ OP *);

STATIC OP *da_tag_rv2cv(pTHX) { return NORMAL; }
STATIC OP *da_tag_list(pTHX) { return NORMAL; }
STATIC OP *da_tag_entersub(pTHX) { return NORMAL; }

STATIC void da_peep(pTHX_ OP *o);
STATIC void da_peep2(pTHX_ OP *o);

STATIC SV *da_fetch(pTHX_ SV *a1, SV *a2) {
	switch ((Size_t) a1) {
	case DA_ALIAS_PAD:
		return PL_curpad[(Size_t) a2];
	case DA_ALIAS_RV:
		if (SvTYPE(a2) == SVt_PVGV)
			a2 = GvSV(a2);
		else if (!SvROK(a2) || !(a2 = SvRV(a2))
			|| (SvTYPE(a2) > SVt_PVLV && SvTYPE(a2) != SVt_PVGV))
			Perl_croak(aTHX_ "Not a SCALAR reference");
	case DA_ALIAS_GV:
		return a2;
	case DA_ALIAS_AV:
	case DA_ALIAS_HV:
		break;
	default:
		switch (SvTYPE(a1)) {
			SV **svp;
			HE *he;
		case SVt_PVAV:
			svp = av_fetch((AV *) a1, (Size_t) a2, FALSE);
			return svp ? *svp : &PL_sv_undef;
		case SVt_PVHV:
			he = hv_fetch_ent((HV *) a1, a2, FALSE, 0);
			return he ? HeVAL(he) : &PL_sv_undef;
		default:
			/* suppress warning */ ;
		}
	}
	Perl_croak(aTHX_ DA_TARGET_ERR);
	return NULL; /* suppress warning on win32 */
}

#define PREP_ALIAS_INC(sV)						\
	STMT_START {							\
		if (SvPADTMP(sV) && !IS_PADGV(sV)) {			\
			sV = newSVsv(sV);				\
			SvREADONLY_on(sV);				\
		} else {						\
			switch (SvTYPE(sV)) {				\
			case SVt_PVLV:					\
				if (LvTYPE(sV) == 'y') {		\
					if (LvTARGLEN(sV))		\
						vivify_defelem(sV);	\
					sV = LvTARG(sV);		\
					if (!sV)			\
						sV = &PL_sv_undef;	\
				}					\
				break;					\
			case SVt_PVAV:					\
				if (!AvREAL((AV *) sV) && AvREIFY((AV *) sV)) \
					av_reify((AV *) sV);		\
				break;					\
			default:					\
				/* suppress warning */ ;		\
			}						\
			SvTEMP_off(sV);					\
			SvREFCNT_inc_simple_void_NN(sV);		\
		}							\
	} STMT_END

STATIC void da_restore_gvcv(pTHX_ void *gv_v) {
	GV *gv = (GV*)gv_v;
	CV *restcv = (CV *) SSPOPPTR;
	CV *oldcv = GvCV(gv);
	GvCV_set(gv, restcv);
	SvREFCNT_dec(oldcv);
	SvREFCNT_dec((SV *) gv);
}

STATIC void da_alias(pTHX_ SV *a1, SV *a2, SV *value) {
	PREP_ALIAS_INC(value);
	if ((Size_t) a1 == DA_ALIAS_PAD) {
		SV *old = PL_curpad[(Size_t) a2];
		PL_curpad[(Size_t) a2] = value;
		SvFLAGS(value) |= (SvFLAGS(old) & SVs_PADFLAGS);
		if (old != &PL_sv_undef)
			SvREFCNT_dec(old);
		return;
	}
	switch ((Size_t) a1) {
		SV **svp;
		GV *gv;
	case DA_ALIAS_RV:
		if (SvTYPE(a2) == SVt_PVGV) {
			sv_2mortal(value);
			goto globassign;
		}
		value = newRV_noinc(value);
		goto refassign;
	case DA_ALIAS_GV:
		if (!SvROK(value)) {
		refassign:
			SvSetMagicSV(a2, value);
			SvREFCNT_dec(value);
			return;
		}
		value = SvRV(sv_2mortal(value));
	globassign:
		gv = (GV *) a2;
#ifdef GV_UNIQUE_CHECK
		if (GvUNIQUE(gv))
			Perl_croak(aTHX_ PL_no_modify);
#endif
		switch (SvTYPE(value)) {
			CV *oldcv;
		case SVt_PVCV:
			oldcv = GvCV(gv);
			if (oldcv != (CV *) value) {
				if (GvCVGEN(gv)) {
					GvCV_set(gv, NULL);
					GvCVGEN(gv) = 0;
					SvREFCNT_dec((SV *) oldcv);
					oldcv = NULL;
				}
				PL_sub_generation++;
			}
			GvMULTI_on(gv);
			if (GvINTRO(gv)) {
				SvREFCNT_inc_simple_void_NN((SV *) gv);
				SvREFCNT_inc_simple_void_NN(value);
				GvINTRO_off(gv);
				SSCHECK(1);
				SSPUSHPTR((SV *) oldcv);
				SAVEDESTRUCTOR_X(da_restore_gvcv, (void*)gv);
				GvCV_set(gv, (CV*)value);
			} else {
				SvREFCNT_inc_simple_void_NN(value);
				GvCV_set(gv, (CV*)value);
				SvREFCNT_dec((SV *) oldcv);
			}
			return;
		case SVt_PVAV:	svp = (SV **) &GvAV(gv); break;
		case SVt_PVHV:	svp = (SV **) &GvHV(gv); break;
		case SVt_PVFM:	svp = (SV **) &GvFORM(gv); break;
		case SVt_PVIO:	svp = (SV **) &GvIOp(gv); break;
		default:	svp = &GvSV(gv);
		}
		GvMULTI_on(gv);
		if (GvINTRO(gv)) {
			GvINTRO_off(gv);
			SAVEGENERICSV(*svp);
			*svp = SvREFCNT_inc_simple_NN(value);
		} else {
			SV *old = *svp;
			*svp = SvREFCNT_inc_simple_NN(value);
			SvREFCNT_dec(old);
		}
		return;
	case DA_ALIAS_AV:
	case DA_ALIAS_HV:
		break;
	default:
		switch (SvTYPE(a1)) {
		case SVt_PVAV:
			if (!av_store((AV *) a1, (Size_t) a2, value))
				SvREFCNT_dec(value);
			return;
		case SVt_PVHV:
			if (value == &PL_sv_undef) {
				(void) hv_delete_ent((HV *) a1, a2,
					G_DISCARD, 0);
			} else {
				if (!hv_store_ent((HV *) a1, a2, value, 0))
					SvREFCNT_dec(value);
			}
			return;
		default:
			/* suppress warning */ ;
		}
	}
	SvREFCNT_dec(value);
	Perl_croak(aTHX_ DA_TARGET_ERR);
}

STATIC void da_unlocalize_gvar(pTHX_ void *gp_v) {
	GP *gp = (GP*) gp_v;
	SV *value = (SV *) SSPOPPTR;
	SV **sptr = (SV **) SSPOPPTR;
	SV *old = *sptr;
	*sptr = value;
	SvREFCNT_dec(old);

	if (gp->gp_refcnt > 1) {
		--gp->gp_refcnt;
	} else {
		SV *gv = newSV(0);
		sv_upgrade(gv, SVt_PVGV);
		SvSCREAM_on(gv);
		GvGP_set(gv, gp);
		sv_free(gv);
	}
}

STATIC void da_localize_gvar(pTHX_ GP *gp, SV **sptr) {
	SSCHECK(2);
	SSPUSHPTR(sptr);
	SSPUSHPTR(*sptr);
	SAVEDESTRUCTOR_X(da_unlocalize_gvar, (void*)gp);
	++gp->gp_refcnt;
	*sptr = Nullsv;
}

STATIC SV *da_refgen(pTHX_ SV *sv) {
	SV *rv;
	PREP_ALIAS_INC(sv);
	rv = sv_newmortal();
	sv_upgrade(rv, SVt_RV);
	SvRV(rv) = sv;
	SvROK_on(rv);
	SvREADONLY_on(rv);
	return rv;
}

STATIC OP *DataAlias_pp_srefgen(pTHX) {
	dSP;
	SETs(da_refgen(aTHX_ TOPs));
	RETURN;
}

STATIC OP *DataAlias_pp_refgen(pTHX) {
	dSP; dMARK;
	if (GIMME_V != G_LIST) {
		++MARK;
		*MARK = da_refgen(aTHX_ MARK <= SP ? TOPs : &PL_sv_undef);
		SP = MARK;
	} else {
		EXTEND_MORTAL(SP - MARK);
		while (++MARK <= SP)
			*MARK = da_refgen(aTHX_ *MARK);
	}
	RETURN;
}

STATIC OP *DataAlias_pp_anonlist(pTHX) {
	dSP; dMARK;
	I32 i = SP - MARK;
	AV *av = newAV();
	SV **svp, *sv;
	av_extend(av, i - 1);
	AvFILLp(av) = i - 1;
	svp = AvARRAY(av);
	while (i--)
		SvTEMP_off(svp[i] = SvREFCNT_inc_NN(POPs));
	if (PL_op->op_flags & OPf_SPECIAL) {
		sv = da_refgen(aTHX_ (SV *) av);
		SvREFCNT_dec((SV *) av);
	} else {
		sv = sv_2mortal((SV *) av);
	}
	XPUSHs(sv);
	RETURN;
}

STATIC OP *DataAlias_pp_anonhash(pTHX) {
	dSP; dMARK; dORIGMARK;
	HV *hv = (HV *) newHV();
	SV *sv;
	while (MARK < SP) {
		SV *key = *++MARK;
		SV *val = &PL_sv_undef;
		if (MARK < SP)
			SvTEMP_off(val = SvREFCNT_inc_NN(*++MARK));
		else if (ckWARN(WARN_MISC))
			Perl_warner(aTHX_ packWARN(WARN_MISC),
				"Odd number of elements in anonymous hash");
		if (val == &PL_sv_undef)
			(void) hv_delete_ent(hv, key, G_DISCARD, 0);
		else
			(void) hv_store_ent(hv, key, val, 0);
	}
	SP = ORIGMARK;
	if (PL_op->op_flags & OPf_SPECIAL) {
		sv = da_refgen(aTHX_ (SV *) hv);
		SvREFCNT_dec((SV *) hv);
	} else {
		sv = sv_2mortal((SV *) hv);
	}
	XPUSHs(sv);
	RETURN;
}

STATIC OP *DataAlias_pp_aelemfast(pTHX) {
	dSP;
	AV *av =
#if (PERL_COMBI_VERSION >= 5015000)
		PL_op->op_type == OP_AELEMFAST_LEX ?
#else
		(PL_op->op_flags & OPf_SPECIAL) ?
#endif
			(AV *) PAD_SV(PL_op->op_targ) : GvAVn(cGVOP_gv);
	IV index = PL_op->op_private;
	if (!av_fetch(av, index, TRUE))
		DIE(aTHX_ PL_no_aelem, index);
	XPUSHaa(av, index);
	RETURN;
}

STATIC bool da_badmagic(pTHX_ SV *sv) {
	MAGIC *mg = SvMAGIC(sv);
	while (mg) {
		if (isUPPER(mg->mg_type))
			return TRUE;
		mg = mg->mg_moremagic;
	}
	return FALSE;
}

STATIC OP *DataAlias_pp_aelem(pTHX) {
	dSP;
	SV *elem = POPs, **svp;
	AV *av = (AV *) POPs;
	IV index = SvIV(elem);
	if (SvRMAGICAL(av) && da_badmagic(aTHX_ (SV *) av))
		DIE(aTHX_ DA_TIED_ERR, "put", "into", "array");
	if (SvROK(elem) && !SvGAMAGIC(elem) && ckWARN(WARN_MISC))
		Perl_warner(aTHX_ packWARN(WARN_MISC),
			"Use of reference \"%"SVf"\" as array index", elem);
	if (SvTYPE(av) != SVt_PVAV)
		RETPUSHUNDEF;
	if (index > DA_ARRAY_MAXIDX || !(svp = av_fetch(av, index, TRUE)))
		DIE(aTHX_ PL_no_aelem, index);
	if (PL_op->op_private & OPpLVAL_INTRO)
		save_aelem(av, index, svp);
	PUSHaa(av, index);
	RETURN;
}

#if DA_FEATURE_AVHV
STATIC I32 da_avhv_index(pTHX_ AV *av, SV *key) {
	HV *keys = (HV *) SvRV(*AvARRAY(av));
	HE *he = hv_fetch_ent(keys, key, FALSE, 0);
	I32 index;
	if (!he)
		Perl_croak(aTHX_ "No such pseudo-hash field \"%s\"",
				SvPV_nolen(key));
	if ((index = SvIV(HeVAL(he))) <= 0)
		Perl_croak(aTHX_ "Bad index while coercing array into hash");
	if (index > AvMAX(av)) {
		I32 real = AvREAL(av);
		AvREAL_on(av);
		av_extend(av, index);
		if (!real)
			AvREAL_off(av);
	}
	return index;
}
#endif

STATIC OP *DataAlias_pp_helem(pTHX) {
	dSP;
	SV *key = POPs;
	HV *hv = (HV *) POPs;
	HE *he;
	if (SvRMAGICAL(hv) && da_badmagic(aTHX_ (SV *) hv))
		DIE(aTHX_ DA_TIED_ERR, "put", "into", "hash");
	if (SvTYPE(hv) == SVt_PVHV) {
		if (!(he = hv_fetch_ent(hv, key, TRUE, 0)))
			DIE(aTHX_ PL_no_helem, SvPV_nolen(key));
		if (PL_op->op_private & OPpLVAL_INTRO)
			save_helem(hv, key, &HeVAL(he));
	}
#if DA_FEATURE_AVHV
	else if (SvTYPE(hv) == SVt_PVAV && avhv_keys((AV *) hv)) {
		I32 i = da_avhv_index(aTHX_ (AV *) hv, key);
		if (PL_op->op_private & OPpLVAL_INTRO)
			save_aelem((AV *) hv, i, &AvARRAY(hv)[i]);
		key = (SV *) (Size_t) i;
	}
#endif
	else {
		hv = (HV *) &PL_sv_undef;
		key = NULL;
	}
	PUSHaa(hv, key);
	RETURN;
}

STATIC OP *DataAlias_pp_aslice(pTHX) {
	dSP; dMARK;
	AV *av = (AV *) POPs;
	IV max, count;
	SV **src, **dst;
	const U32 local = PL_op->op_private & OPpLVAL_INTRO;
	if (SvTYPE(av) != SVt_PVAV)
		DIE(aTHX_ "Not an array");
	if (SvRMAGICAL(av) && da_badmagic(aTHX_ (SV *) av))
		DIE(aTHX_ DA_TIED_ERR, "put", "into", "array");
	count = SP - MARK;
	EXTEND(sp, count);
	src = SP;
	dst = SP += count;
	max = AvFILLp(av);
	count = max + 1;
	while (MARK < src) {
		IV i = SvIVx(*src);
		if (i > DA_ARRAY_MAXIDX || (i < 0 && (i += count) < 0))
			DIE(aTHX_ PL_no_aelem, SvIVX(*src));
		if (local)
			save_aelem(av, i, av_fetch(av, i, TRUE));
		if (i > max)
			max = i;
		*dst-- = (SV *) (Size_t) i;
		*dst-- = (SV *) av;
		--src;
	}
	if (max > AvMAX(av))
		av_extend(av, max);
	RETURN;
}

STATIC OP *DataAlias_pp_hslice(pTHX) {
	dSP; dMARK;
	HV *hv = (HV *) POPs;
	SV *key;
	HE *he;
	SV **src, **dst;
	IV i = SP - MARK;
	if (SvRMAGICAL(hv) && da_badmagic(aTHX_ (SV *) hv))
		DIE(aTHX_ DA_TIED_ERR, "put", "into", "hash");
	EXTEND(sp, i);
	src = SP;
	dst = SP += i;
	if (SvTYPE(hv) == SVt_PVHV) {
		while (MARK < src) {
			if (!(he = hv_fetch_ent(hv, key = *src--, TRUE, 0)))
				DIE(aTHX_ PL_no_helem, SvPV_nolen(key));
			if (PL_op->op_private & OPpLVAL_INTRO)
				save_helem(hv, key, &HeVAL(he));
			*dst-- = key;
			*dst-- = (SV *) hv;
		}
	}
#if DA_FEATURE_AVHV
	else if (SvTYPE(hv) == SVt_PVAV && avhv_keys((AV *) hv)) {
		while (MARK < src) {
			i = da_avhv_index(aTHX_ (AV *) hv, key = *src--);
			if (PL_op->op_private & OPpLVAL_INTRO)
				save_aelem((AV *) hv, i, &AvARRAY(hv)[i]);
			*dst-- = (SV *) (Size_t) i;
			*dst-- = (SV *) hv;
		}
	}
#endif
	else {
		DIE(aTHX_ "Not a hash");
	}
	RETURN;
}

#if DA_HAVE_OP_PADRANGE

STATIC OP *DataAlias_pp_padrange_generic(pTHX_ bool is_single) {
	dSP;
	IV start = PL_op->op_targ;
	IV count = PL_op->op_private & OPpPADRANGE_COUNTMASK;
	IV index;
	if (PL_op->op_flags & OPf_SPECIAL) {
		AV *av = GvAVn(PL_defgv);
		PUSHMARK(SP);
		if (is_single) {
			XPUSHs((SV*)av);
		} else {
			const I32 maxarg = AvFILL(av) + 1;
			EXTEND(SP, maxarg);
			if (SvRMAGICAL(av)) {
				U32 i;
				for (i=0; i < (U32)maxarg; i++) {
					SV ** const svp =
						av_fetch(av, i, FALSE);
					SP[i+1] = svp ?
						SvGMAGICAL(*svp) ?
							(mg_get(*svp), *svp) :
							*svp :
						&PL_sv_undef;
				}
			} else {
				Copy(AvARRAY(av), SP+1, maxarg, SV*);
			}
			SP += maxarg;
		}
	}
	if ((PL_op->op_flags & OPf_WANT) != OPf_WANT_VOID) {
		PUSHMARK(SP);
		EXTEND(SP, count << 1);
	}
	for(index = start; index != start+count; index++) {
		Size_t da_type;
		if (is_single) {
			da_type = DA_ALIAS_PAD;
		} else {
			switch(SvTYPE(PAD_SVl(index))) {
				case SVt_PVAV: da_type = DA_ALIAS_AV; break;
				case SVt_PVHV: da_type = DA_ALIAS_HV; break;
				default: da_type = DA_ALIAS_PAD; break;
			}
		}
		if (PL_op->op_private & OPpLVAL_INTRO) {
			if (da_type == DA_ALIAS_PAD) {
				SAVEGENERICSV(PAD_SVl(index));
				PAD_SVl(index) = &PL_sv_undef;
			} else {
				SAVECLEARSV(PAD_SVl(index));
			}
		}
		if ((PL_op->op_flags & OPf_WANT) != OPf_WANT_VOID)
			PUSHaa(da_type, da_type == DA_ALIAS_PAD ?
						(Size_t)index :
						(Size_t)PAD_SVl(index));
	}
	RETURN;
}

STATIC OP *DataAlias_pp_padrange_list(pTHX) {
	return DataAlias_pp_padrange_generic(aTHX_ 0);
}

STATIC OP *DataAlias_pp_padrange_single(pTHX) {
	return DataAlias_pp_padrange_generic(aTHX_ 1);
}

#endif

STATIC OP *DataAlias_pp_padsv(pTHX) {
	dSP;
	IV index = PL_op->op_targ;
	if (PL_op->op_private & OPpLVAL_INTRO) {
		SAVEGENERICSV(PAD_SVl(index));
		PAD_SVl(index) = &PL_sv_undef;
	}
	XPUSHaa(DA_ALIAS_PAD, index);
	RETURN;
}

STATIC OP *DataAlias_pp_padav(pTHX) {
	dSP; dTARGET;
	if (PL_op->op_private & OPpLVAL_INTRO)
		SAVECLEARSV(PAD_SVl(PL_op->op_targ));
	XPUSHaa(DA_ALIAS_AV, TARG);
	RETURN;
}

STATIC OP *DataAlias_pp_padhv(pTHX) {
	dSP; dTARGET;
	if (PL_op->op_private & OPpLVAL_INTRO)
		SAVECLEARSV(PAD_SVl(PL_op->op_targ));
	XPUSHaa(DA_ALIAS_HV, TARG);
	RETURN;
}

STATIC OP *DataAlias_pp_gvsv(pTHX) {
	dSP;
	GV *gv = cGVOP_gv;
	if (PL_op->op_private & OPpLVAL_INTRO) {
		da_localize_gvar(aTHX_ GvGP(gv), &GvSV(gv));
		GvSV(gv) = newSV(0);
	}
	XPUSHaa(DA_ALIAS_RV, gv);
	RETURN;
}

STATIC OP *DataAlias_pp_gvsv_r(pTHX) {
	dSP;
	GV *gv = cGVOP_gv;
	if (PL_op->op_private & OPpLVAL_INTRO) {
		da_localize_gvar(aTHX_ GvGP(gv), &GvSV(gv));
		GvSV(gv) = newSV(0);
	}
	XPUSHs(GvSV(gv));
	RETURN;
}

STATIC GV *fixglob(pTHX_ GV *gv) {
	SV **svp = hv_fetch(GvSTASH(gv), GvNAME(gv), GvNAMELEN(gv), FALSE);
	GV *egv;
	if (!svp || !(egv = (GV *) *svp) || GvGP(egv) != GvGP(gv))
		return gv;
	GvEGV(gv) = egv;
	return egv;
}

STATIC OP *DataAlias_pp_rv2sv(pTHX) {
	dSP; dPOPss;
	if (!SvROK(sv) && SvTYPE(sv) != SVt_PVGV) do {
		const char *tname;
		U32 type;
		switch (PL_op->op_type) {
		case OP_RV2AV:	type = SVt_PVAV; tname = "an ARRAY"; break;
		case OP_RV2HV:	type = SVt_PVHV; tname = "a HASH";   break;
		default:	type = SVt_PV;   tname = "a SCALAR";
		}
		if (SvGMAGICAL(sv)) {
			mg_get(sv);
			if (SvROK(sv))
				break;
		}
		if (!SvOK(sv))
			break;
		if (PL_op->op_private & HINT_STRICT_REFS)
			DIE(aTHX_ msg_no_symref, SvPV_nolen(sv), tname);
		sv = (SV *) gv_fetchpv(SvPV_nolen(sv), TRUE, type);
	} while (0);
	if (SvTYPE(sv) == SVt_PVGV)
		sv = (SV *) (GvEGV(sv) ? GvEGV(sv) : fixglob(aTHX_ (GV *) sv));
	if (PL_op->op_private & OPpLVAL_INTRO) {
		if (SvTYPE(sv) != SVt_PVGV || SvFAKE(sv))
			DIE(aTHX_ "%s", PL_no_localize_ref);
		switch (PL_op->op_type) {
		case OP_RV2AV:
			da_localize_gvar(aTHX_ GvGP(sv), (SV **) &GvAV(sv));
			break;
		case OP_RV2HV:
			da_localize_gvar(aTHX_ GvGP(sv), (SV **) &GvHV(sv));
			break;
		default:
			da_localize_gvar(aTHX_ GvGP(sv), &GvSV(sv));
			GvSV(sv) = newSV(0);
		}
	}
	XPUSHaa(DA_ALIAS_RV, sv);
	RETURN;
}

STATIC OP *DataAlias_pp_rv2sv_r(pTHX) {
	U8 savedflags;
	OP *op = PL_op, *ret;

	DataAlias_pp_rv2sv(aTHX);
	PL_stack_sp[-1] = PL_stack_sp[0];
	--PL_stack_sp;

	savedflags = op->op_private;
	op->op_private = savedflags & ~OPpLVAL_INTRO;

	ret = PL_ppaddr[op->op_type](aTHX);

	op->op_private = savedflags;

	return ret;
}

STATIC OP *DataAlias_pp_rv2gv(pTHX) {
	dSP; dPOPss;
	if (SvROK(sv)) {
	wasref:	sv = SvRV(sv);
		if (SvTYPE(sv) != SVt_PVGV)
			DIE(aTHX_ "Not a GLOB reference");
	} else if (SvTYPE(sv) != SVt_PVGV) {
		if (SvGMAGICAL(sv)) {
			mg_get(sv);
			if (SvROK(sv))
				goto wasref;
		}
		if (!SvOK(sv))
			DIE(aTHX_ PL_no_usym, "a symbol");
		if (PL_op->op_private & HINT_STRICT_REFS)
			DIE(aTHX_ msg_no_symref, SvPV_nolen(sv), "a symbol");
		sv = (SV *) gv_fetchpv(SvPV_nolen(sv), TRUE, SVt_PVGV);
	}
	if (SvTYPE(sv) == SVt_PVGV)
		sv = (SV *) (GvEGV(sv) ? GvEGV(sv) : fixglob(aTHX_ (GV *) sv));
	if (PL_op->op_private & OPpLVAL_INTRO)
		save_gp((GV *) sv, !(PL_op->op_flags & OPf_SPECIAL));
	XPUSHaa(DA_ALIAS_GV, sv);
	RETURN;
}

STATIC OP *DataAlias_pp_rv2av(pTHX) {
	OP *ret = PL_ppaddr[OP_RV2AV](aTHX);
	dSP;
	SV *av = POPs;
	XPUSHaa(DA_ALIAS_AV, av);
	PUTBACK;
	return ret;
}

STATIC OP *DataAlias_pp_rv2hv(pTHX) {
	OP *ret = PL_ppaddr[OP_RV2HV](aTHX);
	dSP;
	SV *hv = POPs;
	XPUSHaa(DA_ALIAS_HV, hv);
	PUTBACK;
	return ret;
}

STATIC OP *DataAlias_pp_sassign(pTHX) {
	dSP;
	SV *a1, *a2, *value;
	if (PL_op->op_private & OPpASSIGN_BACKWARDS) {
		value = POPs, a2 = POPs, a1 = TOPs;
		SETs(value);
	} else {
		a2 = POPs, a1 = POPs, value = TOPs;
	}
	da_alias(aTHX_ a1, a2, value);
	RETURN;
}

STATIC OP *DataAlias_pp_aassign(pTHX) {
	dSP;
	SV **left, **llast, **right, **rlast;
	I32 gimme = GIMME_V;
	I32 done = FALSE;
	EXTEND(sp, 1);
	left  = POPMARK + PL_stack_base + 1;
	llast = SP;
	right = POPMARK + PL_stack_base + 1;
	rlast = left - 1;
	if (PL_op->op_private & OPpALIAS) {
		U32 hash = (PL_op->op_private & OPpALIASHV);
		U32 type = hash ? SVt_PVHV : SVt_PVAV;
		SV *a2 = POPs;
		SV *a1 = POPs;
		OPCODE savedop;
		if (SP != rlast)
			DIE(aTHX_ "Panic: unexpected number of lvalues");
		PUTBACK;
		if (right != rlast || SvTYPE(*right) != type) {
			PUSHMARK(right - 1);
			hash ? DataAlias_pp_anonhash(aTHX) : DataAlias_pp_anonlist(aTHX);
			SPAGAIN;
		}
		da_alias(aTHX_ a1, a2, TOPs);
		savedop = PL_op->op_type;
		PL_op->op_type = hash ? OP_RV2HV : OP_RV2AV;
		PL_ppaddr[PL_op->op_type](aTHX);
		PL_op->op_type = savedop;
		return NORMAL;
	}
	SP = right - 1;
	while (SP < rlast)
		if (!SvTEMP(*++SP))
			sv_2mortal(SvREFCNT_inc_NN(*SP));
	SP = right - 1;
	while (left <= llast) {
		SV *a1 = *left++, *a2;
		if (a1 == &PL_sv_undef) {
			right++;
			continue;
		}
		a2 = *left++;
		switch ((Size_t) a1) {
		case DA_ALIAS_AV: {
			SV **svp;
			if (SvRMAGICAL(a2) && da_badmagic(aTHX_ a2))
				DIE(aTHX_ DA_TIED_ERR, "put", "into", "array");
			av_clear((AV *) a2);
			if (done || right > rlast)
				break;
			av_extend((AV *) a2, rlast - right);
			AvFILLp((AV *) a2) = rlast - right;
			svp = AvARRAY((AV *) a2);
			while (right <= rlast)
				SvTEMP_off(*svp++ = SvREFCNT_inc_NN(*right++));
			break;
		} case DA_ALIAS_HV: {
			SV *tmp, *val, **svp = rlast;
			U32 dups = 0, nils = 0;
			HE *he;
#if DA_FEATURE_AVHV
			if (SvTYPE(a2) == SVt_PVAV)
				goto phash;
#endif
			if (SvRMAGICAL(a2) && da_badmagic(aTHX_ a2))
				DIE(aTHX_ DA_TIED_ERR, "put", "into", "hash");
			hv_clear((HV *) a2);
			if (done || right > rlast)
				break;
			done = TRUE;
			hv_ksplit((HV *) a2, (rlast - right + 2) >> 1);
			if (1 & ~(rlast - right)) {
				if (ckWARN(WARN_MISC))
					Perl_warner(aTHX_ packWARN(WARN_MISC),
						DA_ODD_HASH_ERR);
				*++svp = &PL_sv_undef;
			}
			while (svp > right) {
				val = *svp--;  tmp = *svp--;
				he = hv_fetch_ent((HV *) a2, tmp, TRUE, 0);
				if (!he) /* is this possible? */
					DIE(aTHX_ PL_no_helem, SvPV_nolen(tmp));
				tmp = HeVAL(he);
				if (SvREFCNT(tmp) > 1) { /* existing element */
					svp[1] = svp[2] = NULL;
					dups += 2;
					continue;
				}
				if (val == &PL_sv_undef)
					nils++;
				SvREFCNT_dec(tmp);
				SvTEMP_off(HeVAL(he) =
						SvREFCNT_inc_simple_NN(val));
			}
			while (nils && (he = hv_iternext((HV *) a2))) {
				if (HeVAL(he) == &PL_sv_undef) {
					HeVAL(he) = &PL_sv_placeholder;
					HvPLACEHOLDERS(a2)++;
					nils--;
				}
			}
			if (gimme != G_LIST || !dups) {
				right = rlast - dups + 1;
				break;
			}
			while (svp++ < rlast) {
				if (*svp)
					*right++ = *svp;
			}
			break;
		}
#if DA_FEATURE_AVHV
		phash: {
			SV *key, *val, **svp = rlast, **he;
			U32 dups = 0;
			I32 i;
			if (SvRMAGICAL(a2) && da_badmagic(aTHX_ a2))
				DIE(aTHX_ DA_TIED_ERR, "put", "into", "hash");
			avhv_keys((AV *) a2);
			av_fill((AV *) a2, 0);
			if (done || right > rlast)
				break;
			done = TRUE;
			if (1 & ~(rlast - right)) {
				if (ckWARN(WARN_MISC))
					Perl_warner(aTHX_ packWARN(WARN_MISC),
						DA_ODD_HASH_ERR);
				*++svp = &PL_sv_undef;
			}
			ENTER;
			while (svp > right) {
				val = *svp--;  key = *svp--;
				i = da_avhv_index(aTHX_ (AV *) a2, key);
				he = &AvARRAY(a2)[i];
				if (*he != &PL_sv_undef) {
					svp[1] = svp[2] = NULL;
					dups += 2;
					continue;
				}
				SvREFCNT_dec(*he);
				if (val == &PL_sv_undef) {
					SAVESPTR(*he);
					*he = NULL;
				} else {
					if (i > AvFILLp(a2))
						AvFILLp(a2) = i;
					SvTEMP_off(*he =
						SvREFCNT_inc_simple_NN(val));
				}
			}
			LEAVE;
			if (gimme != G_LIST || !dups) {
				right = rlast - dups + 1;
				break;
			}
			while (svp++ < rlast) {
				if (*svp)
					*right++ = *svp;
			}
			break;
		}
#endif
		default:
			if (right > rlast)
				da_alias(aTHX_ a1, a2, &PL_sv_undef);
			else if (done)
				da_alias(aTHX_ a1, a2, *right = &PL_sv_undef);
			else
				da_alias(aTHX_ a1, a2, *right);
			right++;
			break;
		}
	}
	if (gimme == G_LIST) {
		SP = right - 1;
		EXTEND(SP, 0);
		while (rlast < SP)
			*++rlast = &PL_sv_undef;
		RETURN;
	} else if (gimme == G_SCALAR) {
		dTARGET;
		XPUSHi(rlast - SP);
	}
	RETURN;
}

STATIC OP *DataAlias_pp_andassign(pTHX) {
	dSP;
	SV *a2 = POPs;
	SV *sv = da_fetch(aTHX_ TOPs, a2);
	if (SvTRUE(sv)) {
		/* no PUTBACK */
		return cLOGOP->op_other;
	}
	SETs(sv);
	RETURN;
}

STATIC OP *DataAlias_pp_orassign(pTHX) {
	dSP;
	SV *a2 = POPs;
	SV *sv = da_fetch(aTHX_ TOPs, a2);
	if (!SvTRUE(sv)) {
		/* no PUTBACK */
		return cLOGOP->op_other;
	}
	SETs(sv);
	RETURN;
}

#if DA_HAVE_OP_DORASSIGN
STATIC OP *DataAlias_pp_dorassign(pTHX) {
	dSP;
	SV *a2 = POPs;
	SV *sv = da_fetch(aTHX_ TOPs, a2);
	if (!SvOK(sv)) {
		/* no PUTBACK */
		return cLOGOP->op_other;
	}
	SETs(sv);
	RETURN;
}
#endif

STATIC OP *DataAlias_pp_push(pTHX) {
	dSP; dMARK; dORIGMARK; dTARGET;
	AV *av = (AV *) *++MARK;
	I32 i;
	if (SvRMAGICAL(av) && da_badmagic(aTHX_ (SV *) av))
		DIE(aTHX_ DA_TIED_ERR, "push", "onto", "array");
	i = AvFILL(av);
	av_extend(av, i + (SP - MARK));
	while (MARK < SP)
		av_store(av, ++i, SvREFCNT_inc_NN(*++MARK));
	SP = ORIGMARK;
	PUSHi(i + 1);
	RETURN;
}

STATIC OP *DataAlias_pp_unshift(pTHX) {
	dSP; dMARK; dORIGMARK; dTARGET;
	AV *av = (AV *) *++MARK;
	I32 i = 0;
	if (SvRMAGICAL(av) && da_badmagic(aTHX_ (SV *) av))
		DIE(aTHX_ DA_TIED_ERR, "unshift", "onto", "array");
	av_unshift(av, SP - MARK);
	while (MARK < SP)
		av_store(av, i++, SvREFCNT_inc_NN(*++MARK));
	SP = ORIGMARK;
	PUSHi(AvFILL(av) + 1);
	RETURN;
}

STATIC OP *DataAlias_pp_splice(pTHX) {
	dSP; dMARK; dORIGMARK;
	I32 ins = SP - MARK - 3;
	AV *av = (AV *) MARK[1];
	I32 off, del, count, i;
	SV **svp, *tmp;
	if (ins < 0) /* ?! */
		DIE(aTHX_ "Too few arguments for DataAlias_pp_splice");
	if (SvRMAGICAL(av) && da_badmagic(aTHX_ (SV *) av))
		DIE(aTHX_ DA_TIED_ERR, "splice", "onto", "array");
	count = AvFILLp(av) + 1;
	off = SvIV(MARK[2]);
	if (off < 0 && (off += count) < 0)
		DIE(aTHX_ PL_no_aelem, off - count);
	del = SvIV(ORIGMARK[3]);
	if (del < 0 && (del += count - off) < 0)
		del = 0;
	if (off > count) {
		if (ckWARN(WARN_MISC))
			Perl_warner(aTHX_ packWARN(WARN_MISC),
				"splice() offset past end of array");
		off = count;
	}
	if ((count -= off + del) < 0) /* count of trailing elems */
		del += count, count = 0;
	i = off + ins + count - 1;
	if (i > AvMAX(av))
		av_extend(av, i);
	if (!AvREAL(av) && AvREIFY(av))
		av_reify(av);
	AvFILLp(av) = i;
	MARK = ORIGMARK + 4;
	svp = AvARRAY(av) + off;
	for (i = 0; i < ins; i++)
		SvTEMP_off(SvREFCNT_inc_NN(MARK[i]));
	if (ins > del) {
		Move(svp+del, svp+ins, INT2SIZE(count), SV *);
		for (i = 0; i < del; i++)
			tmp = MARK[i], MARK[i-3] = svp[i], svp[i] = tmp;
		Copy(MARK+del, svp+del, INT2SIZE(ins-del), SV *);
	} else {
		for (i = 0; i < ins; i++)
			tmp = MARK[i], MARK[i-3] = svp[i], svp[i] = tmp;
		if (ins != del)
			Copy(svp+ins, MARK-3+ins, INT2SIZE(del-ins), SV *);
		Move(svp+del, svp+ins, INT2SIZE(count), SV *);
	}
	MARK -= 3;
	for (i = 0; i < del; i++)
		sv_2mortal(MARK[i]);
	SP = MARK + del - 1;
	RETURN;
}

STATIC OP *DataAlias_pp_leave(pTHX) {
	dSP;
	SV **newsp;
	PMOP *newpm;
	I32 gimme;
	PERL_CONTEXT *cx;
	SV *sv;

	if (PL_op->op_flags & OPf_SPECIAL)
		cxstack[cxstack_ix].blk_oldpm = PL_curpm;
	
	POPBLOCK(cx, newpm);

	gimme = OP_GIMME(PL_op, -1);
	if (gimme == -1) {
		if (cxstack_ix >= 0)
			gimme = cxstack[cxstack_ix].blk_gimme;
		else
			gimme = G_SCALAR;
	}

	if (gimme == G_SCALAR) {
		if (newsp == SP) {
			*++newsp = &PL_sv_undef;
		} else {
			sv = SvREFCNT_inc_NN(TOPs);
			FREETMPS;
			*++newsp = sv_2mortal(sv);
		}
	} else if (gimme == G_LIST) {
		while (newsp < SP)
			if (!SvTEMP(sv = *++newsp))
				sv_2mortal(SvREFCNT_inc_simple_NN(sv));
	}
	PL_stack_sp = newsp;
	PL_curpm = newpm;
	LEAVE;
	return NORMAL;
}

STATIC OP *DataAlias_pp_return(pTHX) {
	dSP; dMARK;
	I32 cxix;
	PERL_CONTEXT *cx;
	bool clearerr = FALSE;
	I32 gimme;
	SV **newsp;
	PMOP *newpm;
	I32 optype = 0, type = 0;
	SV *sv = (MARK < SP) ? TOPs : &PL_sv_undef;
	OP *retop;

	cxix = cxstack_ix;
	while (cxix >= 0) {
		cx = &cxstack[cxix];
		type = CxTYPE(cx);
		if (type == CXt_EVAL || type == CXt_SUB || type == CXt_FORMAT)
			break;
		cxix--;
	}

#if DA_FEATURE_MULTICALL
	if (cxix < 0) {
		if (CxMULTICALL(cxstack)) {	/* sort block */
			dounwind(0);
			*(PL_stack_sp = PL_stack_base + 1) = sv;
			return 0;
		}
		DIE(aTHX_ "Can't return outside a subroutine");
	}
#else
	if (PL_curstackinfo->si_type == PERLSI_SORT && cxix <= PL_sortcxix) {
		if (cxstack_ix > PL_sortcxix)
			dounwind(PL_sortcxix);
		*(PL_stack_sp = PL_stack_base + 1) = sv;
		return 0;
	}
	if (cxix < 0)
		DIE(aTHX_ "Can't return outside a subroutine");
#endif


	if (cxix < cxstack_ix)
		dounwind(cxix);

#if DA_FEATURE_MULTICALL
	if (CxMULTICALL(&cxstack[cxix])) {
		gimme = cxstack[cxix].blk_gimme;
		if (gimme == G_VOID)
			PL_stack_sp = PL_stack_base;
		else if (gimme == G_SCALAR)
			*(PL_stack_sp = PL_stack_base + 1) = sv;
		return 0;
	}
#endif

	POPBLOCK(cx, newpm);
	switch (type) {
	case CXt_SUB:
#if DA_FEATURE_RETOP
		retop = cx->blk_sub.retop;
#endif
		cxstack_ix++; /* temporarily protect top context */
		break;
	case CXt_EVAL:
		clearerr = !(PL_in_eval & EVAL_KEEPERR);
		POPEVAL(cx);
#if DA_FEATURE_RETOP
		retop = cx->blk_eval.retop;
#endif
		if (CxTRYBLOCK(cx))
			break;
		lex_end();
		if (optype == OP_REQUIRE && !SvTRUE(sv)
				&& (gimme == G_SCALAR || MARK == SP)) {
			sv = cx->blk_eval.old_namesv;
			(void) hv_delete(GvHVn(PL_incgv), SvPVX_const(sv),
					SvCUR(sv), G_DISCARD);
			DIE(aTHX_ "%"SVf" did not return a true value", sv);
		}
		break;
	case CXt_FORMAT:
		POPFORMAT(cx);
#if DA_FEATURE_RETOP
		retop = cx->blk_sub.retop;
#endif
		break;
	default:
		DIE(aTHX_ "panic: return");
		retop = NULL;   /* suppress "uninitialized" warning */
	}

	TAINT_NOT;
	if (gimme == G_SCALAR) {
		if (MARK == SP) {
			*++newsp = &PL_sv_undef;
		} else {
			sv = SvREFCNT_inc_NN(TOPs);
			FREETMPS;
			*++newsp = sv_2mortal(sv);
		}
	} else if (gimme == G_LIST) {
		while (MARK < SP) {
			*++newsp = sv = *++MARK;
			if (!SvTEMP(sv) && !(SvREADONLY(sv) && SvIMMORTAL(sv)))
				sv_2mortal(SvREFCNT_inc_simple_NN(sv));
			TAINT_NOT;
		}
	}
	PL_stack_sp = newsp;
	LEAVE;
	if (type == CXt_SUB) {
		cxstack_ix--;
		POPSUB(cx, sv);
	} else {
		sv = Nullsv;
	}
	PL_curpm = newpm;
	LEAVESUB(sv);
	if (clearerr)
		sv_setpvn(ERRSV, "", 0);
#if (!DA_FEATURE_RETOP)
	retop = pop_return();
#endif
	return retop;
}

STATIC OP *DataAlias_pp_leavesub(pTHX) {
	if (++PL_markstack_ptr == PL_markstack_max)
		markstack_grow();
	*PL_markstack_ptr = cxstack[cxstack_ix].blk_oldsp;
	return DataAlias_pp_return(aTHX);
}

STATIC OP *DataAlias_pp_entereval(pTHX) {
	dDAforce;
	PERL_CONTEXT *iscope = da_iscope;
	I32 inside = da_inside;
	I32 cxi = (cxstack_ix < cxstack_max) ? cxstack_ix + 1 : cxinc();
	OP *ret;
	da_iscope = &cxstack[cxi];
	da_inside = 1;
	ret = PL_ppaddr[OP_ENTEREVAL](aTHX);
	da_iscope = iscope;
	da_inside = inside;
	return ret;
}

STATIC OP *DataAlias_pp_copy(pTHX) {
	dSP; dMARK;
	SV *sv;
	switch (GIMME_V) {
	case G_VOID:
		SP = MARK;
		break;
	case G_SCALAR:
		if (MARK == SP) {
			sv = sv_newmortal();
			EXTEND(SP, 1);
		} else {
			sv = TOPs;
			if (!SvTEMP(sv) || SvREFCNT(sv) != 1)
				sv = sv_mortalcopy(sv);
		}
		*(SP = MARK + 1) = sv;
		break;
	default:
		while (MARK < SP) {
			if (!SvTEMP(sv = *++MARK) || SvREFCNT(sv) != 1)
				*MARK = sv_mortalcopy(sv);
		}
	}
	RETURN;
}

STATIC void da_lvalue(pTHX_ OP *op, int list) {
	switch (op->op_type) {
	case OP_PADSV:     op->op_ppaddr = DataAlias_pp_padsv;
			   if (SvFAKE(AvARRAY(PL_comppad_name)[op->op_targ])
					   && ckWARN(WARN_CLOSURE))
				   Perl_warner(aTHX_ packWARN(WARN_CLOSURE),
						   DA_OUTER_ERR);
			   break;
#if DA_HAVE_OP_PADRANGE
	case OP_PADRANGE: {
		int start = op->op_targ;
		int count = op->op_private & OPpPADRANGE_COUNTMASK;
		int i;
		if (!list) goto bad;
		for(i = start; i != start+count; i++) {
			   if (SvFAKE(AvARRAY(PL_comppad_name)[i])
					   && ckWARN(WARN_CLOSURE))
				   Perl_warner(aTHX_ packWARN(WARN_CLOSURE),
						   DA_OUTER_ERR);
		}
		if (op->op_ppaddr != DataAlias_pp_padrange_single)
			op->op_ppaddr = DataAlias_pp_padrange_list;
	} break;
#endif
	case OP_AELEM:     op->op_ppaddr = DataAlias_pp_aelem;     break;
#if (PERL_COMBI_VERSION >= 5015000)
	case OP_AELEMFAST_LEX:
#endif
	case OP_AELEMFAST: op->op_ppaddr = DataAlias_pp_aelemfast; break;
	case OP_HELEM:     op->op_ppaddr = DataAlias_pp_helem;     break;
	case OP_ASLICE:    op->op_ppaddr = DataAlias_pp_aslice;    break;
	case OP_HSLICE:    op->op_ppaddr = DataAlias_pp_hslice;    break;
	case OP_GVSV:      op->op_ppaddr = DataAlias_pp_gvsv;      break;
	case OP_RV2SV:     op->op_ppaddr = DataAlias_pp_rv2sv;     break;
	case OP_RV2GV:     op->op_ppaddr = DataAlias_pp_rv2gv;     break;
	case OP_LIST:
		if (!list)
			goto bad;
	case OP_NULL:
		op = (op->op_flags & OPf_KIDS) ? cUNOPx(op)->op_first : NULL;
		while (op) {
			da_lvalue(aTHX_ op, list);
			op = op->op_sibling;
		}
		break;
	case OP_COND_EXPR:
		op = cUNOPx(op)->op_first;
		while ((op = op->op_sibling))
			da_lvalue(aTHX_ op, list);
		break;
	case OP_SCOPE:
	case OP_LEAVE:
	case OP_LINESEQ:
		op = (op->op_flags & OPf_KIDS) ? cUNOPx(op)->op_first : NULL;
		while (op->op_sibling)
			op = op->op_sibling;
		da_lvalue(aTHX_ op, list);
		break;
	case OP_PUSHMARK:
		if (!list) goto bad;
		break;
	case OP_PADAV:
		if (!list) goto bad;
		if (op->op_ppaddr != DataAlias_pp_padsv)
			op->op_ppaddr = DataAlias_pp_padav;
		break;
	case OP_PADHV:
		if (!list) goto bad;
		if (op->op_ppaddr != DataAlias_pp_padsv)
			op->op_ppaddr = DataAlias_pp_padhv;
		break;
	case OP_RV2AV:
		if (!list) goto bad;
		if (op->op_ppaddr != DataAlias_pp_rv2sv)
			op->op_ppaddr = DataAlias_pp_rv2av;
		break;
	case OP_RV2HV:
		if (!list) goto bad;
		if (op->op_ppaddr != DataAlias_pp_rv2sv)
			op->op_ppaddr = DataAlias_pp_rv2hv;
		break;
	case OP_UNDEF:
		if (!list || (op->op_flags & OPf_KIDS))
			goto bad;
		break;
	default:
	bad:	qerror(Perl_mess(aTHX_ DA_TARGET_ERR_AT, OutCopFILE(PL_curcop),
					(UV) CopLINE(PL_curcop)));
	}
}

STATIC void da_aassign(OP *op, OP *right) {
	OP *left, *la, *ra;
	int hash = FALSE, pad;

	/* make sure it fits the model exactly */
	if (!right || !(left = right->op_sibling) || left->op_sibling)
		return;
	if (left->op_type || !(left->op_flags & OPf_KIDS))
		return;
	if (!(left = cUNOPx(left)->op_first) || !IS_PUSHMARK_OR_PADRANGE(left))
		return;
	if (!(la = left->op_sibling) || la->op_sibling)
		return;
	if (la->op_flags & OPf_PARENS)
		return;
	switch (la->op_type) {
	case OP_PADHV: hash = TRUE; case OP_PADAV: pad = TRUE;  break;
	case OP_RV2HV: hash = TRUE; case OP_RV2AV: pad = FALSE; break;
	default: return;
	}
	if (right->op_type || !(right->op_flags & OPf_KIDS))
		return;
	if (!(right = cUNOPx(right)->op_first) ||
			!IS_PUSHMARK_OR_PADRANGE(right))
		return;
	op->op_private = hash ? OPpALIASHV : OPpALIASAV;
	la->op_ppaddr = pad ? DataAlias_pp_padsv : DataAlias_pp_rv2sv;
	if (pad) {
		la->op_type = OP_PADSV;
#if DA_HAVE_OP_PADRANGE
		if (left->op_type == OP_PADRANGE)
			left->op_ppaddr = DataAlias_pp_padrange_single;
		else if (right->op_type == OP_PADRANGE &&
				(right->op_flags & OPf_SPECIAL))
			right->op_ppaddr = DataAlias_pp_padrange_single;
#endif
	}
	if (!(ra = right->op_sibling) || ra->op_sibling)
		return;
	if (ra->op_flags & OPf_PARENS)
		return;
	if (hash) {
		if (ra->op_type != OP_PADHV && ra->op_type != OP_RV2HV)
			return;
	} else {
		if (ra->op_type != OP_PADAV && ra->op_type != OP_RV2AV)
			return;
	}
	ra->op_flags &= -2;
	ra->op_flags |= OPf_REF;
}

STATIC int da_transform(pTHX_ OP *op, int sib) {
	int hits = 0;

	while (op) {
		OP *kid = Nullop, *tmp;
		int ksib = TRUE;
		OPCODE optype;

		if (op->op_flags & OPf_KIDS)
			kid = cUNOPx(op)->op_first;

		++hits;
		switch ((optype = op->op_type)) {
		case OP_NULL:
			optype = (OPCODE) op->op_targ;
		default:
			--hits;
			switch (optype) {
			case_OP_SETSTATE_
			case OP_NEXTSTATE:
			case OP_DBSTATE:
				PL_curcop = (COP *) op;
				break;
			case OP_LIST:
				if (op->op_ppaddr == da_tag_list) {
					da_peep2(aTHX_ op);
					return hits;
				}
				break;
			}
			break;
		case OP_LEAVE:
			if (op->op_ppaddr != da_tag_entersub)
				op->op_ppaddr = DataAlias_pp_leave;
			else
				hits--;
			break;
		case OP_LEAVESUB:
		case OP_LEAVESUBLV:
		case OP_LEAVEEVAL:
		case OP_LEAVETRY:
			op->op_ppaddr = DataAlias_pp_leavesub;
			break;
		case OP_RETURN:
			op->op_ppaddr = DataAlias_pp_return;
			break;
		case OP_ENTEREVAL:
			op->op_ppaddr = DataAlias_pp_entereval;
			break;
		case OP_CONST:
			--hits;
			{
				SV *sv = cSVOPx_sv(op);
				SvPADTMP_off(sv);
				SvREADONLY_on(sv);
			}
			break;
		case OP_GVSV:
			if (op->op_private & OPpLVAL_INTRO)
				op->op_ppaddr = DataAlias_pp_gvsv_r;
			else
				hits--;
			break;
		case OP_RV2SV:
		case OP_RV2AV:
		case OP_RV2HV:
			if (op->op_private & OPpLVAL_INTRO)
				op->op_ppaddr = DataAlias_pp_rv2sv_r;
			else
				hits--;
			break;
		case OP_SREFGEN:
			op->op_ppaddr = DataAlias_pp_srefgen;
			break;
		case OP_REFGEN:
			op->op_ppaddr = DataAlias_pp_refgen;
			break;
		case OP_AASSIGN:
			op->op_ppaddr = DataAlias_pp_aassign;
			da_aassign(op, kid);
			MOD(kid);
			ksib = FALSE;
#if DA_HAVE_OP_PADRANGE
			for (tmp = kid; tmp->op_type == OP_NULL &&
						(tmp->op_flags & OPf_KIDS); )
			tmp = cUNOPx(tmp)->op_first;
			if (tmp->op_type == OP_PADRANGE &&
					(tmp->op_flags & OPf_SPECIAL))
				da_lvalue(aTHX_ tmp, TRUE);
			else
#endif
				da_lvalue(aTHX_ kid->op_sibling, TRUE);
			break;
		case OP_SASSIGN:

			op->op_ppaddr = DataAlias_pp_sassign;
			MOD(kid);
			ksib = FALSE;
			if (!(op->op_private & OPpASSIGN_BACKWARDS))
				da_lvalue(aTHX_ kid->op_sibling, FALSE);
			break;
		case OP_ANDASSIGN:
			op->op_ppaddr = DataAlias_pp_andassign;
			if (0)
		case OP_ORASSIGN:
			op->op_ppaddr = DataAlias_pp_orassign;
#if DA_HAVE_OP_DORASSIGN
			if (0)
		case OP_DORASSIGN:
			op->op_ppaddr = DataAlias_pp_dorassign;
#endif
			da_lvalue(aTHX_ kid, FALSE);
			kid = kid->op_sibling;
			break;
		case OP_UNSHIFT:
			if (!(tmp = kid->op_sibling)) break; /* array */
			if (!(tmp = tmp->op_sibling)) break; /* first elem */
			op->op_ppaddr = DataAlias_pp_unshift;
			goto mod;
		case OP_PUSH:
			if (!(tmp = kid->op_sibling)) break; /* array */
			if (!(tmp = tmp->op_sibling)) break; /* first elem */
			op->op_ppaddr = DataAlias_pp_push;
			goto mod;
		case OP_SPLICE:
			if (!(tmp = kid->op_sibling)) break; /* array */
			if (!(tmp = tmp->op_sibling)) break; /* offset */
			if (!(tmp = tmp->op_sibling)) break; /* length */
			if (!(tmp = tmp->op_sibling)) break; /* first elem */
			op->op_ppaddr = DataAlias_pp_splice;
			goto mod;
		case OP_ANONLIST:
			if (!(tmp = kid->op_sibling)) break; /* first elem */
			op->op_ppaddr = DataAlias_pp_anonlist;
			goto mod;
		case OP_ANONHASH:
			if (!(tmp = kid->op_sibling)) break; /* first elem */
			op->op_ppaddr = DataAlias_pp_anonhash;
		 mod:	do MOD(tmp); while ((tmp = tmp->op_sibling));
		}

		if (sib && op->op_sibling) {
			if (kid)
				hits += da_transform(aTHX_ kid, ksib);
			op = op->op_sibling;
		} else {
			op = kid;
			sib = ksib;
		}
	}

	return hits;
}

STATIC void da_peep2(pTHX_ OP *o) {
	OP *sib, *k;
	int useful;
	while (o->op_ppaddr != da_tag_list) {
		while ((sib = o->op_sibling)) {
			if ((o->op_flags & OPf_KIDS) && (k = cUNOPo->op_first)){
				da_peep2(aTHX_ k);
			} else switch (o->op_type ? o->op_type : o->op_targ) {
			case_OP_SETSTATE_
			case OP_NEXTSTATE:
			case OP_DBSTATE:
				PL_curcop = (COP *) o;
			}
			o = sib;
		}
		if (!(o->op_flags & OPf_KIDS) || !(o = cUNOPo->op_first))
			return;
	}
	useful = o->op_private & OPpUSEFUL;
	op_null(o);
	o->op_ppaddr = PL_ppaddr[OP_NULL];
	k = o = cLISTOPo->op_first;
	while ((sib = k->op_sibling))
		k = sib;
	if (!(sib = cUNOPo->op_first) || sib->op_ppaddr != da_tag_rv2cv) {
		Perl_warn(aTHX_ "da peep weirdness 1");
	} else {
		k->op_sibling = sib;
		if (!(k = sib->op_next) || k->op_ppaddr != da_tag_entersub) {
			Perl_warn(aTHX_ "da peep weirdness 2");
		} else {
			k->op_type = OP_ENTERSUB;
			if (sib->op_flags & OPf_SPECIAL) {
				k->op_ppaddr = DataAlias_pp_copy;
				da_peep2(aTHX_ o);
			} else if (!da_transform(aTHX_ o, TRUE)
					&& !useful && ckWARN(WARN_VOID)) {
				Perl_warner(aTHX_ packWARN(WARN_VOID),
						"Useless use of alias");
			}
		}
	}
}

STATIC void da_peep(pTHX_ OP *o) {
	dDAforce;
	da_old_peepp(aTHX_ o);
	ENTER;
	SAVEVPTR(PL_curcop);
	if (da_inside && da_iscope == &cxstack[cxstack_ix]) {
		OP *tmp;
		while ((tmp = o->op_next))
			o = tmp;
		if (da_transform(aTHX_ o, FALSE))
			da_inside = 2;
	} else {
		da_peep2(aTHX_ o);
	}
	LEAVE;
}

#define LEX_NORMAL		10
#define LEX_INTERPNORMAL	 9
#define LEX_KNOWNEXT             0

STATIC OP *da_ck_rv2cv(pTHX_ OP *o) {
	dDA;
	SV **sp;
	OP *kid;
	char *s, *start_s;
	CV *cv;
	o = da_old_ck_rv2cv(aTHX_ o);
#if (PERL_COMBI_VERSION >= 5009005)
	if (!PL_parser)
		return o;
#endif
	if (PL_lex_state != LEX_NORMAL && PL_lex_state != LEX_INTERPNORMAL)
		return o; /* not lexing? */
	kid = cUNOPo->op_first;
	if (kid->op_type != OP_GV || !DA_ACTIVE || (
			(cv = GvCV(kGVOP_gv)) != da_cv && cv != da_cvc ))
		return o;
	if (o->op_private & OPpENTERSUB_AMPER)
		return o;
	SvPOK_off(cv);
	o->op_ppaddr = da_tag_rv2cv;
	if (cv == da_cv)
		o->op_flags &= ~OPf_SPECIAL;
	else
		o->op_flags |= OPf_SPECIAL;
	start_s = s = PL_oldbufptr;
	while (s < PL_bufend && isSPACE(*s)) s++;
	if (memEQ(s, PL_tokenbuf, strlen(PL_tokenbuf))) {
		s += strlen(PL_tokenbuf);
		if (PL_bufptr > s) s = PL_bufptr;
#if (PERL_COMBI_VERSION >= 5011002)
		{
			char *old_buf = SvPVX(PL_linestr);
			char *old_bufptr = PL_bufptr;
			PL_bufptr = s;
			lex_read_space(LEX_KEEP_PREVIOUS);
			if (SvPVX(PL_linestr) != old_buf)
				Perl_croak(aTHX_ "Data::Alias can't handle "
					"lexer buffer reallocation");
			s = PL_bufptr;
			PL_bufptr = old_bufptr;
		}
#else
		while (s < PL_bufend && isSPACE(*s)) s++;
#endif
	} else {
		s = "";
	}
	if (*s == '{') { /* here comes deep magic */
		I32 shift;
		YYSTYPE yylval = PL_yylval;
		PL_bufptr = s;
		PL_expect = XSTATE;
		if ((PL_nexttype[PL_nexttoke++] = yylex()) == '{') {
			PL_nexttype[PL_nexttoke++] = DO;
			sv_setpv((SV *) cv, "$");
			if (PERL_COMBI_VERSION >= 5011002 &&
					*PL_bufptr == '(') {
				/*
				 * A paren here triggers special lexer
				 * behaviour for a parenthesised argument
				 * list, which screws up the normal
				 * parsing that we want to continue.
				 * Suppress it by injecting a semicolon,
				 * which is otherwise a no-op coming just
				 * after the opening brace of a block.
				 */
				Move(PL_bufptr, PL_bufptr+1,
					PL_bufend+1-PL_bufptr, char);
				*PL_bufptr = ';';
				PL_bufend++;
				SvCUR(PL_linestr)++;
			}
		}
		if(PL_lex_state != LEX_KNOWNEXT) {
			PL_lex_defer = PL_lex_state;
			PL_lex_expect = PL_expect;
			PL_lex_state = LEX_KNOWNEXT;
		}
		PL_yylval = yylval;
		if ((shift = s - PL_bufptr)) { /* here comes deeper magic */
			s = SvPVX(PL_linestr);
			PL_bufptr += shift;
			if ((PL_oldbufptr += shift) < s)
				PL_oldbufptr = s;
			if ((PL_oldoldbufptr += shift) < s)
				PL_oldbufptr = s;
			if (PL_last_uni && (PL_last_uni += shift) < s)
				PL_last_uni = s;
			if (PL_last_lop && (PL_last_lop += shift) < s)
				PL_last_lop = s;
			if (shift > 0) {
				STRLEN len = SvCUR(PL_linestr) + 1;
				if (len + shift > SvLEN(PL_linestr))
					len = SvLEN(PL_linestr) - shift;
				Move(s, s + shift, len, char);
				SvCUR(PL_linestr) = len + shift - 1;
			} else {
				STRLEN len = SvCUR(PL_linestr) + shift + 1;
				Move(s - shift, s, len, char);
				SvCUR(PL_linestr) += shift;
			}
			*(PL_bufend = s + SvCUR(PL_linestr)) = '\0';
			if (start_s < PL_bufptr)
				memset(start_s, ' ', PL_bufptr-start_s);
		}
	}
	if (da_iscope != &cxstack[cxstack_ix]) {
		SAVEVPTR(da_iscope);
		SAVEI32(da_inside);
		da_iscope = &cxstack[cxstack_ix];
	}
	SPAGAIN;
	XPUSHs(da_inside ? &PL_sv_yes : &PL_sv_no);
	da_inside = (cv == da_cv);
	PUTBACK;
	return o;
}

STATIC OP *da_ck_entersub(pTHX_ OP *o) {
	dDA;
	OP *kid = cUNOPo->op_first;
	OP *last, *tmp;
	int inside;
	if (!(kid->op_type == OP_LIST ||
			(kid->op_type == OP_NULL && kid->op_targ == OP_LIST)))
		return da_old_ck_entersub(aTHX_ o);
	last = kLISTOP->op_last;
	if (!DA_ACTIVE || !(kid->op_flags & OPf_KIDS)
				|| last->op_ppaddr != da_tag_rv2cv)
		return da_old_ck_entersub(aTHX_ o);
	inside = da_inside;
	da_inside = SvIVX(*PL_stack_sp--);
	SvPOK_off(inside ? da_cv : da_cvc);
	op_clear(o);
	RenewOpc(0, o, 1, LISTOP, OP);
	o->op_type = inside ? OP_SCOPE : OP_LEAVE;
	o->op_ppaddr = da_tag_entersub;
	cLISTOPo->op_last = kid;
	kid->op_type = OP_LIST;
	kid->op_targ = 0;
	kid->op_ppaddr = da_tag_list;
	if (inside > 1)
		kid->op_private |= OPpUSEFUL;
	else
		kid->op_private &= ~OPpUSEFUL;
	tmp = kLISTOP->op_first;
	if (inside)
		op_null(tmp);
	RenewOpc(0, tmp, 1, UNOP, OP);
	tmp->op_next = tmp;
	kLISTOP->op_first = tmp;
	kid = tmp;
	kUNOP->op_first = last;
	while (kid->op_sibling != last)
		kid = kid->op_sibling;
	kid->op_sibling = Nullop;
	cLISTOPx(cUNOPo->op_first)->op_last = kid;
	if (kid->op_type == OP_NULL && inside)
		kid->op_flags &= ~OPf_SPECIAL;
	last->op_next = o;
	return o;
}


MODULE = Data::Alias  PACKAGE = Data::Alias

PROTOTYPES: DISABLE

BOOT:
	{
	static int initialized = 0;
	dDA;
	DA_INIT;
	da_cv = get_cv("Data::Alias::alias", TRUE);
	da_cvc = get_cv("Data::Alias::copy", TRUE);
	if (!initialized++) {
		da_old_ck_rv2cv = PL_check[OP_RV2CV];
		PL_check[OP_RV2CV] = da_ck_rv2cv;
		da_old_ck_entersub = PL_check[OP_ENTERSUB];
		PL_check[OP_ENTERSUB] = da_ck_entersub;
	}
	CvLVALUE_on(get_cv("Data::Alias::deref", TRUE));
	da_old_peepp = PL_peepp;
	PL_peepp = da_peep;
	}

void
deref(...)
    PREINIT:
	I32 i, n = 0;
	SV *sv;
    PPCODE:
	for (i = 0; i < items; i++) {
		if (!SvROK(ST(i))) {
			STRLEN z;
			if (SvOK(ST(i)))
				Perl_croak(aTHX_ DA_DEREF_ERR, SvPV(ST(i), z));
			if (ckWARN(WARN_UNINITIALIZED))
				Perl_warner(aTHX_ packWARN(WARN_UNINITIALIZED),
					"Use of uninitialized value in deref");
			continue;
		}
		sv = SvRV(ST(i));
		switch (SvTYPE(sv)) {
			I32 x;
		case SVt_PVAV:
			if (!(x = av_len((AV *) sv) + 1))
				continue;
			SP += x;
			break;
		case SVt_PVHV:
			if (!(x = HvKEYS(sv)))
				continue;
			SP += x * 2;
			break;
		case SVt_PVCV:
			Perl_croak(aTHX_ "Can't deref subroutine reference");
		case SVt_PVFM:
			Perl_croak(aTHX_ "Can't deref format reference");
		case SVt_PVIO:
			Perl_croak(aTHX_ "Can't deref filehandle reference");
		default:
			SP++;
		}
		ST(n++) = ST(i);
	}
	EXTEND(SP, 0);
	for (i = 0; n--; ) {
		SV *sv = SvRV(ST(n));
		I32 x = SvTYPE(sv);
		if (x == SVt_PVAV) {
			i -= x = AvFILL((AV *) sv) + 1;
			Copy(AvARRAY((AV *) sv), SP + i + 1, INT2SIZE(x), SV *);
		} else if (x == SVt_PVHV) {
			HE *entry;
			HV *hv = (HV *) sv;
			i -= x = hv_iterinit(hv) * 2;
			PUTBACK;
			while ((entry = hv_iternext(hv))) {
				sv = hv_iterkeysv(entry);
				SvREADONLY_on(sv);
				SPAGAIN;
				SP[++i] = sv;
				sv = hv_iterval(hv, entry);
				SPAGAIN;
				SP[++i] = sv;
			}
			i -= x;
		} else {
			SP[i--] = sv;
		}
	}
