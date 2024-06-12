
{.warning[UnusedImport]: off.}
{.hint[XDeclaredButNotUsed]: off.}
from macros import hint

from os import parentDir

when not declared(enumuccpum68k):
  type
    enumuccpum68k* {.size: sizeof(cuint).} = enum
      Uccpum68km5206 = 0, Uccpum68km68000 = 1, Uccpum68km68020 = 2,
      Uccpum68km68030 = 3, Uccpum68km68040 = 4, Uccpum68km68060 = 5,
      Uccpum68km5208 = 6, Uccpum68kcfv4e = 7, Uccpum68kany = 8,
      Uccpum68kending = 9
else:
  static :
    hint("Declaration of " & "enumuccpum68k" &
        " already exists, not redeclaring")
when not declared(enumucm68kreg):
  type
    enumucm68kreg* {.size: sizeof(cuint).} = enum
      Ucm68kreginvalid = 0, Ucm68krega0 = 1, Ucm68krega1 = 2, Ucm68krega2 = 3,
      Ucm68krega3 = 4, Ucm68krega4 = 5, Ucm68krega5 = 6, Ucm68krega6 = 7,
      Ucm68krega7 = 8, Ucm68kregd0 = 9, Ucm68kregd1 = 10, Ucm68kregd2 = 11,
      Ucm68kregd3 = 12, Ucm68kregd4 = 13, Ucm68kregd5 = 14, Ucm68kregd6 = 15,
      Ucm68kregd7 = 16, Ucm68kregsr = 17, Ucm68kregpc = 18, Ucm68kregending = 19
else:
  static :
    hint("Declaration of " & "enumucm68kreg" &
        " already exists, not redeclaring")
when not declared(enumuccpux86):
  type
    enumuccpux86* {.size: sizeof(cuint).} = enum
      Uccpux86qemu64 = 0, Uccpux86phenom = 1, Uccpux86core2duo = 2,
      Uccpux86kvm64 = 3, Uccpux86qemu32 = 4, Uccpux86kvm32 = 5,
      Uccpux86coreduo = 6, Uccpux86486 = 7, Uccpux86pentium = 8,
      Uccpux86pentium2 = 9, Uccpux86pentium3 = 10, Uccpux86athlon = 11,
      Uccpux86n270 = 12, Uccpux86conroe = 13, Uccpux86penryn = 14,
      Uccpux86nehalem = 15, Uccpux86westmere = 16, Uccpux86sandybridge = 17,
      Uccpux86ivybridge = 18, Uccpux86haswell = 19, Uccpux86broadwell = 20,
      Uccpux86skylakeclient = 21, Uccpux86skylakeserver = 22,
      Uccpux86cascadelakeserver = 23, Uccpux86cooperlake = 24,
      Uccpux86icelakeclient = 25, Uccpux86icelakeserver = 26,
      Uccpux86denverton = 27, Uccpux86snowridge = 28, Uccpux86knightsmill = 29,
      Uccpux86opterong1 = 30, Uccpux86opterong2 = 31, Uccpux86opterong3 = 32,
      Uccpux86opterong4 = 33, Uccpux86opterong5 = 34, Uccpux86epyc = 35,
      Uccpux86dhyana = 36, Uccpux86epycrome = 37, Uccpux86ending = 38
else:
  static :
    hint("Declaration of " & "enumuccpux86" & " already exists, not redeclaring")
when not declared(enumucx86reg):
  type
    enumucx86reg* {.size: sizeof(cuint).} = enum
      Ucx86reginvalid = 0, Ucx86regah = 1, Ucx86regal = 2, Ucx86regax = 3,
      Ucx86regbh = 4, Ucx86regbl = 5, Ucx86regbp = 6, Ucx86regbpl = 7,
      Ucx86regbx = 8, Ucx86regch = 9, Ucx86regcl = 10, Ucx86regcs = 11,
      Ucx86regcx = 12, Ucx86regdh = 13, Ucx86regdi = 14, Ucx86regdil = 15,
      Ucx86regdl = 16, Ucx86regds = 17, Ucx86regdx = 18, Ucx86regeax = 19,
      Ucx86regebp = 20, Ucx86regebx = 21, Ucx86regecx = 22, Ucx86regedi = 23,
      Ucx86regedx = 24, Ucx86regeflags = 25, Ucx86regeip = 26, Ucx86reges = 28,
      Ucx86regesi = 29, Ucx86regesp = 30, Ucx86regfpsw = 31, Ucx86regfs = 32,
      Ucx86reggs = 33, Ucx86regip = 34, Ucx86regrax = 35, Ucx86regrbp = 36,
      Ucx86regrbx = 37, Ucx86regrcx = 38, Ucx86regrdi = 39, Ucx86regrdx = 40,
      Ucx86regrip = 41, Ucx86regrsi = 43, Ucx86regrsp = 44, Ucx86regsi = 45,
      Ucx86regsil = 46, Ucx86regsp = 47, Ucx86regspl = 48, Ucx86regss = 49,
      Ucx86regcr0 = 50, Ucx86regcr1 = 51, Ucx86regcr2 = 52, Ucx86regcr3 = 53,
      Ucx86regcr4 = 54, Ucx86regcr8 = 58, Ucx86regdr0 = 66, Ucx86regdr1 = 67,
      Ucx86regdr2 = 68, Ucx86regdr3 = 69, Ucx86regdr4 = 70, Ucx86regdr5 = 71,
      Ucx86regdr6 = 72, Ucx86regdr7 = 73, Ucx86regfp0 = 82, Ucx86regfp1 = 83,
      Ucx86regfp2 = 84, Ucx86regfp3 = 85, Ucx86regfp4 = 86, Ucx86regfp5 = 87,
      Ucx86regfp6 = 88, Ucx86regfp7 = 89, Ucx86regk0 = 90, Ucx86regk1 = 91,
      Ucx86regk2 = 92, Ucx86regk3 = 93, Ucx86regk4 = 94, Ucx86regk5 = 95,
      Ucx86regk6 = 96, Ucx86regk7 = 97, Ucx86regmm0 = 98, Ucx86regmm1 = 99,
      Ucx86regmm2 = 100, Ucx86regmm3 = 101, Ucx86regmm4 = 102,
      Ucx86regmm5 = 103, Ucx86regmm6 = 104, Ucx86regmm7 = 105, Ucx86regr8 = 106,
      Ucx86regr9 = 107, Ucx86regr10 = 108, Ucx86regr11 = 109, Ucx86regr12 = 110,
      Ucx86regr13 = 111, Ucx86regr14 = 112, Ucx86regr15 = 113,
      Ucx86regst0 = 114, Ucx86regst1 = 115, Ucx86regst2 = 116,
      Ucx86regst3 = 117, Ucx86regst4 = 118, Ucx86regst5 = 119,
      Ucx86regst6 = 120, Ucx86regst7 = 121, Ucx86regxmm0 = 122,
      Ucx86regxmm1 = 123, Ucx86regxmm2 = 124, Ucx86regxmm3 = 125,
      Ucx86regxmm4 = 126, Ucx86regxmm5 = 127, Ucx86regxmm6 = 128,
      Ucx86regxmm7 = 129, Ucx86regxmm8 = 130, Ucx86regxmm9 = 131,
      Ucx86regxmm10 = 132, Ucx86regxmm11 = 133, Ucx86regxmm12 = 134,
      Ucx86regxmm13 = 135, Ucx86regxmm14 = 136, Ucx86regxmm15 = 137,
      Ucx86regxmm16 = 138, Ucx86regxmm17 = 139, Ucx86regxmm18 = 140,
      Ucx86regxmm19 = 141, Ucx86regxmm20 = 142, Ucx86regxmm21 = 143,
      Ucx86regxmm22 = 144, Ucx86regxmm23 = 145, Ucx86regxmm24 = 146,
      Ucx86regxmm25 = 147, Ucx86regxmm26 = 148, Ucx86regxmm27 = 149,
      Ucx86regxmm28 = 150, Ucx86regxmm29 = 151, Ucx86regxmm30 = 152,
      Ucx86regxmm31 = 153, Ucx86regymm0 = 154, Ucx86regymm1 = 155,
      Ucx86regymm2 = 156, Ucx86regymm3 = 157, Ucx86regymm4 = 158,
      Ucx86regymm5 = 159, Ucx86regymm6 = 160, Ucx86regymm7 = 161,
      Ucx86regymm8 = 162, Ucx86regymm9 = 163, Ucx86regymm10 = 164,
      Ucx86regymm11 = 165, Ucx86regymm12 = 166, Ucx86regymm13 = 167,
      Ucx86regymm14 = 168, Ucx86regymm15 = 169, Ucx86regymm16 = 170,
      Ucx86regymm17 = 171, Ucx86regymm18 = 172, Ucx86regymm19 = 173,
      Ucx86regymm20 = 174, Ucx86regymm21 = 175, Ucx86regymm22 = 176,
      Ucx86regymm23 = 177, Ucx86regymm24 = 178, Ucx86regymm25 = 179,
      Ucx86regymm26 = 180, Ucx86regymm27 = 181, Ucx86regymm28 = 182,
      Ucx86regymm29 = 183, Ucx86regymm30 = 184, Ucx86regymm31 = 185,
      Ucx86regzmm0 = 186, Ucx86regzmm1 = 187, Ucx86regzmm2 = 188,
      Ucx86regzmm3 = 189, Ucx86regzmm4 = 190, Ucx86regzmm5 = 191,
      Ucx86regzmm6 = 192, Ucx86regzmm7 = 193, Ucx86regzmm8 = 194,
      Ucx86regzmm9 = 195, Ucx86regzmm10 = 196, Ucx86regzmm11 = 197,
      Ucx86regzmm12 = 198, Ucx86regzmm13 = 199, Ucx86regzmm14 = 200,
      Ucx86regzmm15 = 201, Ucx86regzmm16 = 202, Ucx86regzmm17 = 203,
      Ucx86regzmm18 = 204, Ucx86regzmm19 = 205, Ucx86regzmm20 = 206,
      Ucx86regzmm21 = 207, Ucx86regzmm22 = 208, Ucx86regzmm23 = 209,
      Ucx86regzmm24 = 210, Ucx86regzmm25 = 211, Ucx86regzmm26 = 212,
      Ucx86regzmm27 = 213, Ucx86regzmm28 = 214, Ucx86regzmm29 = 215,
      Ucx86regzmm30 = 216, Ucx86regzmm31 = 217, Ucx86regr8b = 218,
      Ucx86regr9b = 219, Ucx86regr10b = 220, Ucx86regr11b = 221,
      Ucx86regr12b = 222, Ucx86regr13b = 223, Ucx86regr14b = 224,
      Ucx86regr15b = 225, Ucx86regr8d = 226, Ucx86regr9d = 227,
      Ucx86regr10d = 228, Ucx86regr11d = 229, Ucx86regr12d = 230,
      Ucx86regr13d = 231, Ucx86regr14d = 232, Ucx86regr15d = 233,
      Ucx86regr8w = 234, Ucx86regr9w = 235, Ucx86regr10w = 236,
      Ucx86regr11w = 237, Ucx86regr12w = 238, Ucx86regr13w = 239,
      Ucx86regr14w = 240, Ucx86regr15w = 241, Ucx86regidtr = 242,
      Ucx86reggdtr = 243, Ucx86regldtr = 244, Ucx86regtr = 245,
      Ucx86regfpcw = 246, Ucx86regfptag = 247, Ucx86regmsr = 248,
      Ucx86regmxcsr = 249, Ucx86regfsbase = 250, Ucx86reggsbase = 251,
      Ucx86regflags = 252, Ucx86regrflags = 253, Ucx86regfip = 254,
      Ucx86regfcs = 255, Ucx86regfdp = 256, Ucx86regfds = 257,
      Ucx86regfop = 258, Ucx86regending = 259
else:
  static :
    hint("Declaration of " & "enumucx86reg" & " already exists, not redeclaring")
when not declared(enumucx86insn):
  type
    enumucx86insn* {.size: sizeof(cuint).} = enum
      Ucx86insinvalid = 0, Ucx86insaaa = 1, Ucx86insaad = 2, Ucx86insaam = 3,
      Ucx86insaas = 4, Ucx86insfabs = 5, Ucx86insadc = 6, Ucx86insadcx = 7,
      Ucx86insadd = 8, Ucx86insaddpd = 9, Ucx86insaddps = 10,
      Ucx86insaddsd = 11, Ucx86insaddss = 12, Ucx86insaddsubpd = 13,
      Ucx86insaddsubps = 14, Ucx86insfadd = 15, Ucx86insfiadd = 16,
      Ucx86insfaddp = 17, Ucx86insadox = 18, Ucx86insaesdeclast = 19,
      Ucx86insaesdec = 20, Ucx86insaesenclast = 21, Ucx86insaesenc = 22,
      Ucx86insaesimc = 23, Ucx86insaeskeygenassist = 24, Ucx86insand = 25,
      Ucx86insandn = 26, Ucx86insandnpd = 27, Ucx86insandnps = 28,
      Ucx86insandpd = 29, Ucx86insandps = 30, Ucx86insarpl = 31,
      Ucx86insbextr = 32, Ucx86insblcfill = 33, Ucx86insblci = 34,
      Ucx86insblcic = 35, Ucx86insblcmsk = 36, Ucx86insblcs = 37,
      Ucx86insblendpd = 38, Ucx86insblendps = 39, Ucx86insblendvpd = 40,
      Ucx86insblendvps = 41, Ucx86insblsfill = 42, Ucx86insblsi = 43,
      Ucx86insblsic = 44, Ucx86insblsmsk = 45, Ucx86insblsr = 46,
      Ucx86insbound = 47, Ucx86insbsf = 48, Ucx86insbsr = 49,
      Ucx86insbswap = 50, Ucx86insbt = 51, Ucx86insbtc = 52, Ucx86insbtr = 53,
      Ucx86insbts = 54, Ucx86insbzhi = 55, Ucx86inscall = 56, Ucx86inscbw = 57,
      Ucx86inscdq = 58, Ucx86inscdqe = 59, Ucx86insfchs = 60, Ucx86insclac = 61,
      Ucx86insclc = 62, Ucx86inscld = 63, Ucx86insclflush = 64,
      Ucx86insclflushopt = 65, Ucx86insclgi = 66, Ucx86inscli = 67,
      Ucx86insclts = 68, Ucx86insclwb = 69, Ucx86inscmc = 70,
      Ucx86inscmova = 71, Ucx86inscmovae = 72, Ucx86inscmovb = 73,
      Ucx86inscmovbe = 74, Ucx86insfcmovbe = 75, Ucx86insfcmovb = 76,
      Ucx86inscmove = 77, Ucx86insfcmove = 78, Ucx86inscmovg = 79,
      Ucx86inscmovge = 80, Ucx86inscmovl = 81, Ucx86inscmovle = 82,
      Ucx86insfcmovnbe = 83, Ucx86insfcmovnb = 84, Ucx86inscmovne = 85,
      Ucx86insfcmovne = 86, Ucx86inscmovno = 87, Ucx86inscmovnp = 88,
      Ucx86insfcmovnu = 89, Ucx86inscmovns = 90, Ucx86inscmovo = 91,
      Ucx86inscmovp = 92, Ucx86insfcmovu = 93, Ucx86inscmovs = 94,
      Ucx86inscmp = 95, Ucx86inscmppd = 96, Ucx86inscmpps = 97,
      Ucx86inscmpsb = 98, Ucx86inscmpsd = 99, Ucx86inscmpsq = 100,
      Ucx86inscmpss = 101, Ucx86inscmpsw = 102, Ucx86inscmpxchg16b = 103,
      Ucx86inscmpxchg = 104, Ucx86inscmpxchg8b = 105, Ucx86inscomisd = 106,
      Ucx86inscomiss = 107, Ucx86insfcomp = 108, Ucx86insfcompi = 109,
      Ucx86insfcomi = 110, Ucx86insfcom = 111, Ucx86insfcos = 112,
      Ucx86inscpuid = 113, Ucx86inscqo = 114, Ucx86inscrc32 = 115,
      Ucx86inscvtdq2pd = 116, Ucx86inscvtdq2ps = 117, Ucx86inscvtpd2dq = 118,
      Ucx86inscvtpd2ps = 119, Ucx86inscvtps2dq = 120, Ucx86inscvtps2pd = 121,
      Ucx86inscvtsd2si = 122, Ucx86inscvtsd2ss = 123, Ucx86inscvtsi2sd = 124,
      Ucx86inscvtsi2ss = 125, Ucx86inscvtss2sd = 126, Ucx86inscvtss2si = 127,
      Ucx86inscvttpd2dq = 128, Ucx86inscvttps2dq = 129, Ucx86inscvttsd2si = 130,
      Ucx86inscvttss2si = 131, Ucx86inscwd = 132, Ucx86inscwde = 133,
      Ucx86insdaa = 134, Ucx86insdas = 135, Ucx86insdata16 = 136,
      Ucx86insdec = 137, Ucx86insdiv = 138, Ucx86insdivpd = 139,
      Ucx86insdivps = 140, Ucx86insfdivr = 141, Ucx86insfidivr = 142,
      Ucx86insfdivrp = 143, Ucx86insdivsd = 144, Ucx86insdivss = 145,
      Ucx86insfdiv = 146, Ucx86insfidiv = 147, Ucx86insfdivp = 148,
      Ucx86insdppd = 149, Ucx86insdpps = 150, Ucx86insret = 151,
      Ucx86insencls = 152, Ucx86insenclu = 153, Ucx86insenter = 154,
      Ucx86insextractps = 155, Ucx86insextrq = 156, Ucx86insf2xm1 = 157,
      Ucx86inslcall = 158, Ucx86insljmp = 159, Ucx86insfbld = 160,
      Ucx86insfbstp = 161, Ucx86insfcompp = 162, Ucx86insfdecstp = 163,
      Ucx86insfemms = 164, Ucx86insffree = 165, Ucx86insficom = 166,
      Ucx86insficomp = 167, Ucx86insfincstp = 168, Ucx86insfldcw = 169,
      Ucx86insfldenv = 170, Ucx86insfldl2e = 171, Ucx86insfldl2t = 172,
      Ucx86insfldlg2 = 173, Ucx86insfldln2 = 174, Ucx86insfldpi = 175,
      Ucx86insfnclex = 176, Ucx86insfninit = 177, Ucx86insfnop = 178,
      Ucx86insfnstcw = 179, Ucx86insfnstsw = 180, Ucx86insfpatan = 181,
      Ucx86insfprem = 182, Ucx86insfprem1 = 183, Ucx86insfptan = 184,
      Ucx86insffreep = 185, Ucx86insfrndint = 186, Ucx86insfrstor = 187,
      Ucx86insfnsave = 188, Ucx86insfscale = 189, Ucx86insfsetpm = 190,
      Ucx86insfsincos = 191, Ucx86insfnstenv = 192, Ucx86insfxam = 193,
      Ucx86insfxrstor = 194, Ucx86insfxrstor64 = 195, Ucx86insfxsave = 196,
      Ucx86insfxsave64 = 197, Ucx86insfxtract = 198, Ucx86insfyl2x = 199,
      Ucx86insfyl2xp1 = 200, Ucx86insmovapd = 201, Ucx86insmovaps = 202,
      Ucx86insorpd = 203, Ucx86insorps = 204, Ucx86insvmovapd = 205,
      Ucx86insvmovaps = 206, Ucx86insxorpd = 207, Ucx86insxorps = 208,
      Ucx86insgetsec = 209, Ucx86inshaddpd = 210, Ucx86inshaddps = 211,
      Ucx86inshlt = 212, Ucx86inshsubpd = 213, Ucx86inshsubps = 214,
      Ucx86insidiv = 215, Ucx86insfild = 216, Ucx86insimul = 217,
      Ucx86insin = 218, Ucx86insinc = 219, Ucx86insinsb = 220,
      Ucx86insinsertps = 221, Ucx86insinsertq = 222, Ucx86insinsd = 223,
      Ucx86insinsw = 224, Ucx86insint = 225, Ucx86insint1 = 226,
      Ucx86insint3 = 227, Ucx86insinto = 228, Ucx86insinvd = 229,
      Ucx86insinvept = 230, Ucx86insinvlpg = 231, Ucx86insinvlpga = 232,
      Ucx86insinvpcid = 233, Ucx86insinvvpid = 234, Ucx86insiret = 235,
      Ucx86insiretd = 236, Ucx86insiretq = 237, Ucx86insfisttp = 238,
      Ucx86insfist = 239, Ucx86insfistp = 240, Ucx86insucomisd = 241,
      Ucx86insucomiss = 242, Ucx86insvcomisd = 243, Ucx86insvcomiss = 244,
      Ucx86insvcvtsd2ss = 245, Ucx86insvcvtsi2sd = 246, Ucx86insvcvtsi2ss = 247,
      Ucx86insvcvtss2sd = 248, Ucx86insvcvttsd2si = 249,
      Ucx86insvcvttsd2usi = 250, Ucx86insvcvttss2si = 251,
      Ucx86insvcvttss2usi = 252, Ucx86insvcvtusi2sd = 253,
      Ucx86insvcvtusi2ss = 254, Ucx86insvucomisd = 255, Ucx86insvucomiss = 256,
      Ucx86insjae = 257, Ucx86insja = 258, Ucx86insjbe = 259, Ucx86insjb = 260,
      Ucx86insjcxz = 261, Ucx86insjecxz = 262, Ucx86insje = 263,
      Ucx86insjge = 264, Ucx86insjg = 265, Ucx86insjle = 266, Ucx86insjl = 267,
      Ucx86insjmp = 268, Ucx86insjne = 269, Ucx86insjno = 270,
      Ucx86insjnp = 271, Ucx86insjns = 272, Ucx86insjo = 273, Ucx86insjp = 274,
      Ucx86insjrcxz = 275, Ucx86insjs = 276, Ucx86inskandb = 277,
      Ucx86inskandd = 278, Ucx86inskandnb = 279, Ucx86inskandnd = 280,
      Ucx86inskandnq = 281, Ucx86inskandnw = 282, Ucx86inskandq = 283,
      Ucx86inskandw = 284, Ucx86inskmovb = 285, Ucx86inskmovd = 286,
      Ucx86inskmovq = 287, Ucx86inskmovw = 288, Ucx86insknotb = 289,
      Ucx86insknotd = 290, Ucx86insknotq = 291, Ucx86insknotw = 292,
      Ucx86inskorb = 293, Ucx86inskord = 294, Ucx86inskorq = 295,
      Ucx86inskortestb = 296, Ucx86inskortestd = 297, Ucx86inskortestq = 298,
      Ucx86inskortestw = 299, Ucx86inskorw = 300, Ucx86inskshiftlb = 301,
      Ucx86inskshiftld = 302, Ucx86inskshiftlq = 303, Ucx86inskshiftlw = 304,
      Ucx86inskshiftrb = 305, Ucx86inskshiftrd = 306, Ucx86inskshiftrq = 307,
      Ucx86inskshiftrw = 308, Ucx86inskunpckbw = 309, Ucx86inskxnorb = 310,
      Ucx86inskxnord = 311, Ucx86inskxnorq = 312, Ucx86inskxnorw = 313,
      Ucx86inskxorb = 314, Ucx86inskxord = 315, Ucx86inskxorq = 316,
      Ucx86inskxorw = 317, Ucx86inslahf = 318, Ucx86inslar = 319,
      Ucx86inslddqu = 320, Ucx86insldmxcsr = 321, Ucx86inslds = 322,
      Ucx86insfldz = 323, Ucx86insfld1 = 324, Ucx86insfld = 325,
      Ucx86inslea = 326, Ucx86insleave = 327, Ucx86insles = 328,
      Ucx86inslfence = 329, Ucx86inslfs = 330, Ucx86inslgdt = 331,
      Ucx86inslgs = 332, Ucx86inslidt = 333, Ucx86inslldt = 334,
      Ucx86inslmsw = 335, Ucx86insor = 336, Ucx86inssub = 337,
      Ucx86insxor = 338, Ucx86inslodsb = 339, Ucx86inslodsd = 340,
      Ucx86inslodsq = 341, Ucx86inslodsw = 342, Ucx86insloop = 343,
      Ucx86insloope = 344, Ucx86insloopne = 345, Ucx86insretf = 346,
      Ucx86insretfq = 347, Ucx86inslsl = 348, Ucx86inslss = 349,
      Ucx86insltr = 350, Ucx86insxadd = 351, Ucx86inslzcnt = 352,
      Ucx86insmaskmovdqu = 353, Ucx86insmaxpd = 354, Ucx86insmaxps = 355,
      Ucx86insmaxsd = 356, Ucx86insmaxss = 357, Ucx86insmfence = 358,
      Ucx86insminpd = 359, Ucx86insminps = 360, Ucx86insminsd = 361,
      Ucx86insminss = 362, Ucx86inscvtpd2pi = 363, Ucx86inscvtpi2pd = 364,
      Ucx86inscvtpi2ps = 365, Ucx86inscvtps2pi = 366, Ucx86inscvttpd2pi = 367,
      Ucx86inscvttps2pi = 368, Ucx86insemms = 369, Ucx86insmaskmovq = 370,
      Ucx86insmovd = 371, Ucx86insmovdq2q = 372, Ucx86insmovntq = 373,
      Ucx86insmovq2dq = 374, Ucx86insmovq = 375, Ucx86inspabsb = 376,
      Ucx86inspabsd = 377, Ucx86inspabsw = 378, Ucx86inspackssdw = 379,
      Ucx86inspacksswb = 380, Ucx86inspackuswb = 381, Ucx86inspaddb = 382,
      Ucx86inspaddd = 383, Ucx86inspaddq = 384, Ucx86inspaddsb = 385,
      Ucx86inspaddsw = 386, Ucx86inspaddusb = 387, Ucx86inspaddusw = 388,
      Ucx86inspaddw = 389, Ucx86inspalignr = 390, Ucx86inspandn = 391,
      Ucx86inspand = 392, Ucx86inspavgb = 393, Ucx86inspavgw = 394,
      Ucx86inspcmpeqb = 395, Ucx86inspcmpeqd = 396, Ucx86inspcmpeqw = 397,
      Ucx86inspcmpgtb = 398, Ucx86inspcmpgtd = 399, Ucx86inspcmpgtw = 400,
      Ucx86inspextrw = 401, Ucx86insphaddsw = 402, Ucx86insphaddw = 403,
      Ucx86insphaddd = 404, Ucx86insphsubd = 405, Ucx86insphsubsw = 406,
      Ucx86insphsubw = 407, Ucx86inspinsrw = 408, Ucx86inspmaddubsw = 409,
      Ucx86inspmaddwd = 410, Ucx86inspmaxsw = 411, Ucx86inspmaxub = 412,
      Ucx86inspminsw = 413, Ucx86inspminub = 414, Ucx86inspmovmskb = 415,
      Ucx86inspmulhrsw = 416, Ucx86inspmulhuw = 417, Ucx86inspmulhw = 418,
      Ucx86inspmullw = 419, Ucx86inspmuludq = 420, Ucx86inspor = 421,
      Ucx86inspsadbw = 422, Ucx86inspshufb = 423, Ucx86inspshufw = 424,
      Ucx86inspsignb = 425, Ucx86inspsignd = 426, Ucx86inspsignw = 427,
      Ucx86inspslld = 428, Ucx86inspsllq = 429, Ucx86inspsllw = 430,
      Ucx86inspsrad = 431, Ucx86inspsraw = 432, Ucx86inspsrld = 433,
      Ucx86inspsrlq = 434, Ucx86inspsrlw = 435, Ucx86inspsubb = 436,
      Ucx86inspsubd = 437, Ucx86inspsubq = 438, Ucx86inspsubsb = 439,
      Ucx86inspsubsw = 440, Ucx86inspsubusb = 441, Ucx86inspsubusw = 442,
      Ucx86inspsubw = 443, Ucx86inspunpckhbw = 444, Ucx86inspunpckhdq = 445,
      Ucx86inspunpckhwd = 446, Ucx86inspunpcklbw = 447, Ucx86inspunpckldq = 448,
      Ucx86inspunpcklwd = 449, Ucx86inspxor = 450, Ucx86insmonitor = 451,
      Ucx86insmontmul = 452, Ucx86insmov = 453, Ucx86insmovabs = 454,
      Ucx86insmovbe = 455, Ucx86insmovddup = 456, Ucx86insmovdqa = 457,
      Ucx86insmovdqu = 458, Ucx86insmovhlps = 459, Ucx86insmovhpd = 460,
      Ucx86insmovhps = 461, Ucx86insmovlhps = 462, Ucx86insmovlpd = 463,
      Ucx86insmovlps = 464, Ucx86insmovmskpd = 465, Ucx86insmovmskps = 466,
      Ucx86insmovntdqa = 467, Ucx86insmovntdq = 468, Ucx86insmovnti = 469,
      Ucx86insmovntpd = 470, Ucx86insmovntps = 471, Ucx86insmovntsd = 472,
      Ucx86insmovntss = 473, Ucx86insmovsb = 474, Ucx86insmovsd = 475,
      Ucx86insmovshdup = 476, Ucx86insmovsldup = 477, Ucx86insmovsq = 478,
      Ucx86insmovss = 479, Ucx86insmovsw = 480, Ucx86insmovsx = 481,
      Ucx86insmovsxd = 482, Ucx86insmovupd = 483, Ucx86insmovups = 484,
      Ucx86insmovzx = 485, Ucx86insmpsadbw = 486, Ucx86insmul = 487,
      Ucx86insmulpd = 488, Ucx86insmulps = 489, Ucx86insmulsd = 490,
      Ucx86insmulss = 491, Ucx86insmulx = 492, Ucx86insfmul = 493,
      Ucx86insfimul = 494, Ucx86insfmulp = 495, Ucx86insmwait = 496,
      Ucx86insneg = 497, Ucx86insnop = 498, Ucx86insnot = 499,
      Ucx86insout = 500, Ucx86insoutsb = 501, Ucx86insoutsd = 502,
      Ucx86insoutsw = 503, Ucx86inspackusdw = 504, Ucx86inspause = 505,
      Ucx86inspavgusb = 506, Ucx86inspblendvb = 507, Ucx86inspblendw = 508,
      Ucx86inspclmulqdq = 509, Ucx86inspcmpeqq = 510, Ucx86inspcmpestri = 511,
      Ucx86inspcmpestrm = 512, Ucx86inspcmpgtq = 513, Ucx86inspcmpistri = 514,
      Ucx86inspcmpistrm = 515, Ucx86inspcommit = 516, Ucx86inspdep = 517,
      Ucx86inspext = 518, Ucx86inspextrb = 519, Ucx86inspextrd = 520,
      Ucx86inspextrq = 521, Ucx86inspf2id = 522, Ucx86inspf2iw = 523,
      Ucx86inspfacc = 524, Ucx86inspfadd = 525, Ucx86inspfcmpeq = 526,
      Ucx86inspfcmpge = 527, Ucx86inspfcmpgt = 528, Ucx86inspfmax = 529,
      Ucx86inspfmin = 530, Ucx86inspfmul = 531, Ucx86inspfnacc = 532,
      Ucx86inspfpnacc = 533, Ucx86inspfrcpit1 = 534, Ucx86inspfrcpit2 = 535,
      Ucx86inspfrcp = 536, Ucx86inspfrsqit1 = 537, Ucx86inspfrsqrt = 538,
      Ucx86inspfsubr = 539, Ucx86inspfsub = 540, Ucx86insphminposuw = 541,
      Ucx86inspi2fd = 542, Ucx86inspi2fw = 543, Ucx86inspinsrb = 544,
      Ucx86inspinsrd = 545, Ucx86inspinsrq = 546, Ucx86inspmaxsb = 547,
      Ucx86inspmaxsd = 548, Ucx86inspmaxud = 549, Ucx86inspmaxuw = 550,
      Ucx86inspminsb = 551, Ucx86inspminsd = 552, Ucx86inspminud = 553,
      Ucx86inspminuw = 554, Ucx86inspmovsxbd = 555, Ucx86inspmovsxbq = 556,
      Ucx86inspmovsxbw = 557, Ucx86inspmovsxdq = 558, Ucx86inspmovsxwd = 559,
      Ucx86inspmovsxwq = 560, Ucx86inspmovzxbd = 561, Ucx86inspmovzxbq = 562,
      Ucx86inspmovzxbw = 563, Ucx86inspmovzxdq = 564, Ucx86inspmovzxwd = 565,
      Ucx86inspmovzxwq = 566, Ucx86inspmuldq = 567, Ucx86inspmulhrw = 568,
      Ucx86inspmulld = 569, Ucx86inspop = 570, Ucx86inspopaw = 571,
      Ucx86inspopal = 572, Ucx86inspopcnt = 573, Ucx86inspopf = 574,
      Ucx86inspopfd = 575, Ucx86inspopfq = 576, Ucx86insprefetch = 577,
      Ucx86insprefetchnta = 578, Ucx86insprefetcht0 = 579,
      Ucx86insprefetcht1 = 580, Ucx86insprefetcht2 = 581,
      Ucx86insprefetchw = 582, Ucx86inspshufd = 583, Ucx86inspshufhw = 584,
      Ucx86inspshuflw = 585, Ucx86inspslldq = 586, Ucx86inspsrldq = 587,
      Ucx86inspswapd = 588, Ucx86insptest = 589, Ucx86inspunpckhqdq = 590,
      Ucx86inspunpcklqdq = 591, Ucx86inspush = 592, Ucx86inspushaw = 593,
      Ucx86inspushal = 594, Ucx86inspushf = 595, Ucx86inspushfd = 596,
      Ucx86inspushfq = 597, Ucx86insrcl = 598, Ucx86insrcpps = 599,
      Ucx86insrcpss = 600, Ucx86insrcr = 601, Ucx86insrdfsbase = 602,
      Ucx86insrdgsbase = 603, Ucx86insrdmsr = 604, Ucx86insrdpmc = 605,
      Ucx86insrdrand = 606, Ucx86insrdseed = 607, Ucx86insrdtsc = 608,
      Ucx86insrdtscp = 609, Ucx86insrol = 610, Ucx86insror = 611,
      Ucx86insrorx = 612, Ucx86insroundpd = 613, Ucx86insroundps = 614,
      Ucx86insroundsd = 615, Ucx86insroundss = 616, Ucx86insrsm = 617,
      Ucx86insrsqrtps = 618, Ucx86insrsqrtss = 619, Ucx86inssahf = 620,
      Ucx86inssal = 621, Ucx86inssalc = 622, Ucx86inssar = 623,
      Ucx86inssarx = 624, Ucx86inssbb = 625, Ucx86insscasb = 626,
      Ucx86insscasd = 627, Ucx86insscasq = 628, Ucx86insscasw = 629,
      Ucx86inssetae = 630, Ucx86insseta = 631, Ucx86inssetbe = 632,
      Ucx86inssetb = 633, Ucx86inssete = 634, Ucx86inssetge = 635,
      Ucx86inssetg = 636, Ucx86inssetle = 637, Ucx86inssetl = 638,
      Ucx86inssetne = 639, Ucx86inssetno = 640, Ucx86inssetnp = 641,
      Ucx86inssetns = 642, Ucx86insseto = 643, Ucx86inssetp = 644,
      Ucx86inssets = 645, Ucx86inssfence = 646, Ucx86inssgdt = 647,
      Ucx86inssha1msg1 = 648, Ucx86inssha1msg2 = 649, Ucx86inssha1nexte = 650,
      Ucx86inssha1rnds4 = 651, Ucx86inssha256msg1 = 652,
      Ucx86inssha256msg2 = 653, Ucx86inssha256rnds2 = 654, Ucx86insshl = 655,
      Ucx86insshld = 656, Ucx86insshlx = 657, Ucx86insshr = 658,
      Ucx86insshrd = 659, Ucx86insshrx = 660, Ucx86insshufpd = 661,
      Ucx86insshufps = 662, Ucx86inssidt = 663, Ucx86insfsin = 664,
      Ucx86insskinit = 665, Ucx86inssldt = 666, Ucx86inssmsw = 667,
      Ucx86inssqrtpd = 668, Ucx86inssqrtps = 669, Ucx86inssqrtsd = 670,
      Ucx86inssqrtss = 671, Ucx86insfsqrt = 672, Ucx86insstac = 673,
      Ucx86insstc = 674, Ucx86insstd = 675, Ucx86insstgi = 676,
      Ucx86inssti = 677, Ucx86insstmxcsr = 678, Ucx86insstosb = 679,
      Ucx86insstosd = 680, Ucx86insstosq = 681, Ucx86insstosw = 682,
      Ucx86insstr = 683, Ucx86insfst = 684, Ucx86insfstp = 685,
      Ucx86insfstpnce = 686, Ucx86insfxch = 687, Ucx86inssubpd = 688,
      Ucx86inssubps = 689, Ucx86insfsubr = 690, Ucx86insfisubr = 691,
      Ucx86insfsubrp = 692, Ucx86inssubsd = 693, Ucx86inssubss = 694,
      Ucx86insfsub = 695, Ucx86insfisub = 696, Ucx86insfsubp = 697,
      Ucx86insswapgs = 698, Ucx86inssyscall = 699, Ucx86inssysenter = 700,
      Ucx86inssysexit = 701, Ucx86inssysret = 702, Ucx86inst1mskc = 703,
      Ucx86instest = 704, Ucx86insud2 = 705, Ucx86insftst = 706,
      Ucx86instzcnt = 707, Ucx86instzmsk = 708, Ucx86insfucompi = 709,
      Ucx86insfucomi = 710, Ucx86insfucompp = 711, Ucx86insfucomp = 712,
      Ucx86insfucom = 713, Ucx86insud2b = 714, Ucx86insunpckhpd = 715,
      Ucx86insunpckhps = 716, Ucx86insunpcklpd = 717, Ucx86insunpcklps = 718,
      Ucx86insvaddpd = 719, Ucx86insvaddps = 720, Ucx86insvaddsd = 721,
      Ucx86insvaddss = 722, Ucx86insvaddsubpd = 723, Ucx86insvaddsubps = 724,
      Ucx86insvaesdeclast = 725, Ucx86insvaesdec = 726,
      Ucx86insvaesenclast = 727, Ucx86insvaesenc = 728, Ucx86insvaesimc = 729,
      Ucx86insvaeskeygenassist = 730, Ucx86insvalignd = 731,
      Ucx86insvalignq = 732, Ucx86insvandnpd = 733, Ucx86insvandnps = 734,
      Ucx86insvandpd = 735, Ucx86insvandps = 736, Ucx86insvblendmpd = 737,
      Ucx86insvblendmps = 738, Ucx86insvblendpd = 739, Ucx86insvblendps = 740,
      Ucx86insvblendvpd = 741, Ucx86insvblendvps = 742,
      Ucx86insvbroadcastf128 = 743, Ucx86insvbroadcasti32x4 = 744,
      Ucx86insvbroadcasti64x4 = 745, Ucx86insvbroadcastsd = 746,
      Ucx86insvbroadcastss = 747, Ucx86insvcmppd = 748, Ucx86insvcmpps = 749,
      Ucx86insvcmpsd = 750, Ucx86insvcmpss = 751, Ucx86insvcompresspd = 752,
      Ucx86insvcompressps = 753, Ucx86insvcvtdq2pd = 754,
      Ucx86insvcvtdq2ps = 755, Ucx86insvcvtpd2dqx = 756,
      Ucx86insvcvtpd2dq = 757, Ucx86insvcvtpd2psx = 758,
      Ucx86insvcvtpd2ps = 759, Ucx86insvcvtpd2udq = 760,
      Ucx86insvcvtph2ps = 761, Ucx86insvcvtps2dq = 762, Ucx86insvcvtps2pd = 763,
      Ucx86insvcvtps2ph = 764, Ucx86insvcvtps2udq = 765,
      Ucx86insvcvtsd2si = 766, Ucx86insvcvtsd2usi = 767,
      Ucx86insvcvtss2si = 768, Ucx86insvcvtss2usi = 769,
      Ucx86insvcvttpd2dqx = 770, Ucx86insvcvttpd2dq = 771,
      Ucx86insvcvttpd2udq = 772, Ucx86insvcvttps2dq = 773,
      Ucx86insvcvttps2udq = 774, Ucx86insvcvtudq2pd = 775,
      Ucx86insvcvtudq2ps = 776, Ucx86insvdivpd = 777, Ucx86insvdivps = 778,
      Ucx86insvdivsd = 779, Ucx86insvdivss = 780, Ucx86insvdppd = 781,
      Ucx86insvdpps = 782, Ucx86insverr = 783, Ucx86insverw = 784,
      Ucx86insvexp2pd = 785, Ucx86insvexp2ps = 786, Ucx86insvexpandpd = 787,
      Ucx86insvexpandps = 788, Ucx86insvextractf128 = 789,
      Ucx86insvextractf32x4 = 790, Ucx86insvextractf64x4 = 791,
      Ucx86insvextracti128 = 792, Ucx86insvextracti32x4 = 793,
      Ucx86insvextracti64x4 = 794, Ucx86insvextractps = 795,
      Ucx86insvfmadd132pd = 796, Ucx86insvfmadd132ps = 797,
      Ucx86insvfmaddpd = 798, Ucx86insvfmadd213pd = 799,
      Ucx86insvfmadd231pd = 800, Ucx86insvfmaddps = 801,
      Ucx86insvfmadd213ps = 802, Ucx86insvfmadd231ps = 803,
      Ucx86insvfmaddsd = 804, Ucx86insvfmadd213sd = 805,
      Ucx86insvfmadd132sd = 806, Ucx86insvfmadd231sd = 807,
      Ucx86insvfmaddss = 808, Ucx86insvfmadd213ss = 809,
      Ucx86insvfmadd132ss = 810, Ucx86insvfmadd231ss = 811,
      Ucx86insvfmaddsub132pd = 812, Ucx86insvfmaddsub132ps = 813,
      Ucx86insvfmaddsubpd = 814, Ucx86insvfmaddsub213pd = 815,
      Ucx86insvfmaddsub231pd = 816, Ucx86insvfmaddsubps = 817,
      Ucx86insvfmaddsub213ps = 818, Ucx86insvfmaddsub231ps = 819,
      Ucx86insvfmsub132pd = 820, Ucx86insvfmsub132ps = 821,
      Ucx86insvfmsubadd132pd = 822, Ucx86insvfmsubadd132ps = 823,
      Ucx86insvfmsubaddpd = 824, Ucx86insvfmsubadd213pd = 825,
      Ucx86insvfmsubadd231pd = 826, Ucx86insvfmsubaddps = 827,
      Ucx86insvfmsubadd213ps = 828, Ucx86insvfmsubadd231ps = 829,
      Ucx86insvfmsubpd = 830, Ucx86insvfmsub213pd = 831,
      Ucx86insvfmsub231pd = 832, Ucx86insvfmsubps = 833,
      Ucx86insvfmsub213ps = 834, Ucx86insvfmsub231ps = 835,
      Ucx86insvfmsubsd = 836, Ucx86insvfmsub213sd = 837,
      Ucx86insvfmsub132sd = 838, Ucx86insvfmsub231sd = 839,
      Ucx86insvfmsubss = 840, Ucx86insvfmsub213ss = 841,
      Ucx86insvfmsub132ss = 842, Ucx86insvfmsub231ss = 843,
      Ucx86insvfnmadd132pd = 844, Ucx86insvfnmadd132ps = 845,
      Ucx86insvfnmaddpd = 846, Ucx86insvfnmadd213pd = 847,
      Ucx86insvfnmadd231pd = 848, Ucx86insvfnmaddps = 849,
      Ucx86insvfnmadd213ps = 850, Ucx86insvfnmadd231ps = 851,
      Ucx86insvfnmaddsd = 852, Ucx86insvfnmadd213sd = 853,
      Ucx86insvfnmadd132sd = 854, Ucx86insvfnmadd231sd = 855,
      Ucx86insvfnmaddss = 856, Ucx86insvfnmadd213ss = 857,
      Ucx86insvfnmadd132ss = 858, Ucx86insvfnmadd231ss = 859,
      Ucx86insvfnmsub132pd = 860, Ucx86insvfnmsub132ps = 861,
      Ucx86insvfnmsubpd = 862, Ucx86insvfnmsub213pd = 863,
      Ucx86insvfnmsub231pd = 864, Ucx86insvfnmsubps = 865,
      Ucx86insvfnmsub213ps = 866, Ucx86insvfnmsub231ps = 867,
      Ucx86insvfnmsubsd = 868, Ucx86insvfnmsub213sd = 869,
      Ucx86insvfnmsub132sd = 870, Ucx86insvfnmsub231sd = 871,
      Ucx86insvfnmsubss = 872, Ucx86insvfnmsub213ss = 873,
      Ucx86insvfnmsub132ss = 874, Ucx86insvfnmsub231ss = 875,
      Ucx86insvfrczpd = 876, Ucx86insvfrczps = 877, Ucx86insvfrczsd = 878,
      Ucx86insvfrczss = 879, Ucx86insvorpd = 880, Ucx86insvorps = 881,
      Ucx86insvxorpd = 882, Ucx86insvxorps = 883, Ucx86insvgatherdpd = 884,
      Ucx86insvgatherdps = 885, Ucx86insvgatherpf0dpd = 886,
      Ucx86insvgatherpf0dps = 887, Ucx86insvgatherpf0qpd = 888,
      Ucx86insvgatherpf0qps = 889, Ucx86insvgatherpf1dpd = 890,
      Ucx86insvgatherpf1dps = 891, Ucx86insvgatherpf1qpd = 892,
      Ucx86insvgatherpf1qps = 893, Ucx86insvgatherqpd = 894,
      Ucx86insvgatherqps = 895, Ucx86insvhaddpd = 896, Ucx86insvhaddps = 897,
      Ucx86insvhsubpd = 898, Ucx86insvhsubps = 899, Ucx86insvinsertf128 = 900,
      Ucx86insvinsertf32x4 = 901, Ucx86insvinsertf32x8 = 902,
      Ucx86insvinsertf64x2 = 903, Ucx86insvinsertf64x4 = 904,
      Ucx86insvinserti128 = 905, Ucx86insvinserti32x4 = 906,
      Ucx86insvinserti32x8 = 907, Ucx86insvinserti64x2 = 908,
      Ucx86insvinserti64x4 = 909, Ucx86insvinsertps = 910, Ucx86insvlddqu = 911,
      Ucx86insvldmxcsr = 912, Ucx86insvmaskmovdqu = 913,
      Ucx86insvmaskmovpd = 914, Ucx86insvmaskmovps = 915, Ucx86insvmaxpd = 916,
      Ucx86insvmaxps = 917, Ucx86insvmaxsd = 918, Ucx86insvmaxss = 919,
      Ucx86insvmcall = 920, Ucx86insvmclear = 921, Ucx86insvmfunc = 922,
      Ucx86insvminpd = 923, Ucx86insvminps = 924, Ucx86insvminsd = 925,
      Ucx86insvminss = 926, Ucx86insvmlaunch = 927, Ucx86insvmload = 928,
      Ucx86insvmmcall = 929, Ucx86insvmovq = 930, Ucx86insvmovddup = 931,
      Ucx86insvmovd = 932, Ucx86insvmovdqa32 = 933, Ucx86insvmovdqa64 = 934,
      Ucx86insvmovdqa = 935, Ucx86insvmovdqu16 = 936, Ucx86insvmovdqu32 = 937,
      Ucx86insvmovdqu64 = 938, Ucx86insvmovdqu8 = 939, Ucx86insvmovdqu = 940,
      Ucx86insvmovhlps = 941, Ucx86insvmovhpd = 942, Ucx86insvmovhps = 943,
      Ucx86insvmovlhps = 944, Ucx86insvmovlpd = 945, Ucx86insvmovlps = 946,
      Ucx86insvmovmskpd = 947, Ucx86insvmovmskps = 948, Ucx86insvmovntdqa = 949,
      Ucx86insvmovntdq = 950, Ucx86insvmovntpd = 951, Ucx86insvmovntps = 952,
      Ucx86insvmovsd = 953, Ucx86insvmovshdup = 954, Ucx86insvmovsldup = 955,
      Ucx86insvmovss = 956, Ucx86insvmovupd = 957, Ucx86insvmovups = 958,
      Ucx86insvmpsadbw = 959, Ucx86insvmptrld = 960, Ucx86insvmptrst = 961,
      Ucx86insvmread = 962, Ucx86insvmresume = 963, Ucx86insvmrun = 964,
      Ucx86insvmsave = 965, Ucx86insvmulpd = 966, Ucx86insvmulps = 967,
      Ucx86insvmulsd = 968, Ucx86insvmulss = 969, Ucx86insvmwrite = 970,
      Ucx86insvmxoff = 971, Ucx86insvmxon = 972, Ucx86insvpabsb = 973,
      Ucx86insvpabsd = 974, Ucx86insvpabsq = 975, Ucx86insvpabsw = 976,
      Ucx86insvpackssdw = 977, Ucx86insvpacksswb = 978, Ucx86insvpackusdw = 979,
      Ucx86insvpackuswb = 980, Ucx86insvpaddb = 981, Ucx86insvpaddd = 982,
      Ucx86insvpaddq = 983, Ucx86insvpaddsb = 984, Ucx86insvpaddsw = 985,
      Ucx86insvpaddusb = 986, Ucx86insvpaddusw = 987, Ucx86insvpaddw = 988,
      Ucx86insvpalignr = 989, Ucx86insvpandd = 990, Ucx86insvpandnd = 991,
      Ucx86insvpandnq = 992, Ucx86insvpandn = 993, Ucx86insvpandq = 994,
      Ucx86insvpand = 995, Ucx86insvpavgb = 996, Ucx86insvpavgw = 997,
      Ucx86insvpblendd = 998, Ucx86insvpblendmb = 999, Ucx86insvpblendmd = 1000,
      Ucx86insvpblendmq = 1001, Ucx86insvpblendmw = 1002,
      Ucx86insvpblendvb = 1003, Ucx86insvpblendw = 1004,
      Ucx86insvpbroadcastb = 1005, Ucx86insvpbroadcastd = 1006,
      Ucx86insvpbroadcastmb2q = 1007, Ucx86insvpbroadcastmw2d = 1008,
      Ucx86insvpbroadcastq = 1009, Ucx86insvpbroadcastw = 1010,
      Ucx86insvpclmulqdq = 1011, Ucx86insvpcmov = 1012, Ucx86insvpcmpb = 1013,
      Ucx86insvpcmpd = 1014, Ucx86insvpcmpeqb = 1015, Ucx86insvpcmpeqd = 1016,
      Ucx86insvpcmpeqq = 1017, Ucx86insvpcmpeqw = 1018,
      Ucx86insvpcmpestri = 1019, Ucx86insvpcmpestrm = 1020,
      Ucx86insvpcmpgtb = 1021, Ucx86insvpcmpgtd = 1022, Ucx86insvpcmpgtq = 1023,
      Ucx86insvpcmpgtw = 1024, Ucx86insvpcmpistri = 1025,
      Ucx86insvpcmpistrm = 1026, Ucx86insvpcmpq = 1027, Ucx86insvpcmpub = 1028,
      Ucx86insvpcmpud = 1029, Ucx86insvpcmpuq = 1030, Ucx86insvpcmpuw = 1031,
      Ucx86insvpcmpw = 1032, Ucx86insvpcomb = 1033, Ucx86insvpcomd = 1034,
      Ucx86insvpcompressd = 1035, Ucx86insvpcompressq = 1036,
      Ucx86insvpcomq = 1037, Ucx86insvpcomub = 1038, Ucx86insvpcomud = 1039,
      Ucx86insvpcomuq = 1040, Ucx86insvpcomuw = 1041, Ucx86insvpcomw = 1042,
      Ucx86insvpconflictd = 1043, Ucx86insvpconflictq = 1044,
      Ucx86insvperm2f128 = 1045, Ucx86insvperm2i128 = 1046,
      Ucx86insvpermd = 1047, Ucx86insvpermi2d = 1048, Ucx86insvpermi2pd = 1049,
      Ucx86insvpermi2ps = 1050, Ucx86insvpermi2q = 1051,
      Ucx86insvpermil2pd = 1052, Ucx86insvpermil2ps = 1053,
      Ucx86insvpermilpd = 1054, Ucx86insvpermilps = 1055,
      Ucx86insvpermpd = 1056, Ucx86insvpermps = 1057, Ucx86insvpermq = 1058,
      Ucx86insvpermt2d = 1059, Ucx86insvpermt2pd = 1060,
      Ucx86insvpermt2ps = 1061, Ucx86insvpermt2q = 1062,
      Ucx86insvpexpandd = 1063, Ucx86insvpexpandq = 1064,
      Ucx86insvpextrb = 1065, Ucx86insvpextrd = 1066, Ucx86insvpextrq = 1067,
      Ucx86insvpextrw = 1068, Ucx86insvpgatherdd = 1069,
      Ucx86insvpgatherdq = 1070, Ucx86insvpgatherqd = 1071,
      Ucx86insvpgatherqq = 1072, Ucx86insvphaddbd = 1073,
      Ucx86insvphaddbq = 1074, Ucx86insvphaddbw = 1075, Ucx86insvphadddq = 1076,
      Ucx86insvphaddd = 1077, Ucx86insvphaddsw = 1078, Ucx86insvphaddubd = 1079,
      Ucx86insvphaddubq = 1080, Ucx86insvphaddubw = 1081,
      Ucx86insvphaddudq = 1082, Ucx86insvphadduwd = 1083,
      Ucx86insvphadduwq = 1084, Ucx86insvphaddwd = 1085,
      Ucx86insvphaddwq = 1086, Ucx86insvphaddw = 1087,
      Ucx86insvphminposuw = 1088, Ucx86insvphsubbw = 1089,
      Ucx86insvphsubdq = 1090, Ucx86insvphsubd = 1091, Ucx86insvphsubsw = 1092,
      Ucx86insvphsubwd = 1093, Ucx86insvphsubw = 1094, Ucx86insvpinsrb = 1095,
      Ucx86insvpinsrd = 1096, Ucx86insvpinsrq = 1097, Ucx86insvpinsrw = 1098,
      Ucx86insvplzcntd = 1099, Ucx86insvplzcntq = 1100, Ucx86insvpmacsdd = 1101,
      Ucx86insvpmacsdqh = 1102, Ucx86insvpmacsdql = 1103,
      Ucx86insvpmacssdd = 1104, Ucx86insvpmacssdqh = 1105,
      Ucx86insvpmacssdql = 1106, Ucx86insvpmacsswd = 1107,
      Ucx86insvpmacssww = 1108, Ucx86insvpmacswd = 1109,
      Ucx86insvpmacsww = 1110, Ucx86insvpmadcsswd = 1111,
      Ucx86insvpmadcswd = 1112, Ucx86insvpmaddubsw = 1113,
      Ucx86insvpmaddwd = 1114, Ucx86insvpmaskmovd = 1115,
      Ucx86insvpmaskmovq = 1116, Ucx86insvpmaxsb = 1117, Ucx86insvpmaxsd = 1118,
      Ucx86insvpmaxsq = 1119, Ucx86insvpmaxsw = 1120, Ucx86insvpmaxub = 1121,
      Ucx86insvpmaxud = 1122, Ucx86insvpmaxuq = 1123, Ucx86insvpmaxuw = 1124,
      Ucx86insvpminsb = 1125, Ucx86insvpminsd = 1126, Ucx86insvpminsq = 1127,
      Ucx86insvpminsw = 1128, Ucx86insvpminub = 1129, Ucx86insvpminud = 1130,
      Ucx86insvpminuq = 1131, Ucx86insvpminuw = 1132, Ucx86insvpmovdb = 1133,
      Ucx86insvpmovdw = 1134, Ucx86insvpmovm2b = 1135, Ucx86insvpmovm2d = 1136,
      Ucx86insvpmovm2q = 1137, Ucx86insvpmovm2w = 1138,
      Ucx86insvpmovmskb = 1139, Ucx86insvpmovqb = 1140, Ucx86insvpmovqd = 1141,
      Ucx86insvpmovqw = 1142, Ucx86insvpmovsdb = 1143, Ucx86insvpmovsdw = 1144,
      Ucx86insvpmovsqb = 1145, Ucx86insvpmovsqd = 1146, Ucx86insvpmovsqw = 1147,
      Ucx86insvpmovsxbd = 1148, Ucx86insvpmovsxbq = 1149,
      Ucx86insvpmovsxbw = 1150, Ucx86insvpmovsxdq = 1151,
      Ucx86insvpmovsxwd = 1152, Ucx86insvpmovsxwq = 1153,
      Ucx86insvpmovusdb = 1154, Ucx86insvpmovusdw = 1155,
      Ucx86insvpmovusqb = 1156, Ucx86insvpmovusqd = 1157,
      Ucx86insvpmovusqw = 1158, Ucx86insvpmovzxbd = 1159,
      Ucx86insvpmovzxbq = 1160, Ucx86insvpmovzxbw = 1161,
      Ucx86insvpmovzxdq = 1162, Ucx86insvpmovzxwd = 1163,
      Ucx86insvpmovzxwq = 1164, Ucx86insvpmuldq = 1165,
      Ucx86insvpmulhrsw = 1166, Ucx86insvpmulhuw = 1167, Ucx86insvpmulhw = 1168,
      Ucx86insvpmulld = 1169, Ucx86insvpmullq = 1170, Ucx86insvpmullw = 1171,
      Ucx86insvpmuludq = 1172, Ucx86insvpord = 1173, Ucx86insvporq = 1174,
      Ucx86insvpor = 1175, Ucx86insvpperm = 1176, Ucx86insvprotb = 1177,
      Ucx86insvprotd = 1178, Ucx86insvprotq = 1179, Ucx86insvprotw = 1180,
      Ucx86insvpsadbw = 1181, Ucx86insvpscatterdd = 1182,
      Ucx86insvpscatterdq = 1183, Ucx86insvpscatterqd = 1184,
      Ucx86insvpscatterqq = 1185, Ucx86insvpshab = 1186, Ucx86insvpshad = 1187,
      Ucx86insvpshaq = 1188, Ucx86insvpshaw = 1189, Ucx86insvpshlb = 1190,
      Ucx86insvpshld = 1191, Ucx86insvpshlq = 1192, Ucx86insvpshlw = 1193,
      Ucx86insvpshufb = 1194, Ucx86insvpshufd = 1195, Ucx86insvpshufhw = 1196,
      Ucx86insvpshuflw = 1197, Ucx86insvpsignb = 1198, Ucx86insvpsignd = 1199,
      Ucx86insvpsignw = 1200, Ucx86insvpslldq = 1201, Ucx86insvpslld = 1202,
      Ucx86insvpsllq = 1203, Ucx86insvpsllvd = 1204, Ucx86insvpsllvq = 1205,
      Ucx86insvpsllw = 1206, Ucx86insvpsrad = 1207, Ucx86insvpsraq = 1208,
      Ucx86insvpsravd = 1209, Ucx86insvpsravq = 1210, Ucx86insvpsraw = 1211,
      Ucx86insvpsrldq = 1212, Ucx86insvpsrld = 1213, Ucx86insvpsrlq = 1214,
      Ucx86insvpsrlvd = 1215, Ucx86insvpsrlvq = 1216, Ucx86insvpsrlw = 1217,
      Ucx86insvpsubb = 1218, Ucx86insvpsubd = 1219, Ucx86insvpsubq = 1220,
      Ucx86insvpsubsb = 1221, Ucx86insvpsubsw = 1222, Ucx86insvpsubusb = 1223,
      Ucx86insvpsubusw = 1224, Ucx86insvpsubw = 1225, Ucx86insvptestmd = 1226,
      Ucx86insvptestmq = 1227, Ucx86insvptestnmd = 1228,
      Ucx86insvptestnmq = 1229, Ucx86insvptest = 1230,
      Ucx86insvpunpckhbw = 1231, Ucx86insvpunpckhdq = 1232,
      Ucx86insvpunpckhqdq = 1233, Ucx86insvpunpckhwd = 1234,
      Ucx86insvpunpcklbw = 1235, Ucx86insvpunpckldq = 1236,
      Ucx86insvpunpcklqdq = 1237, Ucx86insvpunpcklwd = 1238,
      Ucx86insvpxord = 1239, Ucx86insvpxorq = 1240, Ucx86insvpxor = 1241,
      Ucx86insvrcp14pd = 1242, Ucx86insvrcp14ps = 1243, Ucx86insvrcp14sd = 1244,
      Ucx86insvrcp14ss = 1245, Ucx86insvrcp28pd = 1246, Ucx86insvrcp28ps = 1247,
      Ucx86insvrcp28sd = 1248, Ucx86insvrcp28ss = 1249, Ucx86insvrcpps = 1250,
      Ucx86insvrcpss = 1251, Ucx86insvrndscalepd = 1252,
      Ucx86insvrndscaleps = 1253, Ucx86insvrndscalesd = 1254,
      Ucx86insvrndscaless = 1255, Ucx86insvroundpd = 1256,
      Ucx86insvroundps = 1257, Ucx86insvroundsd = 1258, Ucx86insvroundss = 1259,
      Ucx86insvrsqrt14pd = 1260, Ucx86insvrsqrt14ps = 1261,
      Ucx86insvrsqrt14sd = 1262, Ucx86insvrsqrt14ss = 1263,
      Ucx86insvrsqrt28pd = 1264, Ucx86insvrsqrt28ps = 1265,
      Ucx86insvrsqrt28sd = 1266, Ucx86insvrsqrt28ss = 1267,
      Ucx86insvrsqrtps = 1268, Ucx86insvrsqrtss = 1269,
      Ucx86insvscatterdpd = 1270, Ucx86insvscatterdps = 1271,
      Ucx86insvscatterpf0dpd = 1272, Ucx86insvscatterpf0dps = 1273,
      Ucx86insvscatterpf0qpd = 1274, Ucx86insvscatterpf0qps = 1275,
      Ucx86insvscatterpf1dpd = 1276, Ucx86insvscatterpf1dps = 1277,
      Ucx86insvscatterpf1qpd = 1278, Ucx86insvscatterpf1qps = 1279,
      Ucx86insvscatterqpd = 1280, Ucx86insvscatterqps = 1281,
      Ucx86insvshufpd = 1282, Ucx86insvshufps = 1283, Ucx86insvsqrtpd = 1284,
      Ucx86insvsqrtps = 1285, Ucx86insvsqrtsd = 1286, Ucx86insvsqrtss = 1287,
      Ucx86insvstmxcsr = 1288, Ucx86insvsubpd = 1289, Ucx86insvsubps = 1290,
      Ucx86insvsubsd = 1291, Ucx86insvsubss = 1292, Ucx86insvtestpd = 1293,
      Ucx86insvtestps = 1294, Ucx86insvunpckhpd = 1295,
      Ucx86insvunpckhps = 1296, Ucx86insvunpcklpd = 1297,
      Ucx86insvunpcklps = 1298, Ucx86insvzeroall = 1299,
      Ucx86insvzeroupper = 1300, Ucx86inswait = 1301, Ucx86inswbinvd = 1302,
      Ucx86inswrfsbase = 1303, Ucx86inswrgsbase = 1304, Ucx86inswrmsr = 1305,
      Ucx86insxabort = 1306, Ucx86insxacquire = 1307, Ucx86insxbegin = 1308,
      Ucx86insxchg = 1309, Ucx86insxcryptcbc = 1310, Ucx86insxcryptcfb = 1311,
      Ucx86insxcryptctr = 1312, Ucx86insxcryptecb = 1313,
      Ucx86insxcryptofb = 1314, Ucx86insxend = 1315, Ucx86insxgetbv = 1316,
      Ucx86insxlatb = 1317, Ucx86insxrelease = 1318, Ucx86insxrstor = 1319,
      Ucx86insxrstor64 = 1320, Ucx86insxrstors = 1321, Ucx86insxrstors64 = 1322,
      Ucx86insxsave = 1323, Ucx86insxsave64 = 1324, Ucx86insxsavec = 1325,
      Ucx86insxsavec64 = 1326, Ucx86insxsaveopt = 1327,
      Ucx86insxsaveopt64 = 1328, Ucx86insxsaves = 1329, Ucx86insxsaves64 = 1330,
      Ucx86insxsetbv = 1331, Ucx86insxsha1 = 1332, Ucx86insxsha256 = 1333,
      Ucx86insxstore = 1334, Ucx86insxtest = 1335, Ucx86insfdisi8087nop = 1336,
      Ucx86insfeni8087nop = 1337, Ucx86insending = 1338
else:
  static :
    hint("Declaration of " & "enumucx86insn" &
        " already exists, not redeclaring")
when not declared(enumuccpuarm):
  type
    enumuccpuarm* {.size: sizeof(cuint).} = enum
      Uccpuarm926 = 0, Uccpuarm946 = 1, Uccpuarm1026 = 2, Uccpuarm1136r2 = 3,
      Uccpuarm1136 = 4, Uccpuarm1176 = 5, Uccpuarm11mpcore = 6,
      Uccpuarmcortexm0 = 7, Uccpuarmcortexm3 = 8, Uccpuarmcortexm4 = 9,
      Uccpuarmcortexm7 = 10, Uccpuarmcortexm33 = 11, Uccpuarmcortexr5 = 12,
      Uccpuarmcortexr5f = 13, Uccpuarmcortexa7 = 14, Uccpuarmcortexa8 = 15,
      Uccpuarmcortexa9 = 16, Uccpuarmcortexa15 = 17, Uccpuarmti925t = 18,
      Uccpuarmsa1100 = 19, Uccpuarmsa1110 = 20, Uccpuarmpxa250 = 21,
      Uccpuarmpxa255 = 22, Uccpuarmpxa260 = 23, Uccpuarmpxa261 = 24,
      Uccpuarmpxa262 = 25, Uccpuarmpxa270 = 26, Uccpuarmpxa270a0 = 27,
      Uccpuarmpxa270a1 = 28, Uccpuarmpxa270b0 = 29, Uccpuarmpxa270b1 = 30,
      Uccpuarmpxa270c0 = 31, Uccpuarmpxa270c5 = 32, Uccpuarmmax = 33,
      Uccpuarmending = 34
else:
  static :
    hint("Declaration of " & "enumuccpuarm" & " already exists, not redeclaring")
when not declared(enumucarmreg):
  type
    enumucarmreg* {.size: sizeof(cuint).} = enum
      Ucarmreginvalid = 0, Ucarmregapsr = 1, Ucarmregapsrnzcv = 2,
      Ucarmregcpsr = 3, Ucarmregfpexc = 4, Ucarmregfpinst = 5,
      Ucarmregfpscr = 6, Ucarmregfpscrnzcv = 7, Ucarmregfpsid = 8,
      Ucarmregitstate = 9, Ucarmreglr = 10, Ucarmregpc = 11, Ucarmregsp = 12,
      Ucarmregspsr = 13, Ucarmregd0 = 14, Ucarmregd1 = 15, Ucarmregd2 = 16,
      Ucarmregd3 = 17, Ucarmregd4 = 18, Ucarmregd5 = 19, Ucarmregd6 = 20,
      Ucarmregd7 = 21, Ucarmregd8 = 22, Ucarmregd9 = 23, Ucarmregd10 = 24,
      Ucarmregd11 = 25, Ucarmregd12 = 26, Ucarmregd13 = 27, Ucarmregd14 = 28,
      Ucarmregd15 = 29, Ucarmregd16 = 30, Ucarmregd17 = 31, Ucarmregd18 = 32,
      Ucarmregd19 = 33, Ucarmregd20 = 34, Ucarmregd21 = 35, Ucarmregd22 = 36,
      Ucarmregd23 = 37, Ucarmregd24 = 38, Ucarmregd25 = 39, Ucarmregd26 = 40,
      Ucarmregd27 = 41, Ucarmregd28 = 42, Ucarmregd29 = 43, Ucarmregd30 = 44,
      Ucarmregd31 = 45, Ucarmregfpinst2 = 46, Ucarmregmvfr0 = 47,
      Ucarmregmvfr1 = 48, Ucarmregmvfr2 = 49, Ucarmregq0 = 50, Ucarmregq1 = 51,
      Ucarmregq2 = 52, Ucarmregq3 = 53, Ucarmregq4 = 54, Ucarmregq5 = 55,
      Ucarmregq6 = 56, Ucarmregq7 = 57, Ucarmregq8 = 58, Ucarmregq9 = 59,
      Ucarmregq10 = 60, Ucarmregq11 = 61, Ucarmregq12 = 62, Ucarmregq13 = 63,
      Ucarmregq14 = 64, Ucarmregq15 = 65, Ucarmregr0 = 66, Ucarmregr1 = 67,
      Ucarmregr2 = 68, Ucarmregr3 = 69, Ucarmregr4 = 70, Ucarmregr5 = 71,
      Ucarmregr6 = 72, Ucarmregr7 = 73, Ucarmregr8 = 74, Ucarmregr9 = 75,
      Ucarmregr10 = 76, Ucarmregr11 = 77, Ucarmregr12 = 78, Ucarmregs0 = 79,
      Ucarmregs1 = 80, Ucarmregs2 = 81, Ucarmregs3 = 82, Ucarmregs4 = 83,
      Ucarmregs5 = 84, Ucarmregs6 = 85, Ucarmregs7 = 86, Ucarmregs8 = 87,
      Ucarmregs9 = 88, Ucarmregs10 = 89, Ucarmregs11 = 90, Ucarmregs12 = 91,
      Ucarmregs13 = 92, Ucarmregs14 = 93, Ucarmregs15 = 94, Ucarmregs16 = 95,
      Ucarmregs17 = 96, Ucarmregs18 = 97, Ucarmregs19 = 98, Ucarmregs20 = 99,
      Ucarmregs21 = 100, Ucarmregs22 = 101, Ucarmregs23 = 102,
      Ucarmregs24 = 103, Ucarmregs25 = 104, Ucarmregs26 = 105,
      Ucarmregs27 = 106, Ucarmregs28 = 107, Ucarmregs29 = 108,
      Ucarmregs30 = 109, Ucarmregs31 = 110, Ucarmregc1c02 = 111,
      Ucarmregc13c02 = 112, Ucarmregc13c03 = 113, Ucarmregipsr = 114,
      Ucarmregmsp = 115, Ucarmregpsp = 116, Ucarmregcontrol = 117,
      Ucarmregiapsr = 118, Ucarmregeapsr = 119, Ucarmregxpsr = 120,
      Ucarmregepsr = 121, Ucarmregiepsr = 122, Ucarmregprimask = 123,
      Ucarmregbasepri = 124, Ucarmregbaseprimax = 125, Ucarmregfaultmask = 126,
      Ucarmregapsrnzcvq = 127, Ucarmregapsrg = 128, Ucarmregapsrnzcvqg = 129,
      Ucarmregiapsrnzcvq = 130, Ucarmregiapsrg = 131, Ucarmregiapsrnzcvqg = 132,
      Ucarmregeapsrnzcvq = 133, Ucarmregeapsrg = 134, Ucarmregeapsrnzcvqg = 135,
      Ucarmregxpsrnzcvq = 136, Ucarmregxpsrg = 137, Ucarmregxpsrnzcvqg = 138,
      Ucarmregcpreg = 139, Ucarmregending = 140
else:
  static :
    hint("Declaration of " & "enumucarmreg" & " already exists, not redeclaring")
when not declared(Ucarmregr13):
  const
    Ucarmregr13* = enumucarmreg.Ucarmregsp
else:
  static :
    hint("Declaration of " & "Ucarmregr13" & " already exists, not redeclaring")
when not declared(Ucarmregr14):
  const
    Ucarmregr14* = enumucarmreg.Ucarmreglr
else:
  static :
    hint("Declaration of " & "Ucarmregr14" & " already exists, not redeclaring")
when not declared(Ucarmregr15):
  const
    Ucarmregr15* = enumucarmreg.Ucarmregpc
else:
  static :
    hint("Declaration of " & "Ucarmregr15" & " already exists, not redeclaring")
when not declared(Ucarmregsb):
  const
    Ucarmregsb* = enumucarmreg.Ucarmregr9
else:
  static :
    hint("Declaration of " & "Ucarmregsb" & " already exists, not redeclaring")
when not declared(Ucarmregsl):
  const
    Ucarmregsl* = enumucarmreg.Ucarmregr10
else:
  static :
    hint("Declaration of " & "Ucarmregsl" & " already exists, not redeclaring")
when not declared(Ucarmregfp):
  const
    Ucarmregfp* = enumucarmreg.Ucarmregr11
else:
  static :
    hint("Declaration of " & "Ucarmregfp" & " already exists, not redeclaring")
when not declared(Ucarmregip):
  const
    Ucarmregip* = enumucarmreg.Ucarmregr12
else:
  static :
    hint("Declaration of " & "Ucarmregip" & " already exists, not redeclaring")
when not declared(enumuccpuarm64):
  type
    enumuccpuarm64* {.size: sizeof(cuint).} = enum
      Uccpuarm64a57 = 0, Uccpuarm64a53 = 1, Uccpuarm64a72 = 2,
      Uccpuarm64max = 3, Uccpuarm64ending = 4
else:
  static :
    hint("Declaration of " & "enumuccpuarm64" &
        " already exists, not redeclaring")
when not declared(enumucarm64reg):
  type
    enumucarm64reg* {.size: sizeof(cuint).} = enum
      Ucarm64reginvalid = 0, Ucarm64regx29 = 1, Ucarm64regx30 = 2,
      Ucarm64regnzcv = 3, Ucarm64regsp = 4, Ucarm64regwsp = 5,
      Ucarm64regwzr = 6, Ucarm64regxzr = 7, Ucarm64regb0 = 8, Ucarm64regb1 = 9,
      Ucarm64regb2 = 10, Ucarm64regb3 = 11, Ucarm64regb4 = 12,
      Ucarm64regb5 = 13, Ucarm64regb6 = 14, Ucarm64regb7 = 15,
      Ucarm64regb8 = 16, Ucarm64regb9 = 17, Ucarm64regb10 = 18,
      Ucarm64regb11 = 19, Ucarm64regb12 = 20, Ucarm64regb13 = 21,
      Ucarm64regb14 = 22, Ucarm64regb15 = 23, Ucarm64regb16 = 24,
      Ucarm64regb17 = 25, Ucarm64regb18 = 26, Ucarm64regb19 = 27,
      Ucarm64regb20 = 28, Ucarm64regb21 = 29, Ucarm64regb22 = 30,
      Ucarm64regb23 = 31, Ucarm64regb24 = 32, Ucarm64regb25 = 33,
      Ucarm64regb26 = 34, Ucarm64regb27 = 35, Ucarm64regb28 = 36,
      Ucarm64regb29 = 37, Ucarm64regb30 = 38, Ucarm64regb31 = 39,
      Ucarm64regd0 = 40, Ucarm64regd1 = 41, Ucarm64regd2 = 42,
      Ucarm64regd3 = 43, Ucarm64regd4 = 44, Ucarm64regd5 = 45,
      Ucarm64regd6 = 46, Ucarm64regd7 = 47, Ucarm64regd8 = 48,
      Ucarm64regd9 = 49, Ucarm64regd10 = 50, Ucarm64regd11 = 51,
      Ucarm64regd12 = 52, Ucarm64regd13 = 53, Ucarm64regd14 = 54,
      Ucarm64regd15 = 55, Ucarm64regd16 = 56, Ucarm64regd17 = 57,
      Ucarm64regd18 = 58, Ucarm64regd19 = 59, Ucarm64regd20 = 60,
      Ucarm64regd21 = 61, Ucarm64regd22 = 62, Ucarm64regd23 = 63,
      Ucarm64regd24 = 64, Ucarm64regd25 = 65, Ucarm64regd26 = 66,
      Ucarm64regd27 = 67, Ucarm64regd28 = 68, Ucarm64regd29 = 69,
      Ucarm64regd30 = 70, Ucarm64regd31 = 71, Ucarm64regh0 = 72,
      Ucarm64regh1 = 73, Ucarm64regh2 = 74, Ucarm64regh3 = 75,
      Ucarm64regh4 = 76, Ucarm64regh5 = 77, Ucarm64regh6 = 78,
      Ucarm64regh7 = 79, Ucarm64regh8 = 80, Ucarm64regh9 = 81,
      Ucarm64regh10 = 82, Ucarm64regh11 = 83, Ucarm64regh12 = 84,
      Ucarm64regh13 = 85, Ucarm64regh14 = 86, Ucarm64regh15 = 87,
      Ucarm64regh16 = 88, Ucarm64regh17 = 89, Ucarm64regh18 = 90,
      Ucarm64regh19 = 91, Ucarm64regh20 = 92, Ucarm64regh21 = 93,
      Ucarm64regh22 = 94, Ucarm64regh23 = 95, Ucarm64regh24 = 96,
      Ucarm64regh25 = 97, Ucarm64regh26 = 98, Ucarm64regh27 = 99,
      Ucarm64regh28 = 100, Ucarm64regh29 = 101, Ucarm64regh30 = 102,
      Ucarm64regh31 = 103, Ucarm64regq0 = 104, Ucarm64regq1 = 105,
      Ucarm64regq2 = 106, Ucarm64regq3 = 107, Ucarm64regq4 = 108,
      Ucarm64regq5 = 109, Ucarm64regq6 = 110, Ucarm64regq7 = 111,
      Ucarm64regq8 = 112, Ucarm64regq9 = 113, Ucarm64regq10 = 114,
      Ucarm64regq11 = 115, Ucarm64regq12 = 116, Ucarm64regq13 = 117,
      Ucarm64regq14 = 118, Ucarm64regq15 = 119, Ucarm64regq16 = 120,
      Ucarm64regq17 = 121, Ucarm64regq18 = 122, Ucarm64regq19 = 123,
      Ucarm64regq20 = 124, Ucarm64regq21 = 125, Ucarm64regq22 = 126,
      Ucarm64regq23 = 127, Ucarm64regq24 = 128, Ucarm64regq25 = 129,
      Ucarm64regq26 = 130, Ucarm64regq27 = 131, Ucarm64regq28 = 132,
      Ucarm64regq29 = 133, Ucarm64regq30 = 134, Ucarm64regq31 = 135,
      Ucarm64regs0 = 136, Ucarm64regs1 = 137, Ucarm64regs2 = 138,
      Ucarm64regs3 = 139, Ucarm64regs4 = 140, Ucarm64regs5 = 141,
      Ucarm64regs6 = 142, Ucarm64regs7 = 143, Ucarm64regs8 = 144,
      Ucarm64regs9 = 145, Ucarm64regs10 = 146, Ucarm64regs11 = 147,
      Ucarm64regs12 = 148, Ucarm64regs13 = 149, Ucarm64regs14 = 150,
      Ucarm64regs15 = 151, Ucarm64regs16 = 152, Ucarm64regs17 = 153,
      Ucarm64regs18 = 154, Ucarm64regs19 = 155, Ucarm64regs20 = 156,
      Ucarm64regs21 = 157, Ucarm64regs22 = 158, Ucarm64regs23 = 159,
      Ucarm64regs24 = 160, Ucarm64regs25 = 161, Ucarm64regs26 = 162,
      Ucarm64regs27 = 163, Ucarm64regs28 = 164, Ucarm64regs29 = 165,
      Ucarm64regs30 = 166, Ucarm64regs31 = 167, Ucarm64regw0 = 168,
      Ucarm64regw1 = 169, Ucarm64regw2 = 170, Ucarm64regw3 = 171,
      Ucarm64regw4 = 172, Ucarm64regw5 = 173, Ucarm64regw6 = 174,
      Ucarm64regw7 = 175, Ucarm64regw8 = 176, Ucarm64regw9 = 177,
      Ucarm64regw10 = 178, Ucarm64regw11 = 179, Ucarm64regw12 = 180,
      Ucarm64regw13 = 181, Ucarm64regw14 = 182, Ucarm64regw15 = 183,
      Ucarm64regw16 = 184, Ucarm64regw17 = 185, Ucarm64regw18 = 186,
      Ucarm64regw19 = 187, Ucarm64regw20 = 188, Ucarm64regw21 = 189,
      Ucarm64regw22 = 190, Ucarm64regw23 = 191, Ucarm64regw24 = 192,
      Ucarm64regw25 = 193, Ucarm64regw26 = 194, Ucarm64regw27 = 195,
      Ucarm64regw28 = 196, Ucarm64regw29 = 197, Ucarm64regw30 = 198,
      Ucarm64regx0 = 199, Ucarm64regx1 = 200, Ucarm64regx2 = 201,
      Ucarm64regx3 = 202, Ucarm64regx4 = 203, Ucarm64regx5 = 204,
      Ucarm64regx6 = 205, Ucarm64regx7 = 206, Ucarm64regx8 = 207,
      Ucarm64regx9 = 208, Ucarm64regx10 = 209, Ucarm64regx11 = 210,
      Ucarm64regx12 = 211, Ucarm64regx13 = 212, Ucarm64regx14 = 213,
      Ucarm64regx15 = 214, Ucarm64regx16 = 215, Ucarm64regx17 = 216,
      Ucarm64regx18 = 217, Ucarm64regx19 = 218, Ucarm64regx20 = 219,
      Ucarm64regx21 = 220, Ucarm64regx22 = 221, Ucarm64regx23 = 222,
      Ucarm64regx24 = 223, Ucarm64regx25 = 224, Ucarm64regx26 = 225,
      Ucarm64regx27 = 226, Ucarm64regx28 = 227, Ucarm64regv0 = 228,
      Ucarm64regv1 = 229, Ucarm64regv2 = 230, Ucarm64regv3 = 231,
      Ucarm64regv4 = 232, Ucarm64regv5 = 233, Ucarm64regv6 = 234,
      Ucarm64regv7 = 235, Ucarm64regv8 = 236, Ucarm64regv9 = 237,
      Ucarm64regv10 = 238, Ucarm64regv11 = 239, Ucarm64regv12 = 240,
      Ucarm64regv13 = 241, Ucarm64regv14 = 242, Ucarm64regv15 = 243,
      Ucarm64regv16 = 244, Ucarm64regv17 = 245, Ucarm64regv18 = 246,
      Ucarm64regv19 = 247, Ucarm64regv20 = 248, Ucarm64regv21 = 249,
      Ucarm64regv22 = 250, Ucarm64regv23 = 251, Ucarm64regv24 = 252,
      Ucarm64regv25 = 253, Ucarm64regv26 = 254, Ucarm64regv27 = 255,
      Ucarm64regv28 = 256, Ucarm64regv29 = 257, Ucarm64regv30 = 258,
      Ucarm64regv31 = 259, Ucarm64regpc = 260, Ucarm64regcpacrel1 = 261,
      Ucarm64regtpidrel0 = 262, Ucarm64regtpidrroel0 = 263,
      Ucarm64regtpidrel1 = 264, Ucarm64regpstate = 265, Ucarm64regelrel0 = 266,
      Ucarm64regelrel1 = 267, Ucarm64regelrel2 = 268, Ucarm64regelrel3 = 269,
      Ucarm64regspel0 = 270, Ucarm64regspel1 = 271, Ucarm64regspel2 = 272,
      Ucarm64regspel3 = 273, Ucarm64regttbr0el1 = 274, Ucarm64regttbr1el1 = 275,
      Ucarm64regesrel0 = 276, Ucarm64regesrel1 = 277, Ucarm64regesrel2 = 278,
      Ucarm64regesrel3 = 279, Ucarm64regfarel0 = 280, Ucarm64regfarel1 = 281,
      Ucarm64regfarel2 = 282, Ucarm64regfarel3 = 283, Ucarm64regparel1 = 284,
      Ucarm64regmairel1 = 285, Ucarm64regvbarel0 = 286, Ucarm64regvbarel1 = 287,
      Ucarm64regvbarel2 = 288, Ucarm64regvbarel3 = 289, Ucarm64regcpreg = 290,
      Ucarm64regfpcr = 291, Ucarm64regfpsr = 292, Ucarm64regending = 293
else:
  static :
    hint("Declaration of " & "enumucarm64reg" &
        " already exists, not redeclaring")
when not declared(Ucarm64regip0):
  const
    Ucarm64regip0* = enumucarm64reg.Ucarm64regx16
else:
  static :
    hint("Declaration of " & "Ucarm64regip0" &
        " already exists, not redeclaring")
when not declared(Ucarm64regip1):
  const
    Ucarm64regip1* = enumucarm64reg.Ucarm64regx17
else:
  static :
    hint("Declaration of " & "Ucarm64regip1" &
        " already exists, not redeclaring")
when not declared(Ucarm64regfp):
  const
    Ucarm64regfp* = enumucarm64reg.Ucarm64regx29
else:
  static :
    hint("Declaration of " & "Ucarm64regfp" & " already exists, not redeclaring")
when not declared(Ucarm64reglr):
  const
    Ucarm64reglr* = enumucarm64reg.Ucarm64regx30
else:
  static :
    hint("Declaration of " & "Ucarm64reglr" & " already exists, not redeclaring")
when not declared(enumucarm64insn):
  type
    enumucarm64insn* {.size: sizeof(cuint).} = enum
      Ucarm64insinvalid = 0, Ucarm64insmrs = 1, Ucarm64insmsr = 2,
      Ucarm64inssys = 3, Ucarm64inssysl = 4, Ucarm64insending = 5
else:
  static :
    hint("Declaration of " & "enumucarm64insn" &
        " already exists, not redeclaring")
when not declared(enumuccpumips32):
  type
    enumuccpumips32* {.size: sizeof(cuint).} = enum
      Uccpumips324kc = 0, Uccpumips324km = 1, Uccpumips324kecr1 = 2,
      Uccpumips324kemr1 = 3, Uccpumips324kec = 4, Uccpumips324kem = 5,
      Uccpumips3224kc = 6, Uccpumips3224kec = 7, Uccpumips3224kf = 8,
      Uccpumips3234kf = 9, Uccpumips3274kf = 10, Uccpumips32m14k = 11,
      Uccpumips32m14kc = 12, Uccpumips32p5600 = 13,
      Uccpumips32mips32r6generic = 14, Uccpumips32i7200 = 15,
      Uccpumips32ending = 16
else:
  static :
    hint("Declaration of " & "enumuccpumips32" &
        " already exists, not redeclaring")
when not declared(enumuccpumips64):
  type
    enumuccpumips64* {.size: sizeof(cuint).} = enum
      Uccpumips64r4000 = 0, Uccpumips64vr5432 = 1, Uccpumips645kc = 2,
      Uccpumips645kf = 3, Uccpumips6420kc = 4, Uccpumips64mips64r2generic = 5,
      Uccpumips645kec = 6, Uccpumips645kef = 7, Uccpumips64i6400 = 8,
      Uccpumips64i6500 = 9, Uccpumips64loongson2e = 10,
      Uccpumips64loongson2f = 11, Uccpumips64mips64dspr2 = 12,
      Uccpumips64ending = 13
else:
  static :
    hint("Declaration of " & "enumuccpumips64" &
        " already exists, not redeclaring")
when not declared(enumucmipsreg):
  type
    enumucmipsreg* {.size: sizeof(cuint).} = enum
      Ucmipsreginvalid = 0, Ucmipsregpc = 1, Ucmipsreg0 = 2, Ucmipsreg1 = 3,
      Ucmipsreg2 = 4, Ucmipsreg3 = 5, Ucmipsreg4 = 6, Ucmipsreg5 = 7,
      Ucmipsreg6 = 8, Ucmipsreg7 = 9, Ucmipsreg8 = 10, Ucmipsreg9 = 11,
      Ucmipsreg10 = 12, Ucmipsreg11 = 13, Ucmipsreg12 = 14, Ucmipsreg13 = 15,
      Ucmipsreg14 = 16, Ucmipsreg15 = 17, Ucmipsreg16 = 18, Ucmipsreg17 = 19,
      Ucmipsreg18 = 20, Ucmipsreg19 = 21, Ucmipsreg20 = 22, Ucmipsreg21 = 23,
      Ucmipsreg22 = 24, Ucmipsreg23 = 25, Ucmipsreg24 = 26, Ucmipsreg25 = 27,
      Ucmipsreg26 = 28, Ucmipsreg27 = 29, Ucmipsreg28 = 30, Ucmipsreg29 = 31,
      Ucmipsreg30 = 32, Ucmipsreg31 = 33, Ucmipsregdspccond = 34,
      Ucmipsregdspcarry = 35, Ucmipsregdspefi = 36, Ucmipsregdspoutflag = 37,
      Ucmipsregdspoutflag1619 = 38, Ucmipsregdspoutflag20 = 39,
      Ucmipsregdspoutflag21 = 40, Ucmipsregdspoutflag22 = 41,
      Ucmipsregdspoutflag23 = 42, Ucmipsregdsppos = 43, Ucmipsregdspscount = 44,
      Ucmipsregac0 = 45, Ucmipsregac1 = 46, Ucmipsregac2 = 47,
      Ucmipsregac3 = 48, Ucmipsregcc0 = 49, Ucmipsregcc1 = 50,
      Ucmipsregcc2 = 51, Ucmipsregcc3 = 52, Ucmipsregcc4 = 53,
      Ucmipsregcc5 = 54, Ucmipsregcc6 = 55, Ucmipsregcc7 = 56, Ucmipsregf0 = 57,
      Ucmipsregf1 = 58, Ucmipsregf2 = 59, Ucmipsregf3 = 60, Ucmipsregf4 = 61,
      Ucmipsregf5 = 62, Ucmipsregf6 = 63, Ucmipsregf7 = 64, Ucmipsregf8 = 65,
      Ucmipsregf9 = 66, Ucmipsregf10 = 67, Ucmipsregf11 = 68, Ucmipsregf12 = 69,
      Ucmipsregf13 = 70, Ucmipsregf14 = 71, Ucmipsregf15 = 72,
      Ucmipsregf16 = 73, Ucmipsregf17 = 74, Ucmipsregf18 = 75,
      Ucmipsregf19 = 76, Ucmipsregf20 = 77, Ucmipsregf21 = 78,
      Ucmipsregf22 = 79, Ucmipsregf23 = 80, Ucmipsregf24 = 81,
      Ucmipsregf25 = 82, Ucmipsregf26 = 83, Ucmipsregf27 = 84,
      Ucmipsregf28 = 85, Ucmipsregf29 = 86, Ucmipsregf30 = 87,
      Ucmipsregf31 = 88, Ucmipsregfcc0 = 89, Ucmipsregfcc1 = 90,
      Ucmipsregfcc2 = 91, Ucmipsregfcc3 = 92, Ucmipsregfcc4 = 93,
      Ucmipsregfcc5 = 94, Ucmipsregfcc6 = 95, Ucmipsregfcc7 = 96,
      Ucmipsregw0 = 97, Ucmipsregw1 = 98, Ucmipsregw2 = 99, Ucmipsregw3 = 100,
      Ucmipsregw4 = 101, Ucmipsregw5 = 102, Ucmipsregw6 = 103,
      Ucmipsregw7 = 104, Ucmipsregw8 = 105, Ucmipsregw9 = 106,
      Ucmipsregw10 = 107, Ucmipsregw11 = 108, Ucmipsregw12 = 109,
      Ucmipsregw13 = 110, Ucmipsregw14 = 111, Ucmipsregw15 = 112,
      Ucmipsregw16 = 113, Ucmipsregw17 = 114, Ucmipsregw18 = 115,
      Ucmipsregw19 = 116, Ucmipsregw20 = 117, Ucmipsregw21 = 118,
      Ucmipsregw22 = 119, Ucmipsregw23 = 120, Ucmipsregw24 = 121,
      Ucmipsregw25 = 122, Ucmipsregw26 = 123, Ucmipsregw27 = 124,
      Ucmipsregw28 = 125, Ucmipsregw29 = 126, Ucmipsregw30 = 127,
      Ucmipsregw31 = 128, Ucmipsreghi = 129, Ucmipsreglo = 130,
      Ucmipsregp0 = 131, Ucmipsregp1 = 132, Ucmipsregp2 = 133,
      Ucmipsregmpl0 = 134, Ucmipsregmpl1 = 135, Ucmipsregmpl2 = 136,
      Ucmipsregcp0config3 = 137, Ucmipsregcp0userlocal = 138,
      Ucmipsregcp0status = 139, Ucmipsregending = 140
else:
  static :
    hint("Declaration of " & "enumucmipsreg" &
        " already exists, not redeclaring")
when not declared(Ucmipsregzero):
  const
    Ucmipsregzero* = enumucmipsreg.Ucmipsreg0
else:
  static :
    hint("Declaration of " & "Ucmipsregzero" &
        " already exists, not redeclaring")
when not declared(Ucmipsregat):
  const
    Ucmipsregat* = enumucmipsreg.Ucmipsreg1
else:
  static :
    hint("Declaration of " & "Ucmipsregat" & " already exists, not redeclaring")
when not declared(Ucmipsregv0):
  const
    Ucmipsregv0* = enumucmipsreg.Ucmipsreg2
else:
  static :
    hint("Declaration of " & "Ucmipsregv0" & " already exists, not redeclaring")
when not declared(Ucmipsregv1):
  const
    Ucmipsregv1* = enumucmipsreg.Ucmipsreg3
else:
  static :
    hint("Declaration of " & "Ucmipsregv1" & " already exists, not redeclaring")
when not declared(Ucmipsrega0):
  const
    Ucmipsrega0* = enumucmipsreg.Ucmipsreg4
else:
  static :
    hint("Declaration of " & "Ucmipsrega0" & " already exists, not redeclaring")
when not declared(Ucmipsrega1):
  const
    Ucmipsrega1* = enumucmipsreg.Ucmipsreg5
else:
  static :
    hint("Declaration of " & "Ucmipsrega1" & " already exists, not redeclaring")
when not declared(Ucmipsrega2):
  const
    Ucmipsrega2* = enumucmipsreg.Ucmipsreg6
else:
  static :
    hint("Declaration of " & "Ucmipsrega2" & " already exists, not redeclaring")
when not declared(Ucmipsrega3):
  const
    Ucmipsrega3* = enumucmipsreg.Ucmipsreg7
else:
  static :
    hint("Declaration of " & "Ucmipsrega3" & " already exists, not redeclaring")
when not declared(Ucmipsregt0):
  const
    Ucmipsregt0* = enumucmipsreg.Ucmipsreg8
else:
  static :
    hint("Declaration of " & "Ucmipsregt0" & " already exists, not redeclaring")
when not declared(Ucmipsregt1):
  const
    Ucmipsregt1* = enumucmipsreg.Ucmipsreg9
else:
  static :
    hint("Declaration of " & "Ucmipsregt1" & " already exists, not redeclaring")
when not declared(Ucmipsregt2):
  const
    Ucmipsregt2* = enumucmipsreg.Ucmipsreg10
else:
  static :
    hint("Declaration of " & "Ucmipsregt2" & " already exists, not redeclaring")
when not declared(Ucmipsregt3):
  const
    Ucmipsregt3* = enumucmipsreg.Ucmipsreg11
else:
  static :
    hint("Declaration of " & "Ucmipsregt3" & " already exists, not redeclaring")
when not declared(Ucmipsregt4):
  const
    Ucmipsregt4* = enumucmipsreg.Ucmipsreg12
else:
  static :
    hint("Declaration of " & "Ucmipsregt4" & " already exists, not redeclaring")
when not declared(Ucmipsregt5):
  const
    Ucmipsregt5* = enumucmipsreg.Ucmipsreg13
else:
  static :
    hint("Declaration of " & "Ucmipsregt5" & " already exists, not redeclaring")
when not declared(Ucmipsregt6):
  const
    Ucmipsregt6* = enumucmipsreg.Ucmipsreg14
else:
  static :
    hint("Declaration of " & "Ucmipsregt6" & " already exists, not redeclaring")
when not declared(Ucmipsregt7):
  const
    Ucmipsregt7* = enumucmipsreg.Ucmipsreg15
else:
  static :
    hint("Declaration of " & "Ucmipsregt7" & " already exists, not redeclaring")
when not declared(Ucmipsregs0):
  const
    Ucmipsregs0* = enumucmipsreg.Ucmipsreg16
else:
  static :
    hint("Declaration of " & "Ucmipsregs0" & " already exists, not redeclaring")
when not declared(Ucmipsregs1):
  const
    Ucmipsregs1* = enumucmipsreg.Ucmipsreg17
else:
  static :
    hint("Declaration of " & "Ucmipsregs1" & " already exists, not redeclaring")
when not declared(Ucmipsregs2):
  const
    Ucmipsregs2* = enumucmipsreg.Ucmipsreg18
else:
  static :
    hint("Declaration of " & "Ucmipsregs2" & " already exists, not redeclaring")
when not declared(Ucmipsregs3):
  const
    Ucmipsregs3* = enumucmipsreg.Ucmipsreg19
else:
  static :
    hint("Declaration of " & "Ucmipsregs3" & " already exists, not redeclaring")
when not declared(Ucmipsregs4):
  const
    Ucmipsregs4* = enumucmipsreg.Ucmipsreg20
else:
  static :
    hint("Declaration of " & "Ucmipsregs4" & " already exists, not redeclaring")
when not declared(Ucmipsregs5):
  const
    Ucmipsregs5* = enumucmipsreg.Ucmipsreg21
else:
  static :
    hint("Declaration of " & "Ucmipsregs5" & " already exists, not redeclaring")
when not declared(Ucmipsregs6):
  const
    Ucmipsregs6* = enumucmipsreg.Ucmipsreg22
else:
  static :
    hint("Declaration of " & "Ucmipsregs6" & " already exists, not redeclaring")
when not declared(Ucmipsregs7):
  const
    Ucmipsregs7* = enumucmipsreg.Ucmipsreg23
else:
  static :
    hint("Declaration of " & "Ucmipsregs7" & " already exists, not redeclaring")
when not declared(Ucmipsregt8):
  const
    Ucmipsregt8* = enumucmipsreg.Ucmipsreg24
else:
  static :
    hint("Declaration of " & "Ucmipsregt8" & " already exists, not redeclaring")
when not declared(Ucmipsregt9):
  const
    Ucmipsregt9* = enumucmipsreg.Ucmipsreg25
else:
  static :
    hint("Declaration of " & "Ucmipsregt9" & " already exists, not redeclaring")
when not declared(Ucmipsregk0):
  const
    Ucmipsregk0* = enumucmipsreg.Ucmipsreg26
else:
  static :
    hint("Declaration of " & "Ucmipsregk0" & " already exists, not redeclaring")
when not declared(Ucmipsregk1):
  const
    Ucmipsregk1* = enumucmipsreg.Ucmipsreg27
else:
  static :
    hint("Declaration of " & "Ucmipsregk1" & " already exists, not redeclaring")
when not declared(Ucmipsreggp):
  const
    Ucmipsreggp* = enumucmipsreg.Ucmipsreg28
else:
  static :
    hint("Declaration of " & "Ucmipsreggp" & " already exists, not redeclaring")
when not declared(Ucmipsregsp):
  const
    Ucmipsregsp* = enumucmipsreg.Ucmipsreg29
else:
  static :
    hint("Declaration of " & "Ucmipsregsp" & " already exists, not redeclaring")
when not declared(Ucmipsregfp):
  const
    Ucmipsregfp* = enumucmipsreg.Ucmipsreg30
else:
  static :
    hint("Declaration of " & "Ucmipsregfp" & " already exists, not redeclaring")
when not declared(Ucmipsregs8):
  const
    Ucmipsregs8* = enumucmipsreg.Ucmipsreg30
else:
  static :
    hint("Declaration of " & "Ucmipsregs8" & " already exists, not redeclaring")
when not declared(Ucmipsregra):
  const
    Ucmipsregra* = enumucmipsreg.Ucmipsreg31
else:
  static :
    hint("Declaration of " & "Ucmipsregra" & " already exists, not redeclaring")
when not declared(Ucmipsreghi0):
  const
    Ucmipsreghi0* = enumucmipsreg.Ucmipsregac0
else:
  static :
    hint("Declaration of " & "Ucmipsreghi0" & " already exists, not redeclaring")
when not declared(Ucmipsreghi1):
  const
    Ucmipsreghi1* = enumucmipsreg.Ucmipsregac1
else:
  static :
    hint("Declaration of " & "Ucmipsreghi1" & " already exists, not redeclaring")
when not declared(Ucmipsreghi2):
  const
    Ucmipsreghi2* = enumucmipsreg.Ucmipsregac2
else:
  static :
    hint("Declaration of " & "Ucmipsreghi2" & " already exists, not redeclaring")
when not declared(Ucmipsreghi3):
  const
    Ucmipsreghi3* = enumucmipsreg.Ucmipsregac3
else:
  static :
    hint("Declaration of " & "Ucmipsreghi3" & " already exists, not redeclaring")
when not declared(Ucmipsreglo0):
  const
    Ucmipsreglo0* = enumucmipsreg.Ucmipsregac0
else:
  static :
    hint("Declaration of " & "Ucmipsreglo0" & " already exists, not redeclaring")
when not declared(Ucmipsreglo1):
  const
    Ucmipsreglo1* = enumucmipsreg.Ucmipsregac1
else:
  static :
    hint("Declaration of " & "Ucmipsreglo1" & " already exists, not redeclaring")
when not declared(Ucmipsreglo2):
  const
    Ucmipsreglo2* = enumucmipsreg.Ucmipsregac2
else:
  static :
    hint("Declaration of " & "Ucmipsreglo2" & " already exists, not redeclaring")
when not declared(Ucmipsreglo3):
  const
    Ucmipsreglo3* = enumucmipsreg.Ucmipsregac3
else:
  static :
    hint("Declaration of " & "Ucmipsreglo3" & " already exists, not redeclaring")
when not declared(enumuccpusparc32):
  type
    enumuccpusparc32* {.size: sizeof(cuint).} = enum
      Uccpusparc32fujitsumb86904 = 0, Uccpusparc32fujitsumb86907 = 1,
      Uccpusparc32timicrosparci = 2, Uccpusparc32timicrosparcii = 3,
      Uccpusparc32timicrosparciiep = 4, Uccpusparc32tisupersparc40 = 5,
      Uccpusparc32tisupersparc50 = 6, Uccpusparc32tisupersparc51 = 7,
      Uccpusparc32tisupersparc60 = 8, Uccpusparc32tisupersparc61 = 9,
      Uccpusparc32tisupersparcii = 10, Uccpusparc32leon2 = 11,
      Uccpusparc32leon3 = 12, Uccpusparc32ending = 13
else:
  static :
    hint("Declaration of " & "enumuccpusparc32" &
        " already exists, not redeclaring")
when not declared(enumuccpusparc64):
  type
    enumuccpusparc64* {.size: sizeof(cuint).} = enum
      Uccpusparc64fujitsu = 0, Uccpusparc64fujitsuiii = 1,
      Uccpusparc64fujitsuiv = 2, Uccpusparc64fujitsuv = 3,
      Uccpusparc64tiultrasparci = 4, Uccpusparc64tiultrasparcii = 5,
      Uccpusparc64tiultrasparciii = 6, Uccpusparc64tiultrasparciie = 7,
      Uccpusparc64sunultrasparciii = 8, Uccpusparc64sunultrasparciiicu = 9,
      Uccpusparc64sunultrasparciiii = 10, Uccpusparc64sunultrasparciv = 11,
      Uccpusparc64sunultrasparcivplus = 12,
      Uccpusparc64sunultrasparciiiiplus = 13, Uccpusparc64sunultrasparct1 = 14,
      Uccpusparc64sunultrasparct2 = 15, Uccpusparc64necultrasparci = 16,
      Uccpusparc64ending = 17
else:
  static :
    hint("Declaration of " & "enumuccpusparc64" &
        " already exists, not redeclaring")
when not declared(enumucsparcreg):
  type
    enumucsparcreg* {.size: sizeof(cuint).} = enum
      Ucsparcreginvalid = 0, Ucsparcregf0 = 1, Ucsparcregf1 = 2,
      Ucsparcregf2 = 3, Ucsparcregf3 = 4, Ucsparcregf4 = 5, Ucsparcregf5 = 6,
      Ucsparcregf6 = 7, Ucsparcregf7 = 8, Ucsparcregf8 = 9, Ucsparcregf9 = 10,
      Ucsparcregf10 = 11, Ucsparcregf11 = 12, Ucsparcregf12 = 13,
      Ucsparcregf13 = 14, Ucsparcregf14 = 15, Ucsparcregf15 = 16,
      Ucsparcregf16 = 17, Ucsparcregf17 = 18, Ucsparcregf18 = 19,
      Ucsparcregf19 = 20, Ucsparcregf20 = 21, Ucsparcregf21 = 22,
      Ucsparcregf22 = 23, Ucsparcregf23 = 24, Ucsparcregf24 = 25,
      Ucsparcregf25 = 26, Ucsparcregf26 = 27, Ucsparcregf27 = 28,
      Ucsparcregf28 = 29, Ucsparcregf29 = 30, Ucsparcregf30 = 31,
      Ucsparcregf31 = 32, Ucsparcregf32 = 33, Ucsparcregf34 = 34,
      Ucsparcregf36 = 35, Ucsparcregf38 = 36, Ucsparcregf40 = 37,
      Ucsparcregf42 = 38, Ucsparcregf44 = 39, Ucsparcregf46 = 40,
      Ucsparcregf48 = 41, Ucsparcregf50 = 42, Ucsparcregf52 = 43,
      Ucsparcregf54 = 44, Ucsparcregf56 = 45, Ucsparcregf58 = 46,
      Ucsparcregf60 = 47, Ucsparcregf62 = 48, Ucsparcregfcc0 = 49,
      Ucsparcregfcc1 = 50, Ucsparcregfcc2 = 51, Ucsparcregfcc3 = 52,
      Ucsparcregg0 = 53, Ucsparcregg1 = 54, Ucsparcregg2 = 55,
      Ucsparcregg3 = 56, Ucsparcregg4 = 57, Ucsparcregg5 = 58,
      Ucsparcregg6 = 59, Ucsparcregg7 = 60, Ucsparcregi0 = 61,
      Ucsparcregi1 = 62, Ucsparcregi2 = 63, Ucsparcregi3 = 64,
      Ucsparcregi4 = 65, Ucsparcregi5 = 66, Ucsparcregfp = 67,
      Ucsparcregi7 = 68, Ucsparcregicc = 69, Ucsparcregl0 = 70,
      Ucsparcregl1 = 71, Ucsparcregl2 = 72, Ucsparcregl3 = 73,
      Ucsparcregl4 = 74, Ucsparcregl5 = 75, Ucsparcregl6 = 76,
      Ucsparcregl7 = 77, Ucsparcrego0 = 78, Ucsparcrego1 = 79,
      Ucsparcrego2 = 80, Ucsparcrego3 = 81, Ucsparcrego4 = 82,
      Ucsparcrego5 = 83, Ucsparcregsp = 84, Ucsparcrego7 = 85, Ucsparcregy = 86,
      Ucsparcregxcc = 87, Ucsparcregpc = 88, Ucsparcregending = 89
else:
  static :
    hint("Declaration of " & "enumucsparcreg" &
        " already exists, not redeclaring")
when not declared(Ucsparcrego6):
  const
    Ucsparcrego6* = enumucsparcreg.Ucsparcregsp
else:
  static :
    hint("Declaration of " & "Ucsparcrego6" & " already exists, not redeclaring")
when not declared(Ucsparcregi6):
  const
    Ucsparcregi6* = enumucsparcreg.Ucsparcregfp
else:
  static :
    hint("Declaration of " & "Ucsparcregi6" & " already exists, not redeclaring")
when not declared(enumuccpuppc):
  type
    enumuccpuppc* {.size: sizeof(cuint).} = enum
      Uccpuppc32401 = 0, Uccpuppc32401a1 = 1, Uccpuppc32401b2 = 2,
      Uccpuppc32401c2 = 3, Uccpuppc32401d2 = 4, Uccpuppc32401e2 = 5,
      Uccpuppc32401f2 = 6, Uccpuppc32401g2 = 7, Uccpuppc32iop480 = 8,
      Uccpuppc32cobra = 9, Uccpuppc32403ga = 10, Uccpuppc32403gb = 11,
      Uccpuppc32403gc = 12, Uccpuppc32403gcx = 13, Uccpuppc32405d2 = 14,
      Uccpuppc32405d4 = 15, Uccpuppc32405cra = 16, Uccpuppc32405crb = 17,
      Uccpuppc32405crc = 18, Uccpuppc32405ep = 19, Uccpuppc32405ez = 20,
      Uccpuppc32405gpa = 21, Uccpuppc32405gpb = 22, Uccpuppc32405gpc = 23,
      Uccpuppc32405gpd = 24, Uccpuppc32405gpr = 25, Uccpuppc32405lp = 26,
      Uccpuppc32npe405h = 27, Uccpuppc32npe405h2 = 28, Uccpuppc32npe405l = 29,
      Uccpuppc32npe4gs3 = 30, Uccpuppc32stb03 = 31, Uccpuppc32stb04 = 32,
      Uccpuppc32stb25 = 33, Uccpuppc32x2vp4 = 34, Uccpuppc32x2vp20 = 35,
      Uccpuppc32440xilinx = 36, Uccpuppc32440xilinxwdfpu = 37,
      Uccpuppc32440epa = 38, Uccpuppc32440epb = 39, Uccpuppc32440epx = 40,
      Uccpuppc32460exb = 41, Uccpuppc32g2 = 42, Uccpuppc32g2h4 = 43,
      Uccpuppc32g2gp = 44, Uccpuppc32g2ls = 45, Uccpuppc32g2hip3 = 46,
      Uccpuppc32g2hip4 = 47, Uccpuppc32mpc603 = 48, Uccpuppc32g2le = 49,
      Uccpuppc32g2legp = 50, Uccpuppc32g2lels = 51, Uccpuppc32g2legp1 = 52,
      Uccpuppc32g2legp3 = 53, Uccpuppc32mpc5200v10 = 54,
      Uccpuppc32mpc5200v11 = 55, Uccpuppc32mpc5200v12 = 56,
      Uccpuppc32mpc5200bv20 = 57, Uccpuppc32mpc5200bv21 = 58,
      Uccpuppc32e200z5 = 59, Uccpuppc32e200z6 = 60, Uccpuppc32e300c1 = 61,
      Uccpuppc32e300c2 = 62, Uccpuppc32e300c3 = 63, Uccpuppc32e300c4 = 64,
      Uccpuppc32mpc8343 = 65, Uccpuppc32mpc8343a = 66, Uccpuppc32mpc8343e = 67,
      Uccpuppc32mpc8343ea = 68, Uccpuppc32mpc8347t = 69,
      Uccpuppc32mpc8347p = 70, Uccpuppc32mpc8347at = 71,
      Uccpuppc32mpc8347ap = 72, Uccpuppc32mpc8347et = 73,
      Uccpuppc32mpc8347ep = 74, Uccpuppc32mpc8347eat = 75,
      Uccpuppc32mpc8347eap = 76, Uccpuppc32mpc8349 = 77,
      Uccpuppc32mpc8349a = 78, Uccpuppc32mpc8349e = 79,
      Uccpuppc32mpc8349ea = 80, Uccpuppc32mpc8377 = 81, Uccpuppc32mpc8377e = 82,
      Uccpuppc32mpc8378 = 83, Uccpuppc32mpc8378e = 84, Uccpuppc32mpc8379 = 85,
      Uccpuppc32mpc8379e = 86, Uccpuppc32e500v10 = 87, Uccpuppc32e500v20 = 88,
      Uccpuppc32e500v2v10 = 89, Uccpuppc32e500v2v20 = 90,
      Uccpuppc32e500v2v21 = 91, Uccpuppc32e500v2v22 = 92,
      Uccpuppc32e500v2v30 = 93, Uccpuppc32e500mc = 94,
      Uccpuppc32mpc8533v10 = 95, Uccpuppc32mpc8533v11 = 96,
      Uccpuppc32mpc8533ev10 = 97, Uccpuppc32mpc8533ev11 = 98,
      Uccpuppc32mpc8540v10 = 99, Uccpuppc32mpc8540v20 = 100,
      Uccpuppc32mpc8540v21 = 101, Uccpuppc32mpc8541v10 = 102,
      Uccpuppc32mpc8541v11 = 103, Uccpuppc32mpc8541ev10 = 104,
      Uccpuppc32mpc8541ev11 = 105, Uccpuppc32mpc8543v10 = 106,
      Uccpuppc32mpc8543v11 = 107, Uccpuppc32mpc8543v20 = 108,
      Uccpuppc32mpc8543v21 = 109, Uccpuppc32mpc8543ev10 = 110,
      Uccpuppc32mpc8543ev11 = 111, Uccpuppc32mpc8543ev20 = 112,
      Uccpuppc32mpc8543ev21 = 113, Uccpuppc32mpc8544v10 = 114,
      Uccpuppc32mpc8544v11 = 115, Uccpuppc32mpc8544ev10 = 116,
      Uccpuppc32mpc8544ev11 = 117, Uccpuppc32mpc8545v20 = 118,
      Uccpuppc32mpc8545v21 = 119, Uccpuppc32mpc8545ev20 = 120,
      Uccpuppc32mpc8545ev21 = 121, Uccpuppc32mpc8547ev20 = 122,
      Uccpuppc32mpc8547ev21 = 123, Uccpuppc32mpc8548v10 = 124,
      Uccpuppc32mpc8548v11 = 125, Uccpuppc32mpc8548v20 = 126,
      Uccpuppc32mpc8548v21 = 127, Uccpuppc32mpc8548ev10 = 128,
      Uccpuppc32mpc8548ev11 = 129, Uccpuppc32mpc8548ev20 = 130,
      Uccpuppc32mpc8548ev21 = 131, Uccpuppc32mpc8555v10 = 132,
      Uccpuppc32mpc8555v11 = 133, Uccpuppc32mpc8555ev10 = 134,
      Uccpuppc32mpc8555ev11 = 135, Uccpuppc32mpc8560v10 = 136,
      Uccpuppc32mpc8560v20 = 137, Uccpuppc32mpc8560v21 = 138,
      Uccpuppc32mpc8567 = 139, Uccpuppc32mpc8567e = 140,
      Uccpuppc32mpc8568 = 141, Uccpuppc32mpc8568e = 142,
      Uccpuppc32mpc8572 = 143, Uccpuppc32mpc8572e = 144, Uccpuppc32e600 = 145,
      Uccpuppc32mpc8610 = 146, Uccpuppc32mpc8641 = 147,
      Uccpuppc32mpc8641d = 148, Uccpuppc32601v0 = 149, Uccpuppc32601v1 = 150,
      Uccpuppc32601v2 = 151, Uccpuppc32602 = 152, Uccpuppc32603 = 153,
      Uccpuppc32603ev11 = 154, Uccpuppc32603ev12 = 155, Uccpuppc32603ev13 = 156,
      Uccpuppc32603ev14 = 157, Uccpuppc32603ev22 = 158, Uccpuppc32603ev3 = 159,
      Uccpuppc32603ev4 = 160, Uccpuppc32603ev41 = 161, Uccpuppc32603e7 = 162,
      Uccpuppc32603e7t = 163, Uccpuppc32603e7v = 164, Uccpuppc32603e7v1 = 165,
      Uccpuppc32603e7v2 = 166, Uccpuppc32603p = 167, Uccpuppc32604 = 168,
      Uccpuppc32604ev10 = 169, Uccpuppc32604ev22 = 170, Uccpuppc32604ev24 = 171,
      Uccpuppc32604r = 172, Uccpuppc32740v10 = 173, Uccpuppc32750v10 = 174,
      Uccpuppc32740v20 = 175, Uccpuppc32750v20 = 176, Uccpuppc32740v21 = 177,
      Uccpuppc32750v21 = 178, Uccpuppc32740v22 = 179, Uccpuppc32750v22 = 180,
      Uccpuppc32740v30 = 181, Uccpuppc32750v30 = 182, Uccpuppc32740v31 = 183,
      Uccpuppc32750v31 = 184, Uccpuppc32740e = 185, Uccpuppc32750e = 186,
      Uccpuppc32740p = 187, Uccpuppc32750p = 188, Uccpuppc32750clv10 = 189,
      Uccpuppc32750clv20 = 190, Uccpuppc32750cxv10 = 191,
      Uccpuppc32750cxv20 = 192, Uccpuppc32750cxv21 = 193,
      Uccpuppc32750cxv22 = 194, Uccpuppc32750cxev21 = 195,
      Uccpuppc32750cxev22 = 196, Uccpuppc32750cxev23 = 197,
      Uccpuppc32750cxev24 = 198, Uccpuppc32750cxev24b = 199,
      Uccpuppc32750cxev30 = 200, Uccpuppc32750cxev31 = 201,
      Uccpuppc32750cxev31b = 202, Uccpuppc32750cxr = 203, Uccpuppc32750fl = 204,
      Uccpuppc32750fxv10 = 205, Uccpuppc32750fxv20 = 206,
      Uccpuppc32750fxv21 = 207, Uccpuppc32750fxv22 = 208,
      Uccpuppc32750fxv23 = 209, Uccpuppc32750gl = 210, Uccpuppc32750gxv10 = 211,
      Uccpuppc32750gxv11 = 212, Uccpuppc32750gxv12 = 213,
      Uccpuppc32750lv20 = 214, Uccpuppc32750lv21 = 215, Uccpuppc32750lv22 = 216,
      Uccpuppc32750lv30 = 217, Uccpuppc32750lv32 = 218, Uccpuppc32745v10 = 219,
      Uccpuppc32755v10 = 220, Uccpuppc32745v11 = 221, Uccpuppc32755v11 = 222,
      Uccpuppc32745v20 = 223, Uccpuppc32755v20 = 224, Uccpuppc32745v21 = 225,
      Uccpuppc32755v21 = 226, Uccpuppc32745v22 = 227, Uccpuppc32755v22 = 228,
      Uccpuppc32745v23 = 229, Uccpuppc32755v23 = 230, Uccpuppc32745v24 = 231,
      Uccpuppc32755v24 = 232, Uccpuppc32745v25 = 233, Uccpuppc32755v25 = 234,
      Uccpuppc32745v26 = 235, Uccpuppc32755v26 = 236, Uccpuppc32745v27 = 237,
      Uccpuppc32755v27 = 238, Uccpuppc32745v28 = 239, Uccpuppc32755v28 = 240,
      Uccpuppc327400v10 = 241, Uccpuppc327400v11 = 242, Uccpuppc327400v20 = 243,
      Uccpuppc327400v21 = 244, Uccpuppc327400v22 = 245, Uccpuppc327400v26 = 246,
      Uccpuppc327400v27 = 247, Uccpuppc327400v28 = 248, Uccpuppc327400v29 = 249,
      Uccpuppc327410v10 = 250, Uccpuppc327410v11 = 251, Uccpuppc327410v12 = 252,
      Uccpuppc327410v13 = 253, Uccpuppc327410v14 = 254, Uccpuppc327448v10 = 255,
      Uccpuppc327448v11 = 256, Uccpuppc327448v20 = 257, Uccpuppc327448v21 = 258,
      Uccpuppc327450v10 = 259, Uccpuppc327450v11 = 260, Uccpuppc327450v12 = 261,
      Uccpuppc327450v20 = 262, Uccpuppc327450v21 = 263, Uccpuppc327441v21 = 264,
      Uccpuppc327441v23 = 265, Uccpuppc327451v23 = 266,
      Uccpuppc327441v210 = 267, Uccpuppc327451v210 = 268,
      Uccpuppc327445v10 = 269, Uccpuppc327455v10 = 270, Uccpuppc327445v21 = 271,
      Uccpuppc327455v21 = 272, Uccpuppc327445v32 = 273, Uccpuppc327455v32 = 274,
      Uccpuppc327445v33 = 275, Uccpuppc327455v33 = 276, Uccpuppc327445v34 = 277,
      Uccpuppc327455v34 = 278, Uccpuppc327447v10 = 279, Uccpuppc327457v10 = 280,
      Uccpuppc327447v11 = 281, Uccpuppc327457v11 = 282, Uccpuppc327457v12 = 283,
      Uccpuppc327447av10 = 284, Uccpuppc327457av10 = 285,
      Uccpuppc327447av11 = 286, Uccpuppc327457av11 = 287,
      Uccpuppc327447av12 = 288, Uccpuppc327457av12 = 289, Uccpuppc32ending = 290
else:
  static :
    hint("Declaration of " & "enumuccpuppc" & " already exists, not redeclaring")
when not declared(enumuccpuppc64):
  type
    enumuccpuppc64* {.size: sizeof(cuint).} = enum
      Uccpuppc64e5500 = 0, Uccpuppc64e6500 = 1, Uccpuppc64970v22 = 2,
      Uccpuppc64970fxv10 = 3, Uccpuppc64970fxv20 = 4, Uccpuppc64970fxv21 = 5,
      Uccpuppc64970fxv30 = 6, Uccpuppc64970fxv31 = 7, Uccpuppc64970mpv10 = 8,
      Uccpuppc64970mpv11 = 9, Uccpuppc64power5v21 = 10,
      Uccpuppc64power7v23 = 11, Uccpuppc64power7v21 = 12,
      Uccpuppc64power8ev21 = 13, Uccpuppc64power8v20 = 14,
      Uccpuppc64power8nvlv10 = 15, Uccpuppc64power9v10 = 16,
      Uccpuppc64power9v20 = 17, Uccpuppc64power10v10 = 18, Uccpuppc64ending = 19
else:
  static :
    hint("Declaration of " & "enumuccpuppc64" &
        " already exists, not redeclaring")
when not declared(enumucppcreg):
  type
    enumucppcreg* {.size: sizeof(cuint).} = enum
      Ucppcreginvalid = 0, Ucppcregpc = 1, Ucppcreg0 = 2, Ucppcreg1 = 3,
      Ucppcreg2 = 4, Ucppcreg3 = 5, Ucppcreg4 = 6, Ucppcreg5 = 7, Ucppcreg6 = 8,
      Ucppcreg7 = 9, Ucppcreg8 = 10, Ucppcreg9 = 11, Ucppcreg10 = 12,
      Ucppcreg11 = 13, Ucppcreg12 = 14, Ucppcreg13 = 15, Ucppcreg14 = 16,
      Ucppcreg15 = 17, Ucppcreg16 = 18, Ucppcreg17 = 19, Ucppcreg18 = 20,
      Ucppcreg19 = 21, Ucppcreg20 = 22, Ucppcreg21 = 23, Ucppcreg22 = 24,
      Ucppcreg23 = 25, Ucppcreg24 = 26, Ucppcreg25 = 27, Ucppcreg26 = 28,
      Ucppcreg27 = 29, Ucppcreg28 = 30, Ucppcreg29 = 31, Ucppcreg30 = 32,
      Ucppcreg31 = 33, Ucppcregcr0 = 34, Ucppcregcr1 = 35, Ucppcregcr2 = 36,
      Ucppcregcr3 = 37, Ucppcregcr4 = 38, Ucppcregcr5 = 39, Ucppcregcr6 = 40,
      Ucppcregcr7 = 41, Ucppcregfpr0 = 42, Ucppcregfpr1 = 43, Ucppcregfpr2 = 44,
      Ucppcregfpr3 = 45, Ucppcregfpr4 = 46, Ucppcregfpr5 = 47,
      Ucppcregfpr6 = 48, Ucppcregfpr7 = 49, Ucppcregfpr8 = 50,
      Ucppcregfpr9 = 51, Ucppcregfpr10 = 52, Ucppcregfpr11 = 53,
      Ucppcregfpr12 = 54, Ucppcregfpr13 = 55, Ucppcregfpr14 = 56,
      Ucppcregfpr15 = 57, Ucppcregfpr16 = 58, Ucppcregfpr17 = 59,
      Ucppcregfpr18 = 60, Ucppcregfpr19 = 61, Ucppcregfpr20 = 62,
      Ucppcregfpr21 = 63, Ucppcregfpr22 = 64, Ucppcregfpr23 = 65,
      Ucppcregfpr24 = 66, Ucppcregfpr25 = 67, Ucppcregfpr26 = 68,
      Ucppcregfpr27 = 69, Ucppcregfpr28 = 70, Ucppcregfpr29 = 71,
      Ucppcregfpr30 = 72, Ucppcregfpr31 = 73, Ucppcreglr = 74, Ucppcregxer = 75,
      Ucppcregctr = 76, Ucppcregmsr = 77, Ucppcregfpscr = 78, Ucppcregcr = 79,
      Ucppcregending = 80
else:
  static :
    hint("Declaration of " & "enumucppcreg" & " already exists, not redeclaring")
when not declared(enumuccpuriscv32):
  type
    enumuccpuriscv32* {.size: sizeof(cuint).} = enum
      Uccpuriscv32any = 0, Uccpuriscv32base32 = 1, Uccpuriscv32sifivee31 = 2,
      Uccpuriscv32sifiveu34 = 3, Uccpuriscv32ending = 4
else:
  static :
    hint("Declaration of " & "enumuccpuriscv32" &
        " already exists, not redeclaring")
when not declared(enumuccpuriscv64):
  type
    enumuccpuriscv64* {.size: sizeof(cuint).} = enum
      Uccpuriscv64any = 0, Uccpuriscv64base64 = 1, Uccpuriscv64sifivee51 = 2,
      Uccpuriscv64sifiveu54 = 3, Uccpuriscv64ending = 4
else:
  static :
    hint("Declaration of " & "enumuccpuriscv64" &
        " already exists, not redeclaring")
when not declared(enumucriscvreg):
  type
    enumucriscvreg* {.size: sizeof(cuint).} = enum
      Ucriscvreginvalid = 0, Ucriscvregx0 = 1, Ucriscvregx1 = 2,
      Ucriscvregx2 = 3, Ucriscvregx3 = 4, Ucriscvregx4 = 5, Ucriscvregx5 = 6,
      Ucriscvregx6 = 7, Ucriscvregx7 = 8, Ucriscvregx8 = 9, Ucriscvregx9 = 10,
      Ucriscvregx10 = 11, Ucriscvregx11 = 12, Ucriscvregx12 = 13,
      Ucriscvregx13 = 14, Ucriscvregx14 = 15, Ucriscvregx15 = 16,
      Ucriscvregx16 = 17, Ucriscvregx17 = 18, Ucriscvregx18 = 19,
      Ucriscvregx19 = 20, Ucriscvregx20 = 21, Ucriscvregx21 = 22,
      Ucriscvregx22 = 23, Ucriscvregx23 = 24, Ucriscvregx24 = 25,
      Ucriscvregx25 = 26, Ucriscvregx26 = 27, Ucriscvregx27 = 28,
      Ucriscvregx28 = 29, Ucriscvregx29 = 30, Ucriscvregx30 = 31,
      Ucriscvregx31 = 32, Ucriscvregustatus = 33, Ucriscvreguie = 34,
      Ucriscvregutvec = 35, Ucriscvreguscratch = 36, Ucriscvreguepc = 37,
      Ucriscvregucause = 38, Ucriscvregutval = 39, Ucriscvreguip = 40,
      Ucriscvregfflags = 41, Ucriscvregfrm = 42, Ucriscvregfcsr = 43,
      Ucriscvregcycle = 44, Ucriscvregtime = 45, Ucriscvreginstret = 46,
      Ucriscvreghpmcounter3 = 47, Ucriscvreghpmcounter4 = 48,
      Ucriscvreghpmcounter5 = 49, Ucriscvreghpmcounter6 = 50,
      Ucriscvreghpmcounter7 = 51, Ucriscvreghpmcounter8 = 52,
      Ucriscvreghpmcounter9 = 53, Ucriscvreghpmcounter10 = 54,
      Ucriscvreghpmcounter11 = 55, Ucriscvreghpmcounter12 = 56,
      Ucriscvreghpmcounter13 = 57, Ucriscvreghpmcounter14 = 58,
      Ucriscvreghpmcounter15 = 59, Ucriscvreghpmcounter16 = 60,
      Ucriscvreghpmcounter17 = 61, Ucriscvreghpmcounter18 = 62,
      Ucriscvreghpmcounter19 = 63, Ucriscvreghpmcounter20 = 64,
      Ucriscvreghpmcounter21 = 65, Ucriscvreghpmcounter22 = 66,
      Ucriscvreghpmcounter23 = 67, Ucriscvreghpmcounter24 = 68,
      Ucriscvreghpmcounter25 = 69, Ucriscvreghpmcounter26 = 70,
      Ucriscvreghpmcounter27 = 71, Ucriscvreghpmcounter28 = 72,
      Ucriscvreghpmcounter29 = 73, Ucriscvreghpmcounter30 = 74,
      Ucriscvreghpmcounter31 = 75, Ucriscvregcycleh = 76, Ucriscvregtimeh = 77,
      Ucriscvreginstreth = 78, Ucriscvreghpmcounter3h = 79,
      Ucriscvreghpmcounter4h = 80, Ucriscvreghpmcounter5h = 81,
      Ucriscvreghpmcounter6h = 82, Ucriscvreghpmcounter7h = 83,
      Ucriscvreghpmcounter8h = 84, Ucriscvreghpmcounter9h = 85,
      Ucriscvreghpmcounter10h = 86, Ucriscvreghpmcounter11h = 87,
      Ucriscvreghpmcounter12h = 88, Ucriscvreghpmcounter13h = 89,
      Ucriscvreghpmcounter14h = 90, Ucriscvreghpmcounter15h = 91,
      Ucriscvreghpmcounter16h = 92, Ucriscvreghpmcounter17h = 93,
      Ucriscvreghpmcounter18h = 94, Ucriscvreghpmcounter19h = 95,
      Ucriscvreghpmcounter20h = 96, Ucriscvreghpmcounter21h = 97,
      Ucriscvreghpmcounter22h = 98, Ucriscvreghpmcounter23h = 99,
      Ucriscvreghpmcounter24h = 100, Ucriscvreghpmcounter25h = 101,
      Ucriscvreghpmcounter26h = 102, Ucriscvreghpmcounter27h = 103,
      Ucriscvreghpmcounter28h = 104, Ucriscvreghpmcounter29h = 105,
      Ucriscvreghpmcounter30h = 106, Ucriscvreghpmcounter31h = 107,
      Ucriscvregmcycle = 108, Ucriscvregminstret = 109, Ucriscvregmcycleh = 110,
      Ucriscvregminstreth = 111, Ucriscvregmvendorid = 112,
      Ucriscvregmarchid = 113, Ucriscvregmimpid = 114, Ucriscvregmhartid = 115,
      Ucriscvregmstatus = 116, Ucriscvregmisa = 117, Ucriscvregmedeleg = 118,
      Ucriscvregmideleg = 119, Ucriscvregmie = 120, Ucriscvregmtvec = 121,
      Ucriscvregmcounteren = 122, Ucriscvregmstatush = 123,
      Ucriscvregmucounteren = 124, Ucriscvregmscounteren = 125,
      Ucriscvregmhcounteren = 126, Ucriscvregmscratch = 127,
      Ucriscvregmepc = 128, Ucriscvregmcause = 129, Ucriscvregmtval = 130,
      Ucriscvregmip = 131, Ucriscvregmbadaddr = 132, Ucriscvregsstatus = 133,
      Ucriscvregsedeleg = 134, Ucriscvregsideleg = 135, Ucriscvregsie = 136,
      Ucriscvregstvec = 137, Ucriscvregscounteren = 138,
      Ucriscvregsscratch = 139, Ucriscvregsepc = 140, Ucriscvregscause = 141,
      Ucriscvregstval = 142, Ucriscvregsip = 143, Ucriscvregsbadaddr = 144,
      Ucriscvregsptbr = 145, Ucriscvregsatp = 146, Ucriscvreghstatus = 147,
      Ucriscvreghedeleg = 148, Ucriscvreghideleg = 149, Ucriscvreghie = 150,
      Ucriscvreghcounteren = 151, Ucriscvreghtval = 152, Ucriscvreghip = 153,
      Ucriscvreghtinst = 154, Ucriscvreghgatp = 155, Ucriscvreghtimedelta = 156,
      Ucriscvreghtimedeltah = 157, Ucriscvregf0 = 158, Ucriscvregf1 = 159,
      Ucriscvregf2 = 160, Ucriscvregf3 = 161, Ucriscvregf4 = 162,
      Ucriscvregf5 = 163, Ucriscvregf6 = 164, Ucriscvregf7 = 165,
      Ucriscvregf8 = 166, Ucriscvregf9 = 167, Ucriscvregf10 = 168,
      Ucriscvregf11 = 169, Ucriscvregf12 = 170, Ucriscvregf13 = 171,
      Ucriscvregf14 = 172, Ucriscvregf15 = 173, Ucriscvregf16 = 174,
      Ucriscvregf17 = 175, Ucriscvregf18 = 176, Ucriscvregf19 = 177,
      Ucriscvregf20 = 178, Ucriscvregf21 = 179, Ucriscvregf22 = 180,
      Ucriscvregf23 = 181, Ucriscvregf24 = 182, Ucriscvregf25 = 183,
      Ucriscvregf26 = 184, Ucriscvregf27 = 185, Ucriscvregf28 = 186,
      Ucriscvregf29 = 187, Ucriscvregf30 = 188, Ucriscvregf31 = 189,
      Ucriscvregpc = 190, Ucriscvregending = 191
else:
  static :
    hint("Declaration of " & "enumucriscvreg" &
        " already exists, not redeclaring")
when not declared(Ucriscvregzero):
  const
    Ucriscvregzero* = enumucriscvreg.Ucriscvregx0
else:
  static :
    hint("Declaration of " & "Ucriscvregzero" &
        " already exists, not redeclaring")
when not declared(Ucriscvregra):
  const
    Ucriscvregra* = enumucriscvreg.Ucriscvregx1
else:
  static :
    hint("Declaration of " & "Ucriscvregra" & " already exists, not redeclaring")
when not declared(Ucriscvregsp):
  const
    Ucriscvregsp* = enumucriscvreg.Ucriscvregx2
else:
  static :
    hint("Declaration of " & "Ucriscvregsp" & " already exists, not redeclaring")
when not declared(Ucriscvreggp):
  const
    Ucriscvreggp* = enumucriscvreg.Ucriscvregx3
else:
  static :
    hint("Declaration of " & "Ucriscvreggp" & " already exists, not redeclaring")
when not declared(Ucriscvregtp):
  const
    Ucriscvregtp* = enumucriscvreg.Ucriscvregx4
else:
  static :
    hint("Declaration of " & "Ucriscvregtp" & " already exists, not redeclaring")
when not declared(Ucriscvregt0):
  const
    Ucriscvregt0* = enumucriscvreg.Ucriscvregx5
else:
  static :
    hint("Declaration of " & "Ucriscvregt0" & " already exists, not redeclaring")
when not declared(Ucriscvregt1):
  const
    Ucriscvregt1* = enumucriscvreg.Ucriscvregx6
else:
  static :
    hint("Declaration of " & "Ucriscvregt1" & " already exists, not redeclaring")
when not declared(Ucriscvregt2):
  const
    Ucriscvregt2* = enumucriscvreg.Ucriscvregx7
else:
  static :
    hint("Declaration of " & "Ucriscvregt2" & " already exists, not redeclaring")
when not declared(Ucriscvregs0):
  const
    Ucriscvregs0* = enumucriscvreg.Ucriscvregx8
else:
  static :
    hint("Declaration of " & "Ucriscvregs0" & " already exists, not redeclaring")
when not declared(Ucriscvregfp):
  const
    Ucriscvregfp* = enumucriscvreg.Ucriscvregx8
else:
  static :
    hint("Declaration of " & "Ucriscvregfp" & " already exists, not redeclaring")
when not declared(Ucriscvregs1):
  const
    Ucriscvregs1* = enumucriscvreg.Ucriscvregx9
else:
  static :
    hint("Declaration of " & "Ucriscvregs1" & " already exists, not redeclaring")
when not declared(Ucriscvrega0):
  const
    Ucriscvrega0* = enumucriscvreg.Ucriscvregx10
else:
  static :
    hint("Declaration of " & "Ucriscvrega0" & " already exists, not redeclaring")
when not declared(Ucriscvrega1):
  const
    Ucriscvrega1* = enumucriscvreg.Ucriscvregx11
else:
  static :
    hint("Declaration of " & "Ucriscvrega1" & " already exists, not redeclaring")
when not declared(Ucriscvrega2):
  const
    Ucriscvrega2* = enumucriscvreg.Ucriscvregx12
else:
  static :
    hint("Declaration of " & "Ucriscvrega2" & " already exists, not redeclaring")
when not declared(Ucriscvrega3):
  const
    Ucriscvrega3* = enumucriscvreg.Ucriscvregx13
else:
  static :
    hint("Declaration of " & "Ucriscvrega3" & " already exists, not redeclaring")
when not declared(Ucriscvrega4):
  const
    Ucriscvrega4* = enumucriscvreg.Ucriscvregx14
else:
  static :
    hint("Declaration of " & "Ucriscvrega4" & " already exists, not redeclaring")
when not declared(Ucriscvrega5):
  const
    Ucriscvrega5* = enumucriscvreg.Ucriscvregx15
else:
  static :
    hint("Declaration of " & "Ucriscvrega5" & " already exists, not redeclaring")
when not declared(Ucriscvrega6):
  const
    Ucriscvrega6* = enumucriscvreg.Ucriscvregx16
else:
  static :
    hint("Declaration of " & "Ucriscvrega6" & " already exists, not redeclaring")
when not declared(Ucriscvrega7):
  const
    Ucriscvrega7* = enumucriscvreg.Ucriscvregx17
else:
  static :
    hint("Declaration of " & "Ucriscvrega7" & " already exists, not redeclaring")
when not declared(Ucriscvregs2):
  const
    Ucriscvregs2* = enumucriscvreg.Ucriscvregx18
else:
  static :
    hint("Declaration of " & "Ucriscvregs2" & " already exists, not redeclaring")
when not declared(Ucriscvregs3):
  const
    Ucriscvregs3* = enumucriscvreg.Ucriscvregx19
else:
  static :
    hint("Declaration of " & "Ucriscvregs3" & " already exists, not redeclaring")
when not declared(Ucriscvregs4):
  const
    Ucriscvregs4* = enumucriscvreg.Ucriscvregx20
else:
  static :
    hint("Declaration of " & "Ucriscvregs4" & " already exists, not redeclaring")
when not declared(Ucriscvregs5):
  const
    Ucriscvregs5* = enumucriscvreg.Ucriscvregx21
else:
  static :
    hint("Declaration of " & "Ucriscvregs5" & " already exists, not redeclaring")
when not declared(Ucriscvregs6):
  const
    Ucriscvregs6* = enumucriscvreg.Ucriscvregx22
else:
  static :
    hint("Declaration of " & "Ucriscvregs6" & " already exists, not redeclaring")
when not declared(Ucriscvregs7):
  const
    Ucriscvregs7* = enumucriscvreg.Ucriscvregx23
else:
  static :
    hint("Declaration of " & "Ucriscvregs7" & " already exists, not redeclaring")
when not declared(Ucriscvregs8):
  const
    Ucriscvregs8* = enumucriscvreg.Ucriscvregx24
else:
  static :
    hint("Declaration of " & "Ucriscvregs8" & " already exists, not redeclaring")
when not declared(Ucriscvregs9):
  const
    Ucriscvregs9* = enumucriscvreg.Ucriscvregx25
else:
  static :
    hint("Declaration of " & "Ucriscvregs9" & " already exists, not redeclaring")
when not declared(Ucriscvregs10):
  const
    Ucriscvregs10* = enumucriscvreg.Ucriscvregx26
else:
  static :
    hint("Declaration of " & "Ucriscvregs10" &
        " already exists, not redeclaring")
when not declared(Ucriscvregs11):
  const
    Ucriscvregs11* = enumucriscvreg.Ucriscvregx27
else:
  static :
    hint("Declaration of " & "Ucriscvregs11" &
        " already exists, not redeclaring")
when not declared(Ucriscvregt3):
  const
    Ucriscvregt3* = enumucriscvreg.Ucriscvregx28
else:
  static :
    hint("Declaration of " & "Ucriscvregt3" & " already exists, not redeclaring")
when not declared(Ucriscvregt4):
  const
    Ucriscvregt4* = enumucriscvreg.Ucriscvregx29
else:
  static :
    hint("Declaration of " & "Ucriscvregt4" & " already exists, not redeclaring")
when not declared(Ucriscvregt5):
  const
    Ucriscvregt5* = enumucriscvreg.Ucriscvregx30
else:
  static :
    hint("Declaration of " & "Ucriscvregt5" & " already exists, not redeclaring")
when not declared(Ucriscvregt6):
  const
    Ucriscvregt6* = enumucriscvreg.Ucriscvregx31
else:
  static :
    hint("Declaration of " & "Ucriscvregt6" & " already exists, not redeclaring")
when not declared(Ucriscvregft0):
  const
    Ucriscvregft0* = enumucriscvreg.Ucriscvregf0
else:
  static :
    hint("Declaration of " & "Ucriscvregft0" &
        " already exists, not redeclaring")
when not declared(Ucriscvregft1):
  const
    Ucriscvregft1* = enumucriscvreg.Ucriscvregf1
else:
  static :
    hint("Declaration of " & "Ucriscvregft1" &
        " already exists, not redeclaring")
when not declared(Ucriscvregft2):
  const
    Ucriscvregft2* = enumucriscvreg.Ucriscvregf2
else:
  static :
    hint("Declaration of " & "Ucriscvregft2" &
        " already exists, not redeclaring")
when not declared(Ucriscvregft3):
  const
    Ucriscvregft3* = enumucriscvreg.Ucriscvregf3
else:
  static :
    hint("Declaration of " & "Ucriscvregft3" &
        " already exists, not redeclaring")
when not declared(Ucriscvregft4):
  const
    Ucriscvregft4* = enumucriscvreg.Ucriscvregf4
else:
  static :
    hint("Declaration of " & "Ucriscvregft4" &
        " already exists, not redeclaring")
when not declared(Ucriscvregft5):
  const
    Ucriscvregft5* = enumucriscvreg.Ucriscvregf5
else:
  static :
    hint("Declaration of " & "Ucriscvregft5" &
        " already exists, not redeclaring")
when not declared(Ucriscvregft6):
  const
    Ucriscvregft6* = enumucriscvreg.Ucriscvregf6
else:
  static :
    hint("Declaration of " & "Ucriscvregft6" &
        " already exists, not redeclaring")
when not declared(Ucriscvregft7):
  const
    Ucriscvregft7* = enumucriscvreg.Ucriscvregf7
else:
  static :
    hint("Declaration of " & "Ucriscvregft7" &
        " already exists, not redeclaring")
when not declared(Ucriscvregfs0):
  const
    Ucriscvregfs0* = enumucriscvreg.Ucriscvregf8
else:
  static :
    hint("Declaration of " & "Ucriscvregfs0" &
        " already exists, not redeclaring")
when not declared(Ucriscvregfs1):
  const
    Ucriscvregfs1* = enumucriscvreg.Ucriscvregf9
else:
  static :
    hint("Declaration of " & "Ucriscvregfs1" &
        " already exists, not redeclaring")
when not declared(Ucriscvregfa0):
  const
    Ucriscvregfa0* = enumucriscvreg.Ucriscvregf10
else:
  static :
    hint("Declaration of " & "Ucriscvregfa0" &
        " already exists, not redeclaring")
when not declared(Ucriscvregfa1):
  const
    Ucriscvregfa1* = enumucriscvreg.Ucriscvregf11
else:
  static :
    hint("Declaration of " & "Ucriscvregfa1" &
        " already exists, not redeclaring")
when not declared(Ucriscvregfa2):
  const
    Ucriscvregfa2* = enumucriscvreg.Ucriscvregf12
else:
  static :
    hint("Declaration of " & "Ucriscvregfa2" &
        " already exists, not redeclaring")
when not declared(Ucriscvregfa3):
  const
    Ucriscvregfa3* = enumucriscvreg.Ucriscvregf13
else:
  static :
    hint("Declaration of " & "Ucriscvregfa3" &
        " already exists, not redeclaring")
when not declared(Ucriscvregfa4):
  const
    Ucriscvregfa4* = enumucriscvreg.Ucriscvregf14
else:
  static :
    hint("Declaration of " & "Ucriscvregfa4" &
        " already exists, not redeclaring")
when not declared(Ucriscvregfa5):
  const
    Ucriscvregfa5* = enumucriscvreg.Ucriscvregf15
else:
  static :
    hint("Declaration of " & "Ucriscvregfa5" &
        " already exists, not redeclaring")
when not declared(Ucriscvregfa6):
  const
    Ucriscvregfa6* = enumucriscvreg.Ucriscvregf16
else:
  static :
    hint("Declaration of " & "Ucriscvregfa6" &
        " already exists, not redeclaring")
when not declared(Ucriscvregfa7):
  const
    Ucriscvregfa7* = enumucriscvreg.Ucriscvregf17
else:
  static :
    hint("Declaration of " & "Ucriscvregfa7" &
        " already exists, not redeclaring")
when not declared(Ucriscvregfs2):
  const
    Ucriscvregfs2* = enumucriscvreg.Ucriscvregf18
else:
  static :
    hint("Declaration of " & "Ucriscvregfs2" &
        " already exists, not redeclaring")
when not declared(Ucriscvregfs3):
  const
    Ucriscvregfs3* = enumucriscvreg.Ucriscvregf19
else:
  static :
    hint("Declaration of " & "Ucriscvregfs3" &
        " already exists, not redeclaring")
when not declared(Ucriscvregfs4):
  const
    Ucriscvregfs4* = enumucriscvreg.Ucriscvregf20
else:
  static :
    hint("Declaration of " & "Ucriscvregfs4" &
        " already exists, not redeclaring")
when not declared(Ucriscvregfs5):
  const
    Ucriscvregfs5* = enumucriscvreg.Ucriscvregf21
else:
  static :
    hint("Declaration of " & "Ucriscvregfs5" &
        " already exists, not redeclaring")
when not declared(Ucriscvregfs6):
  const
    Ucriscvregfs6* = enumucriscvreg.Ucriscvregf22
else:
  static :
    hint("Declaration of " & "Ucriscvregfs6" &
        " already exists, not redeclaring")
when not declared(Ucriscvregfs7):
  const
    Ucriscvregfs7* = enumucriscvreg.Ucriscvregf23
else:
  static :
    hint("Declaration of " & "Ucriscvregfs7" &
        " already exists, not redeclaring")
when not declared(Ucriscvregfs8):
  const
    Ucriscvregfs8* = enumucriscvreg.Ucriscvregf24
else:
  static :
    hint("Declaration of " & "Ucriscvregfs8" &
        " already exists, not redeclaring")
when not declared(Ucriscvregfs9):
  const
    Ucriscvregfs9* = enumucriscvreg.Ucriscvregf25
else:
  static :
    hint("Declaration of " & "Ucriscvregfs9" &
        " already exists, not redeclaring")
when not declared(Ucriscvregfs10):
  const
    Ucriscvregfs10* = enumucriscvreg.Ucriscvregf26
else:
  static :
    hint("Declaration of " & "Ucriscvregfs10" &
        " already exists, not redeclaring")
when not declared(Ucriscvregfs11):
  const
    Ucriscvregfs11* = enumucriscvreg.Ucriscvregf27
else:
  static :
    hint("Declaration of " & "Ucriscvregfs11" &
        " already exists, not redeclaring")
when not declared(Ucriscvregft8):
  const
    Ucriscvregft8* = enumucriscvreg.Ucriscvregf28
else:
  static :
    hint("Declaration of " & "Ucriscvregft8" &
        " already exists, not redeclaring")
when not declared(Ucriscvregft9):
  const
    Ucriscvregft9* = enumucriscvreg.Ucriscvregf29
else:
  static :
    hint("Declaration of " & "Ucriscvregft9" &
        " already exists, not redeclaring")
when not declared(Ucriscvregft10):
  const
    Ucriscvregft10* = enumucriscvreg.Ucriscvregf30
else:
  static :
    hint("Declaration of " & "Ucriscvregft10" &
        " already exists, not redeclaring")
when not declared(Ucriscvregft11):
  const
    Ucriscvregft11* = enumucriscvreg.Ucriscvregf31
else:
  static :
    hint("Declaration of " & "Ucriscvregft11" &
        " already exists, not redeclaring")
when not declared(enumuccpus390x):
  type
    enumuccpus390x* {.size: sizeof(cuint).} = enum
      Uccpus390xz900 = 0, Uccpus390xz9002 = 1, Uccpus390xz9003 = 2,
      Uccpus390xz800 = 3, Uccpus390xz990 = 4, Uccpus390xz9902 = 5,
      Uccpus390xz9903 = 6, Uccpus390xz890 = 7, Uccpus390xz9904 = 8,
      Uccpus390xz8902 = 9, Uccpus390xz9905 = 10, Uccpus390xz8903 = 11,
      Uccpus390xz9ec = 12, Uccpus390xz9ec2 = 13, Uccpus390xz9bc = 14,
      Uccpus390xz9ec3 = 15, Uccpus390xz9bc2 = 16, Uccpus390xz10ec = 17,
      Uccpus390xz10ec2 = 18, Uccpus390xz10bc = 19, Uccpus390xz10ec3 = 20,
      Uccpus390xz10bc2 = 21, Uccpus390xz196 = 22, Uccpus390xz1962 = 23,
      Uccpus390xz114 = 24, Uccpus390xzec12 = 25, Uccpus390xzec122 = 26,
      Uccpus390xzbc12 = 27, Uccpus390xz13 = 28, Uccpus390xz132 = 29,
      Uccpus390xz13s = 30, Uccpus390xz14 = 31, Uccpus390xz142 = 32,
      Uccpus390xz14zr1 = 33, Uccpus390xgen15a = 34, Uccpus390xgen15b = 35,
      Uccpus390xqemu = 36, Uccpus390xmax = 37, Uccpus390xending = 38
else:
  static :
    hint("Declaration of " & "enumuccpus390x" &
        " already exists, not redeclaring")
when not declared(enumucs390xreg):
  type
    enumucs390xreg* {.size: sizeof(cuint).} = enum
      Ucs390xreginvalid = 0, Ucs390xregr0 = 1, Ucs390xregr1 = 2,
      Ucs390xregr2 = 3, Ucs390xregr3 = 4, Ucs390xregr4 = 5, Ucs390xregr5 = 6,
      Ucs390xregr6 = 7, Ucs390xregr7 = 8, Ucs390xregr8 = 9, Ucs390xregr9 = 10,
      Ucs390xregr10 = 11, Ucs390xregr11 = 12, Ucs390xregr12 = 13,
      Ucs390xregr13 = 14, Ucs390xregr14 = 15, Ucs390xregr15 = 16,
      Ucs390xregf0 = 17, Ucs390xregf1 = 18, Ucs390xregf2 = 19,
      Ucs390xregf3 = 20, Ucs390xregf4 = 21, Ucs390xregf5 = 22,
      Ucs390xregf6 = 23, Ucs390xregf7 = 24, Ucs390xregf8 = 25,
      Ucs390xregf9 = 26, Ucs390xregf10 = 27, Ucs390xregf11 = 28,
      Ucs390xregf12 = 29, Ucs390xregf13 = 30, Ucs390xregf14 = 31,
      Ucs390xregf15 = 32, Ucs390xregf16 = 33, Ucs390xregf17 = 34,
      Ucs390xregf18 = 35, Ucs390xregf19 = 36, Ucs390xregf20 = 37,
      Ucs390xregf21 = 38, Ucs390xregf22 = 39, Ucs390xregf23 = 40,
      Ucs390xregf24 = 41, Ucs390xregf25 = 42, Ucs390xregf26 = 43,
      Ucs390xregf27 = 44, Ucs390xregf28 = 45, Ucs390xregf29 = 46,
      Ucs390xregf30 = 47, Ucs390xregf31 = 48, Ucs390xrega0 = 49,
      Ucs390xrega1 = 50, Ucs390xrega2 = 51, Ucs390xrega3 = 52,
      Ucs390xrega4 = 53, Ucs390xrega5 = 54, Ucs390xrega6 = 55,
      Ucs390xrega7 = 56, Ucs390xrega8 = 57, Ucs390xrega9 = 58,
      Ucs390xrega10 = 59, Ucs390xrega11 = 60, Ucs390xrega12 = 61,
      Ucs390xrega13 = 62, Ucs390xrega14 = 63, Ucs390xrega15 = 64,
      Ucs390xregpc = 65, Ucs390xregpswm = 66, Ucs390xregending = 67
else:
  static :
    hint("Declaration of " & "enumucs390xreg" &
        " already exists, not redeclaring")
when not declared(enumuccputricore):
  type
    enumuccputricore* {.size: sizeof(cuint).} = enum
      Uccputricoretc1796 = 0, Uccputricoretc1797 = 1, Uccputricoretc27x = 2,
      Uccputricoreending = 3
else:
  static :
    hint("Declaration of " & "enumuccputricore" &
        " already exists, not redeclaring")
when not declared(enumuctricorereg):
  type
    enumuctricorereg* {.size: sizeof(cuint).} = enum
      Uctricorereginvalid = 0, Uctricorerega0 = 1, Uctricorerega1 = 2,
      Uctricorerega2 = 3, Uctricorerega3 = 4, Uctricorerega4 = 5,
      Uctricorerega5 = 6, Uctricorerega6 = 7, Uctricorerega7 = 8,
      Uctricorerega8 = 9, Uctricorerega9 = 10, Uctricorerega10 = 11,
      Uctricorerega11 = 12, Uctricorerega12 = 13, Uctricorerega13 = 14,
      Uctricorerega14 = 15, Uctricorerega15 = 16, Uctricoreregd0 = 17,
      Uctricoreregd1 = 18, Uctricoreregd2 = 19, Uctricoreregd3 = 20,
      Uctricoreregd4 = 21, Uctricoreregd5 = 22, Uctricoreregd6 = 23,
      Uctricoreregd7 = 24, Uctricoreregd8 = 25, Uctricoreregd9 = 26,
      Uctricoreregd10 = 27, Uctricoreregd11 = 28, Uctricoreregd12 = 29,
      Uctricoreregd13 = 30, Uctricoreregd14 = 31, Uctricoreregd15 = 32,
      Uctricoreregpcxi = 33, Uctricoreregpsw = 34, Uctricoreregpswusbc = 35,
      Uctricoreregpswusbv = 36, Uctricoreregpswusbsv = 37,
      Uctricoreregpswusbav = 38, Uctricoreregpswusbsav = 39,
      Uctricoreregpc = 40, Uctricoreregsyscon = 41, Uctricoreregcpuid = 42,
      Uctricoreregbiv = 43, Uctricoreregbtv = 44, Uctricoreregisp = 45,
      Uctricoreregicr = 46, Uctricoreregfcx = 47, Uctricorereglcx = 48,
      Uctricoreregcompat = 49, Uctricoreregdpr0u = 50, Uctricoreregdpr1u = 51,
      Uctricoreregdpr2u = 52, Uctricoreregdpr3u = 53, Uctricoreregdpr0l = 54,
      Uctricoreregdpr1l = 55, Uctricoreregdpr2l = 56, Uctricoreregdpr3l = 57,
      Uctricoreregcpr0u = 58, Uctricoreregcpr1u = 59, Uctricoreregcpr2u = 60,
      Uctricoreregcpr3u = 61, Uctricoreregcpr0l = 62, Uctricoreregcpr1l = 63,
      Uctricoreregcpr2l = 64, Uctricoreregcpr3l = 65, Uctricoreregdpm0 = 66,
      Uctricoreregdpm1 = 67, Uctricoreregdpm2 = 68, Uctricoreregdpm3 = 69,
      Uctricoreregcpm0 = 70, Uctricoreregcpm1 = 71, Uctricoreregcpm2 = 72,
      Uctricoreregcpm3 = 73, Uctricoreregmmucon = 74, Uctricoreregmmuasi = 75,
      Uctricoreregmmutva = 76, Uctricoreregmmutpa = 77, Uctricoreregmmutpx = 78,
      Uctricoreregmmutfa = 79, Uctricoreregbmacon = 80, Uctricoreregsmacon = 81,
      Uctricoreregdiear = 82, Uctricoreregdietr = 83, Uctricoreregccdier = 84,
      Uctricoreregmiecon = 85, Uctricoreregpiear = 86, Uctricoreregpietr = 87,
      Uctricoreregccpier = 88, Uctricoreregdbgsr = 89, Uctricoreregexevt = 90,
      Uctricoreregcrevt = 91, Uctricoreregswevt = 92, Uctricoreregtr0evt = 93,
      Uctricoreregtr1evt = 94, Uctricoreregdms = 95, Uctricoreregdcx = 96,
      Uctricoreregdbgtcr = 97, Uctricoreregcctrl = 98, Uctricoreregccnt = 99,
      Uctricoreregicnt = 100, Uctricoreregm1cnt = 101, Uctricoreregm2cnt = 102,
      Uctricoreregm3cnt = 103, Uctricoreregending = 104
else:
  static :
    hint("Declaration of " & "enumuctricorereg" &
        " already exists, not redeclaring")
when not declared(Uctricoreregga0):
  const
    Uctricoreregga0* = enumuctricorereg.Uctricorerega0
else:
  static :
    hint("Declaration of " & "Uctricoreregga0" &
        " already exists, not redeclaring")
when not declared(Uctricoreregga1):
  const
    Uctricoreregga1* = enumuctricorereg.Uctricorerega1
else:
  static :
    hint("Declaration of " & "Uctricoreregga1" &
        " already exists, not redeclaring")
when not declared(Uctricoreregga8):
  const
    Uctricoreregga8* = enumuctricorereg.Uctricorerega8
else:
  static :
    hint("Declaration of " & "Uctricoreregga8" &
        " already exists, not redeclaring")
when not declared(Uctricoreregga9):
  const
    Uctricoreregga9* = enumuctricorereg.Uctricorerega9
else:
  static :
    hint("Declaration of " & "Uctricoreregga9" &
        " already exists, not redeclaring")
when not declared(Uctricoreregsp):
  const
    Uctricoreregsp* = enumuctricorereg.Uctricorerega10
else:
  static :
    hint("Declaration of " & "Uctricoreregsp" &
        " already exists, not redeclaring")
when not declared(Uctricorereglr):
  const
    Uctricorereglr* = enumuctricorereg.Uctricorerega11
else:
  static :
    hint("Declaration of " & "Uctricorereglr" &
        " already exists, not redeclaring")
when not declared(Uctricoreregia):
  const
    Uctricoreregia* = enumuctricorereg.Uctricorerega15
else:
  static :
    hint("Declaration of " & "Uctricoreregia" &
        " already exists, not redeclaring")
when not declared(Uctricoreregid):
  const
    Uctricoreregid* = enumuctricorereg.Uctricoreregd15
else:
  static :
    hint("Declaration of " & "Uctricoreregid" &
        " already exists, not redeclaring")
when not declared(enumucarch):
  type
    enumucarch* {.size: sizeof(cuint).} = enum
      Ucarcharm = 1, Ucarcharm64 = 2, Ucarchmips = 3, Ucarchx86 = 4,
      Ucarchppc = 5, Ucarchsparc = 6, Ucarchm68k = 7, Ucarchriscv = 8,
      Ucarchs390x = 9, Ucarchtricore = 10, Ucarchmax = 11
else:
  static :
    hint("Declaration of " & "enumucarch" & " already exists, not redeclaring")
when not declared(enumucmode):
  type
    enumucmode* {.size: sizeof(cuint).} = enum
      Ucmodelittleendian = 0, Ucmode16 = 2, Ucmodemips32 = 4, Ucmodemips64 = 8,
      Ucmodethumb = 16, Ucmodemclass = 32, Ucmodev8 = 64, Ucmodearm926 = 128,
      Ucmodearm946 = 256, Ucmodearm1176 = 512, Ucmodearmbe8 = 1024,
      Ucmodebigendian = 1073741824
else:
  static :
    hint("Declaration of " & "enumucmode" & " already exists, not redeclaring")
when not declared(Ucmodearm):
  const
    Ucmodearm* = enumucmode.Ucmodelittleendian
else:
  static :
    hint("Declaration of " & "Ucmodearm" & " already exists, not redeclaring")
when not declared(Ucmodemicro):
  const
    Ucmodemicro* = enumucmode.Ucmodethumb
else:
  static :
    hint("Declaration of " & "Ucmodemicro" & " already exists, not redeclaring")
when not declared(Ucmodemips3):
  const
    Ucmodemips3* = enumucmode.Ucmodemclass
else:
  static :
    hint("Declaration of " & "Ucmodemips3" & " already exists, not redeclaring")
when not declared(Ucmodemips32r6):
  const
    Ucmodemips32r6* = enumucmode.Ucmodev8
else:
  static :
    hint("Declaration of " & "Ucmodemips32r6" &
        " already exists, not redeclaring")
when not declared(Ucmode32):
  const
    Ucmode32* = enumucmode.Ucmodemips32
else:
  static :
    hint("Declaration of " & "Ucmode32" & " already exists, not redeclaring")
when not declared(Ucmode64):
  const
    Ucmode64* = enumucmode.Ucmodemips64
else:
  static :
    hint("Declaration of " & "Ucmode64" & " already exists, not redeclaring")
when not declared(Ucmodeppc32):
  const
    Ucmodeppc32* = enumucmode.Ucmodemips32
else:
  static :
    hint("Declaration of " & "Ucmodeppc32" & " already exists, not redeclaring")
when not declared(Ucmodeppc64):
  const
    Ucmodeppc64* = enumucmode.Ucmodemips64
else:
  static :
    hint("Declaration of " & "Ucmodeppc64" & " already exists, not redeclaring")
when not declared(Ucmodeqpx):
  const
    Ucmodeqpx* = enumucmode.Ucmodethumb
else:
  static :
    hint("Declaration of " & "Ucmodeqpx" & " already exists, not redeclaring")
when not declared(Ucmodesparc32):
  const
    Ucmodesparc32* = enumucmode.Ucmodemips32
else:
  static :
    hint("Declaration of " & "Ucmodesparc32" &
        " already exists, not redeclaring")
when not declared(Ucmodesparc64):
  const
    Ucmodesparc64* = enumucmode.Ucmodemips64
else:
  static :
    hint("Declaration of " & "Ucmodesparc64" &
        " already exists, not redeclaring")
when not declared(Ucmodev9):
  const
    Ucmodev9* = enumucmode.Ucmodethumb
else:
  static :
    hint("Declaration of " & "Ucmodev9" & " already exists, not redeclaring")
when not declared(Ucmoderiscv32):
  const
    Ucmoderiscv32* = enumucmode.Ucmodemips32
else:
  static :
    hint("Declaration of " & "Ucmoderiscv32" &
        " already exists, not redeclaring")
when not declared(Ucmoderiscv64):
  const
    Ucmoderiscv64* = enumucmode.Ucmodemips64
else:
  static :
    hint("Declaration of " & "Ucmoderiscv64" &
        " already exists, not redeclaring")
when not declared(enumucerr):
  type
    enumucerr* {.size: sizeof(cuint).} = enum
      Ucerrok = 0, Ucerrnomem = 1, Ucerrarch = 2, Ucerrhandle = 3,
      Ucerrmode = 4, Ucerrversion = 5, Ucerrreadunmapped = 6,
      Ucerrwriteunmapped = 7, Ucerrfetchunmapped = 8, Ucerrhook = 9,
      Ucerrinsninvalid = 10, Ucerrmap = 11, Ucerrwriteprot = 12,
      Ucerrreadprot = 13, Ucerrfetchprot = 14, Ucerrarg = 15,
      Ucerrreadunaligned = 16, Ucerrwriteunaligned = 17,
      Ucerrfetchunaligned = 18, Ucerrhookexist = 19, Ucerrresource = 20,
      Ucerrexception = 21
else:
  static :
    hint("Declaration of " & "enumucerr" & " already exists, not redeclaring")
when not declared(enumucmemtype):
  type
    enumucmemtype* {.size: sizeof(cuint).} = enum
      Ucmemread = 16, Ucmemwrite = 17, Ucmemfetch = 18, Ucmemreadunmapped = 19,
      Ucmemwriteunmapped = 20, Ucmemfetchunmapped = 21, Ucmemwriteprot = 22,
      Ucmemreadprot = 23, Ucmemfetchprot = 24, Ucmemreadafter = 25
else:
  static :
    hint("Declaration of " & "enumucmemtype" &
        " already exists, not redeclaring")
when not declared(enumuctcgopcode):
  type
    enumuctcgopcode* {.size: sizeof(cuint).} = enum
      Uctcgopsub = 0
else:
  static :
    hint("Declaration of " & "enumuctcgopcode" &
        " already exists, not redeclaring")
when not declared(enumuctcgopflag):
  type
    enumuctcgopflag* {.size: sizeof(cuint).} = enum
      Uctcgopflagcmp = 1, Uctcgopflagdirect = 2
else:
  static :
    hint("Declaration of " & "enumuctcgopflag" &
        " already exists, not redeclaring")
when not declared(enumuchooktype):
  type
    enumuchooktype* {.size: sizeof(cuint).} = enum
      Uchookintr = 1, Uchookinsn = 2, Uchookcode = 4, Uchookblock = 8,
      Uchookmemreadunmapped = 16, Uchookmemwriteunmapped = 32,
      Uchookmemfetchunmapped = 64, Uchookmemreadprot = 128,
      Uchookmemwriteprot = 256, Uchookmemfetchprot = 512, Uchookmemread = 1024,
      Uchookmemwrite = 2048, Uchookmemfetch = 4096, Uchookmemreadafter = 8192,
      Uchookinsninvalid = 16384, Uchookedgegenerated = 32768,
      Uchooktcgopcode = 65536
else:
  static :
    hint("Declaration of " & "enumuchooktype" &
        " already exists, not redeclaring")
when not declared(enumucquerytype):
  type
    enumucquerytype* {.size: sizeof(cuint).} = enum
      Ucquerymode = 1, Ucquerypagesize = 2, Ucqueryarch = 3, Ucquerytimeout = 4
else:
  static :
    hint("Declaration of " & "enumucquerytype" &
        " already exists, not redeclaring")
when not declared(enumuccontroltype):
  type
    enumuccontroltype* {.size: sizeof(cuint).} = enum
      Ucctlucmode = 0, Ucctlucpagesize = 1, Ucctlucarch = 2, Ucctluctimeout = 3,
      Ucctlucuseexits = 4, Ucctlucexitscnt = 5, Ucctlucexits = 6,
      Ucctlcpumodel = 7, Ucctltbrequestcache = 8, Ucctltbremovecache = 9,
      Ucctltbflush = 10
else:
  static :
    hint("Declaration of " & "enumuccontroltype" &
        " already exists, not redeclaring")
when not declared(enumucprot):
  type
    enumucprot* {.size: sizeof(cuint).} = enum
      Ucprotnone = 0, Ucprotread = 1, Ucprotwrite = 2, Ucprotexec = 4,
      Ucprotall = 7
else:
  static :
    hint("Declaration of " & "enumucprot" & " already exists, not redeclaring")
when not declared(structucstruct):
  type
    structucstruct* = object
else:
  static :
    hint("Declaration of " & "structucstruct" &
        " already exists, not redeclaring")
when not declared(structuccontext):
  type
    structuccontext* = object
else:
  static :
    hint("Declaration of " & "structuccontext" &
        " already exists, not redeclaring")
type
  ucengine_520094125 = structucstruct ## Generated based on /usr/local/include/unicorn/unicorn.h:25:26
  uchook_520094128 = csize_t ## Generated based on /usr/local/include/unicorn/unicorn.h:27:16
  uccpum68k_520094132 = enumuccpum68k_520094131 ## Generated based on /usr/local/include/unicorn/m68k.h:31:3
  ucm68kreg_520094136 = enumucm68kreg_520094135 ## Generated based on /usr/local/include/unicorn/m68k.h:59:3
  uccpux86_520094140 = enumuccpux86_520094139 ## Generated based on /usr/local/include/unicorn/x86.h:58:3
  structucx86mmr_520094142 {.pure, inheritable, bycopy.} = object
    selector*: uint16        ## Generated based on /usr/local/include/unicorn/x86.h:62:16
    base*: uint64
    limit*: uint32
    flags*: uint32

  ucx86mmr_520094144 = structucx86mmr_520094143 ## Generated based on /usr/local/include/unicorn/x86.h:67:3
  structucx86msr_520094146 {.pure, inheritable, bycopy.} = object
    rid*: uint32             ## Generated based on /usr/local/include/unicorn/x86.h:71:16
    value*: uint64

  ucx86msr_520094148 = structucx86msr_520094147 ## Generated based on /usr/local/include/unicorn/x86.h:74:3
  uccbinsnsyscallt_520094150 = proc (a0: ptr structucstruct; a1: pointer): void {.
      cdecl.}                ## Generated based on /usr/local/include/unicorn/x86.h:78:16
  uccbinsncpuidt_520094152 = proc (a0: ptr structucstruct; a1: pointer): cint {.
      cdecl.}                ## Generated based on /usr/local/include/unicorn/x86.h:86:15
  ucx86reg_520094156 = enumucx86reg_520094155 ## Generated based on /usr/local/include/unicorn/x86.h:330:3
  ucx86insn_520094160 = enumucx86insn_520094159 ## Generated based on /usr/local/include/unicorn/x86.h:1675:3
  uccpuarm_520094164 = enumuccpuarm_520094163 ## Generated based on /usr/local/include/unicorn/arm.h:56:3
  structucarmcpreg_520094166 {.pure, inheritable, bycopy.} = object
    cp*: uint32              ## Generated based on /usr/local/include/unicorn/arm.h:60:16
    is64*: uint32
    sec*: uint32
    crn*: uint32
    crm*: uint32
    opc1*: uint32
    opc2*: uint32
    val*: uint64

  ucarmcpreg_520094168 = structucarmcpreg_520094167 ## Generated based on /usr/local/include/unicorn/arm.h:69:3
  ucarmreg_520094172 = enumucarmreg_520094171 ## Generated based on /usr/local/include/unicorn/arm.h:226:3
  uccpuarm64_520094176 = enumuccpuarm64_520094175 ## Generated based on /usr/local/include/unicorn/arm64.h:26:3
  structucarm64cpreg_520094178 {.pure, inheritable, bycopy.} = object
    crn*: uint32             ## Generated based on /usr/local/include/unicorn/arm64.h:30:16
    crm*: uint32
    op0*: uint32
    op1*: uint32
    op2*: uint32
    val*: uint64

  ucarm64cpreg_520094180 = structucarm64cpreg_520094179 ## Generated based on /usr/local/include/unicorn/arm64.h:37:3
  ucarm64reg_520094184 = enumucarm64reg_520094183 ## Generated based on /usr/local/include/unicorn/arm64.h:365:3
  uccbinsnsyst_520094186 = proc (a0: ptr ucengine_520094127; a1: ucarm64reg_520094185;
                                 a2: ptr ucarm64cpreg_520094181; a3: pointer): uint32 {.
      cdecl.}                ## Generated based on /usr/local/include/unicorn/arm64.h:373:20
  ucarm64insn_520094190 = enumucarm64insn_520094189 ## Generated based on /usr/local/include/unicorn/arm64.h:387:3
  uccpumips32_520094194 = enumuccpumips32_520094193 ## Generated based on /usr/local/include/unicorn/mips.h:42:3
  uccpumips64_520094198 = enumuccpumips64_520094197 ## Generated based on /usr/local/include/unicorn/mips.h:61:3
  Ucmipsreg_520094202 = enumucmipsreg_520094201 ## Generated based on /usr/local/include/unicorn/mips.h:269:3
  uccpusparc32_520094206 = enumuccpusparc32_520094205 ## Generated based on /usr/local/include/unicorn/sparc.h:39:3
  uccpusparc64_520094210 = enumuccpusparc64_520094209 ## Generated based on /usr/local/include/unicorn/sparc.h:62:3
  ucsparcreg_520094221 = enumucsparcreg_520094220 ## Generated based on /usr/local/include/unicorn/sparc.h:166:3
  uccpuppc_520094225 = enumuccpuppc_520094224 ## Generated based on /usr/local/include/unicorn/ppc.h:312:3
  uccpuppc64_520094229 = enumuccpuppc64_520094228 ## Generated based on /usr/local/include/unicorn/ppc.h:337:3
  ucppcreg_520094233 = enumucppcreg_520094232 ## Generated based on /usr/local/include/unicorn/ppc.h:428:3
  uccpuriscv32_520094237 = enumuccpuriscv32_520094236 ## Generated based on /usr/local/include/unicorn/riscv.h:26:3
  uccpuriscv64_520094241 = enumuccpuriscv64_520094240 ## Generated based on /usr/local/include/unicorn/riscv.h:36:3
  ucriscvreg_520094245 = enumucriscvreg_520094244 ## Generated based on /usr/local/include/unicorn/riscv.h:308:3
  uccpus390x_520094249 = enumuccpus390x_520094248 ## Generated based on /usr/local/include/unicorn/s390x.h:57:3
  ucs390xreg_520094253 = enumucs390xreg_520094252 ## Generated based on /usr/local/include/unicorn/s390x.h:138:3
  uccputricore_520094257 = enumuccputricore_520094256 ## Generated based on /usr/local/include/unicorn/tricore.h:28:3
  uctricorereg_520094261 = enumuctricorereg_520094260 ## Generated based on /usr/local/include/unicorn/tricore.h:168:3
  ucarch_520094265 = enumucarch_520094264 ## Generated based on /usr/local/include/unicorn/unicorn.h:110:3
  ucmode_520094269 = enumucmode_520094268 ## Generated based on /usr/local/include/unicorn/unicorn.h:160:3
  ucerr_520094273 = enumucerr_520094272 ## Generated based on /usr/local/include/unicorn/unicorn.h:195:3
  uccbhookcodet_520094275 = proc (a0: ptr ucengine_520094127; a1: uint64;
                                  a2: uint32; a3: pointer): void {.cdecl.} ## Generated based on /usr/local/include/unicorn/unicorn.h:205:16
  uccbhookintrt_520094277 = proc (a0: ptr ucengine_520094127; a1: uint32;
                                  a2: pointer): void {.cdecl.} ## Generated based on /usr/local/include/unicorn/unicorn.h:214:16
  uccbhookinsninvalidt_520094279 = proc (a0: ptr ucengine_520094127; a1: pointer): bool {.
      cdecl.}                ## Generated based on /usr/local/include/unicorn/unicorn.h:225:16
  uccbinsnint_520094281 = proc (a0: ptr ucengine_520094127; a1: uint32;
                                a2: cint; a3: pointer): uint32 {.cdecl.} ## Generated based on /usr/local/include/unicorn/unicorn.h:234:20
  uccbinsnoutt_520094283 = proc (a0: ptr ucengine_520094127; a1: uint32;
                                 a2: cint; a3: uint32; a4: pointer): void {.
      cdecl.}                ## Generated based on /usr/local/include/unicorn/unicorn.h:244:16
  structuctb_520094285 {.pure, inheritable, bycopy.} = object
    pc*: uint64              ## Generated based on /usr/local/include/unicorn/unicorn.h:248:16
    icount*: uint16
    size*: uint16

  uctb_520094287 = structuctb_520094286 ## Generated based on /usr/local/include/unicorn/unicorn.h:252:3
  uchookedgegent_520094289 = proc (a0: ptr ucengine_520094127; a1: ptr uctb_520094288;
                                   a2: ptr uctb_520094288; a3: pointer): void {.
      cdecl.}                ## Generated based on /usr/local/include/unicorn/unicorn.h:260:16
  uchooktcgop2_520094291 = proc (a0: ptr ucengine_520094127; a1: uint64;
                                 a2: uint64; a3: uint64; a4: uint32; a5: pointer): void {.
      cdecl.}                ## Generated based on /usr/local/include/unicorn/unicorn.h:270:16
  uchooktcgsubt_520094293 = uchooktcgop2_520094292 ## Generated based on /usr/local/include/unicorn/unicorn.h:273:26
  uccbmmioreadt_520094295 = proc (a0: ptr ucengine_520094127; a1: uint64;
                                  a2: cuint; a3: pointer): uint64 {.cdecl.} ## Generated based on /usr/local/include/unicorn/unicorn.h:282:20
  uccbmmiowritet_520094297 = proc (a0: ptr ucengine_520094127; a1: uint64;
                                   a2: cuint; a3: uint64; a4: pointer): void {.
      cdecl.}                ## Generated based on /usr/local/include/unicorn/unicorn.h:293:16
  ucmemtype_520094301 = enumucmemtype_520094300 ## Generated based on /usr/local/include/unicorn/unicorn.h:309:3
  uctcgopcode_520094305 = enumuctcgopcode_520094304 ## Generated based on /usr/local/include/unicorn/unicorn.h:317:3
  uctcgopflag_520094309 = enumuctcgopflag_520094308 ## Generated based on /usr/local/include/unicorn/unicorn.h:327:3
  uchooktype_520094313 = enumuchooktype_520094312 ## Generated based on /usr/local/include/unicorn/unicorn.h:372:3
  uccbhookmemt_520094315 = proc (a0: ptr ucengine_520094127; a1: ucmemtype_520094302;
                                 a2: uint64; a3: cint; a4: int64; a5: pointer): void {.
      cdecl.}                ## Generated based on /usr/local/include/unicorn/unicorn.h:408:16
  uccbeventmemt_520094317 = proc (a0: ptr ucengine_520094127; a1: ucmemtype_520094302;
                                  a2: uint64; a3: cint; a4: int64; a5: pointer): bool {.
      cdecl.}                ## Generated based on /usr/local/include/unicorn/unicorn.h:437:16
  structucmemregion_520094319 {.pure, inheritable, bycopy.} = object
    begin*: uint64           ## Generated based on /usr/local/include/unicorn/unicorn.h:445:16
    endfield*: uint64
    perms*: uint32

  ucmemregion_520094321 = structucmemregion_520094320 ## Generated based on /usr/local/include/unicorn/unicorn.h:449:3
  ucquerytype_520094325 = enumucquerytype_520094324 ## Generated based on /usr/local/include/unicorn/unicorn.h:459:3
  uccontroltype_520094329 = enumuccontroltype_520094328 ## Generated based on /usr/local/include/unicorn/unicorn.h:541:3
  uccontext_520094331 = structuccontext ## Generated based on /usr/local/include/unicorn/unicorn.h:617:27
  ucprot_520094335 = enumucprot_520094334 ## Generated based on /usr/local/include/unicorn/unicorn.h:899:3
  ucengine_520094127 = (when declared(ucengine):
    ucengine
   else:
    ucengine_520094125)
  enumucx86reg_520094155 = (when declared(enumucx86reg):
    enumucx86reg
   else:
    enumucx86reg_520094154)
  enumucarm64insn_520094189 = (when declared(enumucarm64insn):
    enumucarm64insn
   else:
    enumucarm64insn_520094188)
  uccpuriscv64_520094242 = (when declared(uccpuriscv64):
    uccpuriscv64
   else:
    uccpuriscv64_520094241)
  ucmode_520094270 = (when declared(ucmode):
    ucmode
   else:
    ucmode_520094269)
  enumucmode_520094268 = (when declared(enumucmode):
    enumucmode
   else:
    enumucmode_520094267)
  enumuchooktype_520094312 = (when declared(enumuchooktype):
    enumuchooktype
   else:
    enumuchooktype_520094311)
  uchooktype_520094314 = (when declared(uchooktype):
    uchooktype
   else:
    uchooktype_520094313)
  uccpumips32_520094195 = (when declared(uccpumips32):
    uccpumips32
   else:
    uccpumips32_520094194)
  enumuctcgopcode_520094304 = (when declared(enumuctcgopcode):
    enumuctcgopcode
   else:
    enumuctcgopcode_520094303)
  ucarmreg_520094173 = (when declared(ucarmreg):
    ucarmreg
   else:
    ucarmreg_520094172)
  enumuccpumips64_520094197 = (when declared(enumuccpumips64):
    enumuccpumips64
   else:
    enumuccpumips64_520094196)
  enumuccpusparc64_520094209 = (when declared(enumuccpusparc64):
    enumuccpusparc64
   else:
    enumuccpusparc64_520094208)
  ucx86insn_520094161 = (when declared(ucx86insn):
    ucx86insn
   else:
    ucx86insn_520094160)
  ucarmcpreg_520094169 = (when declared(ucarmcpreg):
    ucarmcpreg
   else:
    ucarmcpreg_520094168)
  ucx86reg_520094157 = (when declared(ucx86reg):
    ucx86reg
   else:
    ucx86reg_520094156)
  enumuccpux86_520094139 = (when declared(enumuccpux86):
    enumuccpux86
   else:
    enumuccpux86_520094138)
  enumucquerytype_520094324 = (when declared(enumucquerytype):
    enumucquerytype
   else:
    enumucquerytype_520094323)
  uccbinsnint_520094282 = (when declared(uccbinsnint):
    uccbinsnint
   else:
    uccbinsnint_520094281)
  structucarm64cpreg_520094179 = (when declared(structucarm64cpreg):
    structucarm64cpreg
   else:
    structucarm64cpreg_520094178)
  enumuccpusparc32_520094205 = (when declared(enumuccpusparc32):
    enumuccpusparc32
   else:
    enumuccpusparc32_520094204)
  uctcgopcode_520094306 = (when declared(uctcgopcode):
    uctcgopcode
   else:
    uctcgopcode_520094305)
  enumucprot_520094334 = (when declared(enumucprot):
    enumucprot
   else:
    enumucprot_520094333)
  uccbinsnsyscallt_520094151 = (when declared(uccbinsnsyscallt):
    uccbinsnsyscallt
   else:
    uccbinsnsyscallt_520094150)
  enumuctricorereg_520094260 = (when declared(enumuctricorereg):
    enumuctricorereg
   else:
    enumuctricorereg_520094259)
  uccbinsncpuidt_520094153 = (when declared(uccbinsncpuidt):
    uccbinsncpuidt
   else:
    uccbinsncpuidt_520094152)
  structucmemregion_520094320 = (when declared(structucmemregion):
    structucmemregion
   else:
    structucmemregion_520094319)
  enumucerr_520094272 = (when declared(enumucerr):
    enumucerr
   else:
    enumucerr_520094271)
  enumuccputricore_520094256 = (when declared(enumuccputricore):
    enumuccputricore
   else:
    enumuccputricore_520094255)
  uctb_520094288 = (when declared(uctb):
    uctb
   else:
    uctb_520094287)
  enumuccpuarm64_520094175 = (when declared(enumuccpuarm64):
    enumuccpuarm64
   else:
    enumuccpuarm64_520094174)
  uccbinsnsyst_520094187 = (when declared(uccbinsnsyst):
    uccbinsnsyst
   else:
    uccbinsnsyst_520094186)
  structucx86msr_520094147 = (when declared(structucx86msr):
    structucx86msr
   else:
    structucx86msr_520094146)
  ucppcreg_520094234 = (when declared(ucppcreg):
    ucppcreg
   else:
    ucppcreg_520094233)
  uccbhookmemt_520094316 = (when declared(uccbhookmemt):
    uccbhookmemt
   else:
    uccbhookmemt_520094315)
  enumucppcreg_520094232 = (when declared(enumucppcreg):
    enumucppcreg
   else:
    enumucppcreg_520094231)
  uccpus390x_520094250 = (when declared(uccpus390x):
    uccpus390x
   else:
    uccpus390x_520094249)
  enumuccpum68k_520094131 = (when declared(enumuccpum68k):
    enumuccpum68k
   else:
    enumuccpum68k_520094130)
  enumucarch_520094264 = (when declared(enumucarch):
    enumucarch
   else:
    enumucarch_520094263)
  structucx86mmr_520094143 = (when declared(structucx86mmr):
    structucx86mmr
   else:
    structucx86mmr_520094142)
  ucsparcreg_520094222 = (when declared(ucsparcreg):
    ucsparcreg
   else:
    ucsparcreg_520094221)
  uccontext_520094332 = (when declared(uccontext):
    uccontext
   else:
    uccontext_520094331)
  uccbmmioreadt_520094296 = (when declared(uccbmmioreadt):
    uccbmmioreadt
   else:
    uccbmmioreadt_520094295)
  uccpum68k_520094133 = (when declared(uccpum68k):
    uccpum68k
   else:
    uccpum68k_520094132)
  enumucs390xreg_520094252 = (when declared(enumucs390xreg):
    enumucs390xreg
   else:
    enumucs390xreg_520094251)
  ucm68kreg_520094137 = (when declared(ucm68kreg):
    ucm68kreg
   else:
    ucm68kreg_520094136)
  enumucsparcreg_520094220 = (when declared(enumucsparcreg):
    enumucsparcreg
   else:
    enumucsparcreg_520094219)
  enumuccpuriscv32_520094236 = (when declared(enumuccpuriscv32):
    enumuccpuriscv32
   else:
    enumuccpuriscv32_520094235)
  enumuccpumips32_520094193 = (when declared(enumuccpumips32):
    enumuccpumips32
   else:
    enumuccpumips32_520094192)
  uccpuppc64_520094230 = (when declared(uccpuppc64):
    uccpuppc64
   else:
    uccpuppc64_520094229)
  uccpux86_520094141 = (when declared(uccpux86):
    uccpux86
   else:
    uccpux86_520094140)
  uccontroltype_520094330 = (when declared(uccontroltype):
    uccontroltype
   else:
    uccontroltype_520094329)
  structucarmcpreg_520094167 = (when declared(structucarmcpreg):
    structucarmcpreg
   else:
    structucarmcpreg_520094166)
  enumucarm64reg_520094183 = (when declared(enumucarm64reg):
    enumucarm64reg
   else:
    enumucarm64reg_520094182)
  enumuccpuarm_520094163 = (when declared(enumuccpuarm):
    enumuccpuarm
   else:
    enumuccpuarm_520094162)
  uccpuarm_520094165 = (when declared(uccpuarm):
    uccpuarm
   else:
    uccpuarm_520094164)
  uccpuarm64_520094177 = (when declared(uccpuarm64):
    uccpuarm64
   else:
    uccpuarm64_520094176)
  ucarm64reg_520094185 = (when declared(ucarm64reg):
    ucarm64reg
   else:
    ucarm64reg_520094184)
  uccpusparc32_520094207 = (when declared(uccpusparc32):
    uccpusparc32
   else:
    uccpusparc32_520094206)
  enumucarmreg_520094171 = (when declared(enumucarmreg):
    enumucarmreg
   else:
    enumucarmreg_520094170)
  ucerr_520094274 = (when declared(ucerr):
    ucerr
   else:
    ucerr_520094273)
  uccbhookcodet_520094276 = (when declared(uccbhookcodet):
    uccbhookcodet
   else:
    uccbhookcodet_520094275)
  uccbhookintrt_520094278 = (when declared(uccbhookintrt):
    uccbhookintrt
   else:
    uccbhookintrt_520094277)
  uccbmmiowritet_520094298 = (when declared(uccbmmiowritet):
    uccbmmiowritet
   else:
    uccbmmiowritet_520094297)
  ucarm64cpreg_520094181 = (when declared(ucarm64cpreg):
    ucarm64cpreg
   else:
    ucarm64cpreg_520094180)
  ucmemtype_520094302 = (when declared(ucmemtype):
    ucmemtype
   else:
    ucmemtype_520094301)
  ucquerytype_520094326 = (when declared(ucquerytype):
    ucquerytype
   else:
    ucquerytype_520094325)
  ucprot_520094336 = (when declared(ucprot):
    ucprot
   else:
    ucprot_520094335)
  structuctb_520094286 = (when declared(structuctb):
    structuctb
   else:
    structuctb_520094285)
  uctricorereg_520094262 = (when declared(uctricorereg):
    uctricorereg
   else:
    uctricorereg_520094261)
  ucarch_520094266 = (when declared(ucarch):
    ucarch
   else:
    ucarch_520094265)
  enumuccpuriscv64_520094240 = (when declared(enumuccpuriscv64):
    enumuccpuriscv64
   else:
    enumuccpuriscv64_520094239)
  uccpumips64_520094199 = (when declared(uccpumips64):
    uccpumips64
   else:
    uccpumips64_520094198)
  enumucx86insn_520094159 = (when declared(enumucx86insn):
    enumucx86insn
   else:
    enumucx86insn_520094158)
  uchooktcgsubt_520094294 = (when declared(uchooktcgsubt):
    uchooktcgsubt
   else:
    uchooktcgsubt_520094293)
  enumuctcgopflag_520094308 = (when declared(enumuctcgopflag):
    enumuctcgopflag
   else:
    enumuctcgopflag_520094307)
  uccbinsnoutt_520094284 = (when declared(uccbinsnoutt):
    uccbinsnoutt
   else:
    uccbinsnoutt_520094283)
  enumuccpus390x_520094248 = (when declared(enumuccpus390x):
    enumuccpus390x
   else:
    enumuccpus390x_520094247)
  ucs390xreg_520094254 = (when declared(ucs390xreg):
    ucs390xreg
   else:
    ucs390xreg_520094253)
  uccbhookinsninvalidt_520094280 = (when declared(uccbhookinsninvalidt):
    uccbhookinsninvalidt
   else:
    uccbhookinsninvalidt_520094279)
  enumucriscvreg_520094244 = (when declared(enumucriscvreg):
    enumucriscvreg
   else:
    enumucriscvreg_520094243)
  uccputricore_520094258 = (when declared(uccputricore):
    uccputricore
   else:
    uccputricore_520094257)
  uccpusparc64_520094211 = (when declared(uccpusparc64):
    uccpusparc64
   else:
    uccpusparc64_520094210)
  enumuccpuppc_520094224 = (when declared(enumuccpuppc):
    enumuccpuppc
   else:
    enumuccpuppc_520094223)
  ucx86msr_520094149 = (when declared(ucx86msr):
    ucx86msr
   else:
    ucx86msr_520094148)
  uccbeventmemt_520094318 = (when declared(uccbeventmemt):
    uccbeventmemt
   else:
    uccbeventmemt_520094317)
  enumucm68kreg_520094135 = (when declared(enumucm68kreg):
    enumucm68kreg
   else:
    enumucm68kreg_520094134)
  ucarm64insn_520094191 = (when declared(ucarm64insn):
    ucarm64insn
   else:
    ucarm64insn_520094190)
  Ucmipsreg_520094203 = (when declared(Ucmipsreg):
    Ucmipsreg
   else:
    Ucmipsreg_520094202)
  uccpuriscv32_520094238 = (when declared(uccpuriscv32):
    uccpuriscv32
   else:
    uccpuriscv32_520094237)
  ucriscvreg_520094246 = (when declared(ucriscvreg):
    ucriscvreg
   else:
    ucriscvreg_520094245)
  uchookedgegent_520094290 = (when declared(uchookedgegent):
    uchookedgegent
   else:
    uchookedgegent_520094289)
  uchook_520094129 = (when declared(uchook):
    uchook
   else:
    uchook_520094128)
  uchooktcgop2_520094292 = (when declared(uchooktcgop2):
    uchooktcgop2
   else:
    uchooktcgop2_520094291)
  ucx86mmr_520094145 = (when declared(ucx86mmr):
    ucx86mmr
   else:
    ucx86mmr_520094144)
  enumuccontroltype_520094328 = (when declared(enumuccontroltype):
    enumuccontroltype
   else:
    enumuccontroltype_520094327)
  uccpuppc_520094226 = (when declared(uccpuppc):
    uccpuppc
   else:
    uccpuppc_520094225)
  uctcgopflag_520094310 = (when declared(uctcgopflag):
    uctcgopflag
   else:
    uctcgopflag_520094309)
  enumuccpuppc64_520094228 = (when declared(enumuccpuppc64):
    enumuccpuppc64
   else:
    enumuccpuppc64_520094227)
  ucmemregion_520094322 = (when declared(ucmemregion):
    ucmemregion
   else:
    ucmemregion_520094321)
  enumucmemtype_520094300 = (when declared(enumucmemtype):
    enumucmemtype
   else:
    enumucmemtype_520094299)
  enumucmipsreg_520094201 = (when declared(enumucmipsreg):
    enumucmipsreg
   else:
    enumucmipsreg_520094200)
when not declared(ucengine):
  type
    ucengine* = ucengine_520094125
else:
  static :
    hint("Declaration of " & "ucengine" & " already exists, not redeclaring")
when not declared(uccpuriscv64):
  type
    uccpuriscv64* = uccpuriscv64_520094241
else:
  static :
    hint("Declaration of " & "uccpuriscv64" & " already exists, not redeclaring")
when not declared(ucmode):
  type
    ucmode* = ucmode_520094269
else:
  static :
    hint("Declaration of " & "ucmode" & " already exists, not redeclaring")
when not declared(uchooktype):
  type
    uchooktype* = uchooktype_520094313
else:
  static :
    hint("Declaration of " & "uchooktype" & " already exists, not redeclaring")
when not declared(uccpumips32):
  type
    uccpumips32* = uccpumips32_520094194
else:
  static :
    hint("Declaration of " & "uccpumips32" & " already exists, not redeclaring")
when not declared(ucarmreg):
  type
    ucarmreg* = ucarmreg_520094172
else:
  static :
    hint("Declaration of " & "ucarmreg" & " already exists, not redeclaring")
when not declared(ucx86insn):
  type
    ucx86insn* = ucx86insn_520094160
else:
  static :
    hint("Declaration of " & "ucx86insn" & " already exists, not redeclaring")
when not declared(ucarmcpreg):
  type
    ucarmcpreg* = ucarmcpreg_520094168
else:
  static :
    hint("Declaration of " & "ucarmcpreg" & " already exists, not redeclaring")
when not declared(ucx86reg):
  type
    ucx86reg* = ucx86reg_520094156
else:
  static :
    hint("Declaration of " & "ucx86reg" & " already exists, not redeclaring")
when not declared(uccbinsnint):
  type
    uccbinsnint* = uccbinsnint_520094281
else:
  static :
    hint("Declaration of " & "uccbinsnint" & " already exists, not redeclaring")
when not declared(structucarm64cpreg):
  type
    structucarm64cpreg* = structucarm64cpreg_520094178
else:
  static :
    hint("Declaration of " & "structucarm64cpreg" &
        " already exists, not redeclaring")
when not declared(uctcgopcode):
  type
    uctcgopcode* = uctcgopcode_520094305
else:
  static :
    hint("Declaration of " & "uctcgopcode" & " already exists, not redeclaring")
when not declared(uccbinsnsyscallt):
  type
    uccbinsnsyscallt* = uccbinsnsyscallt_520094150
else:
  static :
    hint("Declaration of " & "uccbinsnsyscallt" &
        " already exists, not redeclaring")
when not declared(uccbinsncpuidt):
  type
    uccbinsncpuidt* = uccbinsncpuidt_520094152
else:
  static :
    hint("Declaration of " & "uccbinsncpuidt" &
        " already exists, not redeclaring")
when not declared(structucmemregion):
  type
    structucmemregion* = structucmemregion_520094319
else:
  static :
    hint("Declaration of " & "structucmemregion" &
        " already exists, not redeclaring")
when not declared(uctb):
  type
    uctb* = uctb_520094287
else:
  static :
    hint("Declaration of " & "uctb" & " already exists, not redeclaring")
when not declared(uccbinsnsyst):
  type
    uccbinsnsyst* = uccbinsnsyst_520094186
else:
  static :
    hint("Declaration of " & "uccbinsnsyst" & " already exists, not redeclaring")
when not declared(structucx86msr):
  type
    structucx86msr* = structucx86msr_520094146
else:
  static :
    hint("Declaration of " & "structucx86msr" &
        " already exists, not redeclaring")
when not declared(ucppcreg):
  type
    ucppcreg* = ucppcreg_520094233
else:
  static :
    hint("Declaration of " & "ucppcreg" & " already exists, not redeclaring")
when not declared(uccbhookmemt):
  type
    uccbhookmemt* = uccbhookmemt_520094315
else:
  static :
    hint("Declaration of " & "uccbhookmemt" & " already exists, not redeclaring")
when not declared(uccpus390x):
  type
    uccpus390x* = uccpus390x_520094249
else:
  static :
    hint("Declaration of " & "uccpus390x" & " already exists, not redeclaring")
when not declared(structucx86mmr):
  type
    structucx86mmr* = structucx86mmr_520094142
else:
  static :
    hint("Declaration of " & "structucx86mmr" &
        " already exists, not redeclaring")
when not declared(ucsparcreg):
  type
    ucsparcreg* = ucsparcreg_520094221
else:
  static :
    hint("Declaration of " & "ucsparcreg" & " already exists, not redeclaring")
when not declared(uccontext):
  type
    uccontext* = uccontext_520094331
else:
  static :
    hint("Declaration of " & "uccontext" & " already exists, not redeclaring")
when not declared(uccbmmioreadt):
  type
    uccbmmioreadt* = uccbmmioreadt_520094295
else:
  static :
    hint("Declaration of " & "uccbmmioreadt" &
        " already exists, not redeclaring")
when not declared(uccpum68k):
  type
    uccpum68k* = uccpum68k_520094132
else:
  static :
    hint("Declaration of " & "uccpum68k" & " already exists, not redeclaring")
when not declared(ucm68kreg):
  type
    ucm68kreg* = ucm68kreg_520094136
else:
  static :
    hint("Declaration of " & "ucm68kreg" & " already exists, not redeclaring")
when not declared(uccpuppc64):
  type
    uccpuppc64* = uccpuppc64_520094229
else:
  static :
    hint("Declaration of " & "uccpuppc64" & " already exists, not redeclaring")
when not declared(uccpux86):
  type
    uccpux86* = uccpux86_520094140
else:
  static :
    hint("Declaration of " & "uccpux86" & " already exists, not redeclaring")
when not declared(uccontroltype):
  type
    uccontroltype* = uccontroltype_520094329
else:
  static :
    hint("Declaration of " & "uccontroltype" &
        " already exists, not redeclaring")
when not declared(structucarmcpreg):
  type
    structucarmcpreg* = structucarmcpreg_520094166
else:
  static :
    hint("Declaration of " & "structucarmcpreg" &
        " already exists, not redeclaring")
when not declared(uccpuarm):
  type
    uccpuarm* = uccpuarm_520094164
else:
  static :
    hint("Declaration of " & "uccpuarm" & " already exists, not redeclaring")
when not declared(uccpuarm64):
  type
    uccpuarm64* = uccpuarm64_520094176
else:
  static :
    hint("Declaration of " & "uccpuarm64" & " already exists, not redeclaring")
when not declared(ucarm64reg):
  type
    ucarm64reg* = ucarm64reg_520094184
else:
  static :
    hint("Declaration of " & "ucarm64reg" & " already exists, not redeclaring")
when not declared(uccpusparc32):
  type
    uccpusparc32* = uccpusparc32_520094206
else:
  static :
    hint("Declaration of " & "uccpusparc32" & " already exists, not redeclaring")
when not declared(ucerr):
  type
    ucerr* = ucerr_520094273
else:
  static :
    hint("Declaration of " & "ucerr" & " already exists, not redeclaring")
when not declared(uccbhookcodet):
  type
    uccbhookcodet* = uccbhookcodet_520094275
else:
  static :
    hint("Declaration of " & "uccbhookcodet" &
        " already exists, not redeclaring")
when not declared(uccbhookintrt):
  type
    uccbhookintrt* = uccbhookintrt_520094277
else:
  static :
    hint("Declaration of " & "uccbhookintrt" &
        " already exists, not redeclaring")
when not declared(uccbmmiowritet):
  type
    uccbmmiowritet* = uccbmmiowritet_520094297
else:
  static :
    hint("Declaration of " & "uccbmmiowritet" &
        " already exists, not redeclaring")
when not declared(ucarm64cpreg):
  type
    ucarm64cpreg* = ucarm64cpreg_520094180
else:
  static :
    hint("Declaration of " & "ucarm64cpreg" & " already exists, not redeclaring")
when not declared(ucmemtype):
  type
    ucmemtype* = ucmemtype_520094301
else:
  static :
    hint("Declaration of " & "ucmemtype" & " already exists, not redeclaring")
when not declared(ucquerytype):
  type
    ucquerytype* = ucquerytype_520094325
else:
  static :
    hint("Declaration of " & "ucquerytype" & " already exists, not redeclaring")
when not declared(ucprot):
  type
    ucprot* = ucprot_520094335
else:
  static :
    hint("Declaration of " & "ucprot" & " already exists, not redeclaring")
when not declared(structuctb):
  type
    structuctb* = structuctb_520094285
else:
  static :
    hint("Declaration of " & "structuctb" & " already exists, not redeclaring")
when not declared(uctricorereg):
  type
    uctricorereg* = uctricorereg_520094261
else:
  static :
    hint("Declaration of " & "uctricorereg" & " already exists, not redeclaring")
when not declared(ucarch):
  type
    ucarch* = ucarch_520094265
else:
  static :
    hint("Declaration of " & "ucarch" & " already exists, not redeclaring")
when not declared(uccpumips64):
  type
    uccpumips64* = uccpumips64_520094198
else:
  static :
    hint("Declaration of " & "uccpumips64" & " already exists, not redeclaring")
when not declared(uchooktcgsubt):
  type
    uchooktcgsubt* = uchooktcgsubt_520094293
else:
  static :
    hint("Declaration of " & "uchooktcgsubt" &
        " already exists, not redeclaring")
when not declared(uccbinsnoutt):
  type
    uccbinsnoutt* = uccbinsnoutt_520094283
else:
  static :
    hint("Declaration of " & "uccbinsnoutt" & " already exists, not redeclaring")
when not declared(ucs390xreg):
  type
    ucs390xreg* = ucs390xreg_520094253
else:
  static :
    hint("Declaration of " & "ucs390xreg" & " already exists, not redeclaring")
when not declared(uccbhookinsninvalidt):
  type
    uccbhookinsninvalidt* = uccbhookinsninvalidt_520094279
else:
  static :
    hint("Declaration of " & "uccbhookinsninvalidt" &
        " already exists, not redeclaring")
when not declared(uccputricore):
  type
    uccputricore* = uccputricore_520094257
else:
  static :
    hint("Declaration of " & "uccputricore" & " already exists, not redeclaring")
when not declared(uccpusparc64):
  type
    uccpusparc64* = uccpusparc64_520094210
else:
  static :
    hint("Declaration of " & "uccpusparc64" & " already exists, not redeclaring")
when not declared(ucx86msr):
  type
    ucx86msr* = ucx86msr_520094148
else:
  static :
    hint("Declaration of " & "ucx86msr" & " already exists, not redeclaring")
when not declared(uccbeventmemt):
  type
    uccbeventmemt* = uccbeventmemt_520094317
else:
  static :
    hint("Declaration of " & "uccbeventmemt" &
        " already exists, not redeclaring")
when not declared(ucarm64insn):
  type
    ucarm64insn* = ucarm64insn_520094190
else:
  static :
    hint("Declaration of " & "ucarm64insn" & " already exists, not redeclaring")
when not declared(Ucmipsreg):
  type
    Ucmipsreg* = Ucmipsreg_520094202
else:
  static :
    hint("Declaration of " & "Ucmipsreg" & " already exists, not redeclaring")
when not declared(uccpuriscv32):
  type
    uccpuriscv32* = uccpuriscv32_520094237
else:
  static :
    hint("Declaration of " & "uccpuriscv32" & " already exists, not redeclaring")
when not declared(ucriscvreg):
  type
    ucriscvreg* = ucriscvreg_520094245
else:
  static :
    hint("Declaration of " & "ucriscvreg" & " already exists, not redeclaring")
when not declared(uchookedgegent):
  type
    uchookedgegent* = uchookedgegent_520094289
else:
  static :
    hint("Declaration of " & "uchookedgegent" &
        " already exists, not redeclaring")
when not declared(uchook):
  type
    uchook* = uchook_520094128
else:
  static :
    hint("Declaration of " & "uchook" & " already exists, not redeclaring")
when not declared(uchooktcgop2):
  type
    uchooktcgop2* = uchooktcgop2_520094291
else:
  static :
    hint("Declaration of " & "uchooktcgop2" & " already exists, not redeclaring")
when not declared(ucx86mmr):
  type
    ucx86mmr* = ucx86mmr_520094144
else:
  static :
    hint("Declaration of " & "ucx86mmr" & " already exists, not redeclaring")
when not declared(uccpuppc):
  type
    uccpuppc* = uccpuppc_520094225
else:
  static :
    hint("Declaration of " & "uccpuppc" & " already exists, not redeclaring")
when not declared(uctcgopflag):
  type
    uctcgopflag* = uctcgopflag_520094309
else:
  static :
    hint("Declaration of " & "uctcgopflag" & " already exists, not redeclaring")
when not declared(ucmemregion):
  type
    ucmemregion* = ucmemregion_520094321
else:
  static :
    hint("Declaration of " & "ucmemregion" & " already exists, not redeclaring")
when not declared(Mscvervs2003):
  when 1310 is static:
    const
      Mscvervs2003* = 1310   ## Generated based on /usr/local/include/unicorn/platform.h:25:9
  else:
    let Mscvervs2003* = 1310 ## Generated based on /usr/local/include/unicorn/platform.h:25:9
else:
  static :
    hint("Declaration of " & "Mscvervs2003" & " already exists, not redeclaring")
when not declared(Mscvervs2005):
  when 1400 is static:
    const
      Mscvervs2005* = 1400   ## Generated based on /usr/local/include/unicorn/platform.h:26:9
  else:
    let Mscvervs2005* = 1400 ## Generated based on /usr/local/include/unicorn/platform.h:26:9
else:
  static :
    hint("Declaration of " & "Mscvervs2005" & " already exists, not redeclaring")
when not declared(Mscvervs2008):
  when 1500 is static:
    const
      Mscvervs2008* = 1500   ## Generated based on /usr/local/include/unicorn/platform.h:27:9
  else:
    let Mscvervs2008* = 1500 ## Generated based on /usr/local/include/unicorn/platform.h:27:9
else:
  static :
    hint("Declaration of " & "Mscvervs2008" & " already exists, not redeclaring")
when not declared(Mscvervs2010):
  when 1600 is static:
    const
      Mscvervs2010* = 1600   ## Generated based on /usr/local/include/unicorn/platform.h:28:9
  else:
    let Mscvervs2010* = 1600 ## Generated based on /usr/local/include/unicorn/platform.h:28:9
else:
  static :
    hint("Declaration of " & "Mscvervs2010" & " already exists, not redeclaring")
when not declared(Mscvervs2012):
  when 1700 is static:
    const
      Mscvervs2012* = 1700   ## Generated based on /usr/local/include/unicorn/platform.h:29:9
  else:
    let Mscvervs2012* = 1700 ## Generated based on /usr/local/include/unicorn/platform.h:29:9
else:
  static :
    hint("Declaration of " & "Mscvervs2012" & " already exists, not redeclaring")
when not declared(Mscvervs2013):
  when 1800 is static:
    const
      Mscvervs2013* = 1800   ## Generated based on /usr/local/include/unicorn/platform.h:30:9
  else:
    let Mscvervs2013* = 1800 ## Generated based on /usr/local/include/unicorn/platform.h:30:9
else:
  static :
    hint("Declaration of " & "Mscvervs2013" & " already exists, not redeclaring")
when not declared(Mscvervs2015):
  when 1900 is static:
    const
      Mscvervs2015* = 1900   ## Generated based on /usr/local/include/unicorn/platform.h:31:9
  else:
    let Mscvervs2015* = 1900 ## Generated based on /usr/local/include/unicorn/platform.h:31:9
else:
  static :
    hint("Declaration of " & "Mscvervs2015" & " already exists, not redeclaring")
when not declared(Ucapimajor):
  when 2 is static:
    const
      Ucapimajor* = 2        ## Generated based on /usr/local/include/unicorn/unicorn.h:73:9
  else:
    let Ucapimajor* = 2      ## Generated based on /usr/local/include/unicorn/unicorn.h:73:9
else:
  static :
    hint("Declaration of " & "Ucapimajor" & " already exists, not redeclaring")
when not declared(Ucapiminor):
  when 0 is static:
    const
      Ucapiminor* = 0        ## Generated based on /usr/local/include/unicorn/unicorn.h:74:9
  else:
    let Ucapiminor* = 0      ## Generated based on /usr/local/include/unicorn/unicorn.h:74:9
else:
  static :
    hint("Declaration of " & "Ucapiminor" & " already exists, not redeclaring")
when not declared(Ucapipatch):
  when 1 is static:
    const
      Ucapipatch* = 1        ## Generated based on /usr/local/include/unicorn/unicorn.h:75:9
  else:
    let Ucapipatch* = 1      ## Generated based on /usr/local/include/unicorn/unicorn.h:75:9
else:
  static :
    hint("Declaration of " & "Ucapipatch" & " already exists, not redeclaring")
when not declared(Ucapiextra):
  when 255 is static:
    const
      Ucapiextra* = 255      ## Generated based on /usr/local/include/unicorn/unicorn.h:77:9
  else:
    let Ucapiextra* = 255    ## Generated based on /usr/local/include/unicorn/unicorn.h:77:9
else:
  static :
    hint("Declaration of " & "Ucapiextra" & " already exists, not redeclaring")
when not declared(Ucversionmajor):
  when Ucapimajor is typedesc:
    type
      Ucversionmajor* = Ucapimajor ## Generated based on /usr/local/include/unicorn/unicorn.h:80:9
  else:
    when Ucapimajor is static:
      const
        Ucversionmajor* = Ucapimajor ## Generated based on /usr/local/include/unicorn/unicorn.h:80:9
    else:
      let Ucversionmajor* = Ucapimajor ## Generated based on /usr/local/include/unicorn/unicorn.h:80:9
else:
  static :
    hint("Declaration of " & "Ucversionmajor" &
        " already exists, not redeclaring")
when not declared(Ucversionminor):
  when Ucapiminor is typedesc:
    type
      Ucversionminor* = Ucapiminor ## Generated based on /usr/local/include/unicorn/unicorn.h:81:9
  else:
    when Ucapiminor is static:
      const
        Ucversionminor* = Ucapiminor ## Generated based on /usr/local/include/unicorn/unicorn.h:81:9
    else:
      let Ucversionminor* = Ucapiminor ## Generated based on /usr/local/include/unicorn/unicorn.h:81:9
else:
  static :
    hint("Declaration of " & "Ucversionminor" &
        " already exists, not redeclaring")
when not declared(Ucversionpatch):
  when Ucapipatch is typedesc:
    type
      Ucversionpatch* = Ucapipatch ## Generated based on /usr/local/include/unicorn/unicorn.h:82:9
  else:
    when Ucapipatch is static:
      const
        Ucversionpatch* = Ucapipatch ## Generated based on /usr/local/include/unicorn/unicorn.h:82:9
    else:
      let Ucversionpatch* = Ucapipatch ## Generated based on /usr/local/include/unicorn/unicorn.h:82:9
else:
  static :
    hint("Declaration of " & "Ucversionpatch" &
        " already exists, not redeclaring")
when not declared(Ucversionextra):
  when Ucapiextra is typedesc:
    type
      Ucversionextra* = Ucapiextra ## Generated based on /usr/local/include/unicorn/unicorn.h:83:9
  else:
    when Ucapiextra is static:
      const
        Ucversionextra* = Ucapiextra ## Generated based on /usr/local/include/unicorn/unicorn.h:83:9
    else:
      let Ucversionextra* = Ucapiextra ## Generated based on /usr/local/include/unicorn/unicorn.h:83:9
else:
  static :
    hint("Declaration of " & "Ucversionextra" &
        " already exists, not redeclaring")
when not declared(Ucsecondscale):
  when 1000000 is static:
    const
      Ucsecondscale* = 1000000 ## Generated based on /usr/local/include/unicorn/unicorn.h:93:9
  else:
    let Ucsecondscale* = 1000000 ## Generated based on /usr/local/include/unicorn/unicorn.h:93:9
else:
  static :
    hint("Declaration of " & "Ucsecondscale" &
        " already exists, not redeclaring")
when not declared(Ucmilisecondscale):
  when 1000 is static:
    const
      Ucmilisecondscale* = 1000 ## Generated based on /usr/local/include/unicorn/unicorn.h:95:9
  else:
    let Ucmilisecondscale* = 1000 ## Generated based on /usr/local/include/unicorn/unicorn.h:95:9
else:
  static :
    hint("Declaration of " & "Ucmilisecondscale" &
        " already exists, not redeclaring")
when not declared(Ucctlionone):
  when 0 is static:
    const
      Ucctlionone* = 0       ## Generated based on /usr/local/include/unicorn/unicorn.h:478:9
  else:
    let Ucctlionone* = 0     ## Generated based on /usr/local/include/unicorn/unicorn.h:478:9
else:
  static :
    hint("Declaration of " & "Ucctlionone" & " already exists, not redeclaring")
when not declared(Ucctliowrite):
  when 1 is static:
    const
      Ucctliowrite* = 1      ## Generated based on /usr/local/include/unicorn/unicorn.h:480:9
  else:
    let Ucctliowrite* = 1    ## Generated based on /usr/local/include/unicorn/unicorn.h:480:9
else:
  static :
    hint("Declaration of " & "Ucctliowrite" & " already exists, not redeclaring")
when not declared(Ucctlioread):
  when 2 is static:
    const
      Ucctlioread* = 2       ## Generated based on /usr/local/include/unicorn/unicorn.h:482:9
  else:
    let Ucctlioread* = 2     ## Generated based on /usr/local/include/unicorn/unicorn.h:482:9
else:
  static :
    hint("Declaration of " & "Ucctlioread" & " already exists, not redeclaring")
when not declared(ucversion):
  proc ucversion*(major: ptr cuint; minor: ptr cuint): cuint {.cdecl,
      importc: "uc_version".}
else:
  static :
    hint("Declaration of " & "ucversion" & " already exists, not redeclaring")
when not declared(ucarchsupported):
  proc ucarchsupported*(arch: ucarch_520094266): bool {.cdecl,
      importc: "uc_arch_supported".}
else:
  static :
    hint("Declaration of " & "ucarchsupported" &
        " already exists, not redeclaring")
when not declared(ucopen):
  proc ucopen*(arch: ucarch_520094266; mode: ucmode_520094270;
               uc: ptr ptr ucengine_520094127): ucerr_520094274 {.cdecl,
      importc: "uc_open".}
else:
  static :
    hint("Declaration of " & "ucopen" & " already exists, not redeclaring")
when not declared(ucclose):
  proc ucclose*(uc: ptr ucengine_520094127): ucerr_520094274 {.cdecl,
    discardable, importc: "uc_close".}
else:
  static :
    hint("Declaration of " & "ucclose" & " already exists, not redeclaring")
when not declared(ucquery):
  proc ucquery*(uc: ptr ucengine_520094127; typearg: ucquerytype_520094326;
                result: ptr csize_t): ucerr_520094274 {.cdecl,
      importc: "uc_query".}
else:
  static :
    hint("Declaration of " & "ucquery" & " already exists, not redeclaring")
when not declared(ucctl):
  proc ucctl*(uc: ptr ucengine_520094127; control: uccontroltype_520094330): ucerr_520094274 {.
      cdecl, varargs, importc: "uc_ctl".}
else:
  static :
    hint("Declaration of " & "ucctl" & " already exists, not redeclaring")
when not declared(ucerrno):
  proc ucerrno*(uc: ptr ucengine_520094127): ucerr_520094274 {.cdecl,
      importc: "uc_errno".}
else:
  static :
    hint("Declaration of " & "ucerrno" & " already exists, not redeclaring")
when not declared(ucstrerror):
  proc ucstrerror*(code: ucerr_520094274): cstring {.cdecl,
      importc: "uc_strerror".}
else:
  static :
    hint("Declaration of " & "ucstrerror" & " already exists, not redeclaring")
when not declared(ucregwrite):
  proc ucregwrite*(uc: ptr ucengine_520094127; regid: enumucx86reg|enumucarm64reg|cint, value: pointer): ucerr_520094274 {.
      cdecl, discardable, importc: "uc_reg_write".}
else:
  static :
    hint("Declaration of " & "ucregwrite" & " already exists, not redeclaring")
when not declared(ucregread):
  proc ucregread*(uc: ptr ucengine_520094127; regid: enumucx86reg|enumucarm64reg|cint, value: pointer): ucerr_520094274 {.
      cdecl, discardable, importc: "uc_reg_read".}
else:
  static :
    hint("Declaration of " & "ucregread" & " already exists, not redeclaring")
when not declared(ucregwritebatch):
  proc ucregwritebatch*(uc: ptr ucengine_520094127; regs: ptr cint;
                        vals: ptr pointer; count: cint): ucerr_520094274 {.
      cdecl, importc: "uc_reg_write_batch".}
else:
  static :
    hint("Declaration of " & "ucregwritebatch" &
        " already exists, not redeclaring")
when not declared(ucregreadbatch):
  proc ucregreadbatch*(uc: ptr ucengine_520094127; regs: ptr cint;
                       vals: ptr pointer; count: cint): ucerr_520094274 {.cdecl,
      importc: "uc_reg_read_batch".}
else:
  static :
    hint("Declaration of " & "ucregreadbatch" &
        " already exists, not redeclaring")
when not declared(ucmemwrite):
  proc ucmemwrite*(uc: ptr ucengine_520094127; address: uint64; bytes: pointer;
                   size: csize_t|int): ucerr_520094274 {.cdecl, discardable, importc: "uc_mem_write".}
else:
  static :
    hint("Declaration of " & "ucmemwrite" & " already exists, not redeclaring")
when not declared(ucmemread):
  proc ucmemread*(uc: ptr ucengine_520094127; address: uint64; bytes: pointer;
                  size: csize_t|int): ucerr_520094274 {.cdecl, discardable, importc: "uc_mem_read".}
else:
  static :
    hint("Declaration of " & "ucmemread" & " already exists, not redeclaring")
when not declared(ucemustart):
  proc ucemustart*(uc: ptr ucengine_520094127; begin: uint64; until: uint64;
                   timeout: uint64; count: csize_t): ucerr_520094274 {.cdecl,
      importc: "uc_emu_start".}
else:
  static :
    hint("Declaration of " & "ucemustart" & " already exists, not redeclaring")
when not declared(ucemustop):
  proc ucemustop*(uc: ptr ucengine_520094127): ucerr_520094274 {.cdecl,
      importc: "uc_emu_stop".}
else:
  static :
    hint("Declaration of " & "ucemustop" & " already exists, not redeclaring")
when not declared(uchookadd):
  proc uchookadd*(uc: ptr ucengine_520094127; hh: ptr uchook_520094129;
                  typearg: enumuchooktype; callback: pointer; userdata: pointer;
                  begin: uint64; endarg: uint64): ucerr_520094274 {.cdecl,
      varargs, discardable, importc: "uc_hook_add".}
else:
  static :
    hint("Declaration of " & "uchookadd" & " already exists, not redeclaring")
when not declared(uchookdel):
  proc uchookdel*(uc: ptr ucengine_520094127; hh: uchook_520094129): ucerr_520094274 {.
      cdecl, importc: "uc_hook_del".}
else:
  static :
    hint("Declaration of " & "uchookdel" & " already exists, not redeclaring")
when not declared(ucmemmap):
  proc ucmemmap*(uc: ptr ucengine_520094127; address: uint64; size: csize_t,
                 perms: enumucprot): ucerr_520094274 {.cdecl, discardable, importc: "uc_mem_map".}
else:
  static :
    hint("Declaration of " & "ucmemmap" & " already exists, not redeclaring")
when not declared(ucmemmapptr):
  proc ucmemmapptr*(uc: ptr ucengine_520094127; address: uint64; size: csize_t;
                    perms: uint32; ptrarg: pointer): ucerr_520094274 {.cdecl,
      importc: "uc_mem_map_ptr".}
else:
  static :
    hint("Declaration of " & "ucmemmapptr" & " already exists, not redeclaring")
when not declared(ucmmiomap):
  proc ucmmiomap*(uc: ptr ucengine_520094127; address: uint64; size: csize_t;
                  readcb: uccbmmioreadt_520094296; userdataread: pointer;
                  writecb: uccbmmiowritet_520094298; userdatawrite: pointer): ucerr_520094274 {.
      cdecl, importc: "uc_mmio_map".}
else:
  static :
    hint("Declaration of " & "ucmmiomap" & " already exists, not redeclaring")
when not declared(ucmemunmap):
  proc ucmemunmap*(uc: ptr ucengine_520094127; address: uint64; size: csize_t): ucerr_520094274 {.
      cdecl, importc: "uc_mem_unmap".}
else:
  static :
    hint("Declaration of " & "ucmemunmap" & " already exists, not redeclaring")
when not declared(ucmemprotect):
  proc ucmemprotect*(uc: ptr ucengine_520094127; address: uint64; size: csize_t;
                     perms: uint32): ucerr_520094274 {.cdecl,
      importc: "uc_mem_protect".}
else:
  static :
    hint("Declaration of " & "ucmemprotect" & " already exists, not redeclaring")
when not declared(ucmemregions):
  proc ucmemregions*(uc: ptr ucengine_520094127; regions: ptr ptr ucmemregion_520094322;
                     count: ptr uint32): ucerr_520094274 {.cdecl,
      importc: "uc_mem_regions".}
else:
  static :
    hint("Declaration of " & "ucmemregions" & " already exists, not redeclaring")
when not declared(uccontextalloc):
  proc uccontextalloc*(uc: ptr ucengine_520094127; context: ptr ptr uccontext_520094332): ucerr_520094274 {.
      cdecl, importc: "uc_context_alloc".}
else:
  static :
    hint("Declaration of " & "uccontextalloc" &
        " already exists, not redeclaring")
when not declared(ucfree):
  proc ucfree*(mem: pointer): ucerr_520094274 {.cdecl, importc: "uc_free".}
else:
  static :
    hint("Declaration of " & "ucfree" & " already exists, not redeclaring")
when not declared(uccontextsave):
  proc uccontextsave*(uc: ptr ucengine_520094127; context: ptr uccontext_520094332): ucerr_520094274 {.
      cdecl, importc: "uc_context_save".}
else:
  static :
    hint("Declaration of " & "uccontextsave" &
        " already exists, not redeclaring")
when not declared(uccontextregwrite):
  proc uccontextregwrite*(ctx: ptr uccontext_520094332; regid: cint;
                          value: pointer): ucerr_520094274 {.cdecl,
      importc: "uc_context_reg_write".}
else:
  static :
    hint("Declaration of " & "uccontextregwrite" &
        " already exists, not redeclaring")
when not declared(uccontextregread):
  proc uccontextregread*(ctx: ptr uccontext_520094332; regid: cint;
                         value: pointer): ucerr_520094274 {.cdecl,
      importc: "uc_context_reg_read".}
else:
  static :
    hint("Declaration of " & "uccontextregread" &
        " already exists, not redeclaring")
when not declared(uccontextregwritebatch):
  proc uccontextregwritebatch*(ctx: ptr uccontext_520094332; regs: ptr cint;
                               vals: ptr pointer; count: cint): ucerr_520094274 {.
      cdecl, importc: "uc_context_reg_write_batch".}
else:
  static :
    hint("Declaration of " & "uccontextregwritebatch" &
        " already exists, not redeclaring")
when not declared(uccontextregreadbatch):
  proc uccontextregreadbatch*(ctx: ptr uccontext_520094332; regs: ptr cint;
                              vals: ptr pointer; count: cint): ucerr_520094274 {.
      cdecl, importc: "uc_context_reg_read_batch".}
else:
  static :
    hint("Declaration of " & "uccontextregreadbatch" &
        " already exists, not redeclaring")
when not declared(uccontextrestore):
  proc uccontextrestore*(uc: ptr ucengine_520094127; context: ptr uccontext_520094332): ucerr_520094274 {.
      cdecl, importc: "uc_context_restore".}
else:
  static :
    hint("Declaration of " & "uccontextrestore" &
        " already exists, not redeclaring")
when not declared(uccontextsize):
  proc uccontextsize*(uc: ptr ucengine_520094127): csize_t {.cdecl,
      importc: "uc_context_size".}
else:
  static :
    hint("Declaration of " & "uccontextsize" &
        " already exists, not redeclaring")
when not declared(uccontextfree):
  proc uccontextfree*(context: ptr uccontext_520094332): ucerr_520094274 {.
      cdecl, importc: "uc_context_free".}
else:
  static :
    hint("Declaration of " & "uccontextfree" &
        " already exists, not redeclaring")