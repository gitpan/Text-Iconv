/* $Id: Iconv.xs,v 1.1 1997/08/25 17:33:24 mxp Exp $ */
/* XSUB for Perl module Text::Iconv       */
/* Copyright (c) 1997, Michael Piotrowski */

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <iconv.h>

/*****************************************************************************/

SV *do_conv(iconv_t iconv_handle, SV *string)
{
   char    *ibuf;         /* char* to the content of SV *string */
   char    *obuf;         /* temporary output buffer */
   size_t  inbytesleft;   /* no. of bytes left to convert; initially
			     this is the length of the input string,
			     and 0 when the conversion has finished */
   size_t  outbytesleft;  /* no. of bytes in the output buffer */
   size_t  l_obuf;        /* length of the output buffer */
   char    *icursor;      /* current position in the input buffer */
   char    *ocursor;      /* current position in the output buffer */
   size_t  ret;           /* iconv() return value */
   SV      *perl_str;     /* Perl return string */
   
   perl_str = newSVpv("", 0);

   /* Get length of input string. That's why we take an SV* instead of
      a char*: This way we can convert UCS-2 strings because we know
      their length. */

   inbytesleft = SvCUR(string);
   ibuf        = SvPV(string, inbytesleft);
   
   /* Calculate approximate amount of memory needed for the temporary
      output buffer and reserve the memory. The idea is to choose it
      large enough from the beginning to reduce the number of copy
      operations when converting from a single byte to a multibyte
      encoding. */
   
   if(inbytesleft <= MB_LEN_MAX)
   {
      outbytesleft = MB_LEN_MAX + 1;
   }
   else
   {
      outbytesleft = 2 * inbytesleft;
   }

   l_obuf = outbytesleft;
   obuf   = (char *) New(0, obuf, outbytesleft, char); /* Perl malloc */

   /**************************************************************************/

   icursor = ibuf;
   ocursor = obuf;

   /**************************************************************************/
   
   while(inbytesleft != 0)
   {
      ret = iconv(iconv_handle, &icursor, &inbytesleft,
		                &ocursor, &outbytesleft);
      
      if(ret == (size_t) -1)
      {
	 switch(errno)
	 {
	    case EILSEQ:
	       /* Stop conversion if input character encountered which
		  does not belong to the input char set */
	       warn("Character not from source char set: %s", strerror(errno));
	       free(obuf);   
	       (void) iconv_close(iconv_handle);
	       return(&sv_undef);
	    case EINVAL:
	       /* Stop conversion if we encounter an incomplete
                  character or shift sequence */
	       warn("Incomplete character or shift sequence: %s",
		    strerror(errno));
	       free(obuf);   
	       (void) iconv_close(iconv_handle);
	       return(&sv_undef);
	    case E2BIG:
	       /* If the output buffer is not large enough, copy the
                  converted bytes to the return string, reset the
                  output buffer and continue */
	       sv_catpvn(perl_str, obuf, l_obuf - outbytesleft);
	       ocursor = obuf;
	       outbytesleft = l_obuf;
	       break;
	    default:
	       warn("iconv error: %s", strerror(errno));
	       free(obuf);   
	       (void) iconv_close(iconv_handle);
	       return(&sv_undef);
	 }
      }
   }

   /* Copy the converted bytes to the return string, free the output
      buffer and release the conversion descriptor */
   
   sv_catpvn(perl_str, obuf, l_obuf - outbytesleft);
   Safefree(obuf); /* Perl malloc */
/*   (void) iconv_close(iconv_handle); */

   return perl_str;
}

/*****************************************************************************/
/* Perl interface                                                            */

MODULE = Text::Iconv		PACKAGE = Text::Iconv      PREFIX = iconv_t_

iconv_t
iconv_t_new(self, fromcode, tocode)
   char *fromcode
   char *tocode
   CODE:
   if((RETVAL = iconv_open(tocode, fromcode)) == (iconv_t)-1)
   {
      switch(errno)
      {
	 case ENOMEM:
	    croak("Insufficient memory to initialize conversion: %s", 
		  strerror(errno));
	 case EINVAL:
	    croak("Unsupported conversion: %s", strerror(errno));
	 default:
	    croak("Couldn't initialize conversion: %s", strerror(errno));
      }
   }
   OUTPUT:
      RETVAL

MODULE = Text::Iconv		PACKAGE = iconv_t      PREFIX = iconv_t_

SV*
iconv_t_convert(self, string)
   iconv_t self
   SV *string
   CODE:
      RETVAL = do_conv(self, string);
   OUTPUT:
      RETVAL

void
iconv_t_DESTROY(self)
   iconv_t self
   CODE:
      /* printf("Now in iconv_t::DESTROY\n"); */
      (void) iconv_close(self);
