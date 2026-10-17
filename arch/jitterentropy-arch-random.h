/*
 * Non-physical true random number generator based on timing jitter.
 *
 * Copyright Stephan Mueller <smueller@chronox.de>, 2014 - 2026
 * Copyright Markus Theil <theil.markus@gmail.com>, 2026
 *
 * License
 * =======
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, and the entire permission notice in its entirety,
 *    including the disclaimer of warranties.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote
 *    products derived from this software without specific prior
 *    written permission.
 *
 * ALTERNATIVELY, this product may be distributed under the terms of
 * the GNU General Public License, in which case the provisions of the GPL are
 * required INSTEAD OF the above restrictions.  (This clause is
 * necessary due to a potential bad interaction between the GPL and
 * the restrictions contained in a BSD-style copyright.)
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, ALL OF
 * WHICH ARE HEREBY DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF NOT ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */

/*
 * Architecture / OS-specific access to the operating system's CSPRNG.
 *
 * Provides jent_os_random_bytes(), and jent_os_random_supported() to ask
 * whether the platform has a backend behind it at all. Both are defined in
 * arch/jitterentropy-arch-random.c; the dispatch order is:
 *
 *   - Linux kernel              -> get_random_bytes()
 *   - Windows (MSVC / MinGW)    -> BCryptGenRandom()
 *   - Apple / *BSD, and the     -> arc4random_buf()
 *     FreeBSD kernel
 *   - Linux userspace           -> getrandom(), /dev/urandom fallback
 *   - other Unix-like           -> /dev/urandom
 *   - anything else (baremetal) -> none, and the call fails
 *
 * Keeping the headers those need - <windows.h>, <bcrypt.h>, <sys/random.h>,
 * the file reads - away from the callers is what this file is for, as
 * elsewhere in arch/.
 *
 * None of it is an entropy source for the Jitter RNG and must never become
 * one: the library exists to produce randomness on machines whose platform has
 * none worth having, the last line of that table being a target it still has
 * to work on. The bytes are for callers that want a value nobody outside the
 * process can anticipate and can cope with the platform offering nothing.
 */
#ifndef _JITTERENTROPY_ARCH_RANDOM_H
#define _JITTERENTROPY_ARCH_RANDOM_H

/* No includes, as in every arch/ header: jitterentropy.h has the types. */

#ifdef LINUX_KERNEL
# define JENT_RANDOM_LINUX_KERNEL
#elif defined(_KERNEL) && defined(__FreeBSD__)
# define JENT_RANDOM_ARC4RANDOM
#elif defined(JENT_BAREMETAL)
#elif defined(_MSC_VER) || defined(__MINGW32__)
# define JENT_RANDOM_WINDOWS
#elif defined(__APPLE__)  || defined(__FreeBSD__) || defined(__OpenBSD__) || \
      defined(__NetBSD__) || defined(__DragonFly__)
# define JENT_RANDOM_ARC4RANDOM
#elif defined(__linux__)
# if defined(__ANDROID__) && __ANDROID_API__ < 28
#  define JENT_RANDOM_DEVURANDOM
# elif defined(__GLIBC__) && \
       (__GLIBC__ < 2 || (__GLIBC__ == 2 && __GLIBC_MINOR__ < 25))
#  define JENT_RANDOM_DEVURANDOM
# else
#  define JENT_RANDOM_GETRANDOM
# endif
#elif defined(__unix__) || defined(__sun) || defined(_AIX) || \
      defined(__HAIKU__) || defined(__CYGWIN__)
# define JENT_RANDOM_DEVURANDOM
#endif

#if defined(JENT_RANDOM_LINUX_KERNEL) || defined(JENT_RANDOM_WINDOWS) || \
    defined(JENT_RANDOM_ARC4RANDOM) || defined(JENT_RANDOM_GETRANDOM) || \
    defined(JENT_RANDOM_DEVURANDOM)
# define JENT_RANDOM_AVAILABLE
#endif

#if defined(JENT_RANDOM_GETRANDOM) || defined(JENT_RANDOM_DEVURANDOM)
JENT_INTERNAL
int jent_random_read_file(const char *path, uint8_t *buf, size_t len);
JENT_INTERNAL
int jent_random_dev_urandom(uint8_t *buf, size_t len);
#endif

/*
 * Fill @buf with @len bytes from whichever of the above this target has.
 * Returns 0 on success and nonzero where there is none to ask or the ask
 * failed, in which case @buf holds nothing worth using.
 */
JENT_INTERNAL
int jent_os_random_bytes(uint8_t *buf, size_t len);

/* Whether one of those backends is compiled in. */
JENT_INTERNAL
int jent_os_random_supported(void);

#endif /* _JITTERENTROPY_ARCH_RANDOM_H */
