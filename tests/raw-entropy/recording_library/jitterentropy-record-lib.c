/*
 * libjitterentropy-record in one translation unit
 *
 * Copyright (C) 2026, Markus Theil <theil.markus@gmail.com>
 *
 * License: see LICENSE file in root directory
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
 * The recording reaches internals a shared libjitterentropy does not export,
 * so the library carries a copy of libjitterentropy of its own. It is compiled
 * here, with the recording, as a private copy (JENT_PRIVATE_COMPILE in
 * jitterentropy.h): every function of the copy is static, and the object
 * defines the functions of jitterentropy-record.h and nothing else. That is
 * what lets it link beside libjitterentropy, shared or static, and it is a
 * property of the compilation - no linker has to hide anything afterwards.
 */
#ifdef _MSC_VER
# pragma warning(disable: 4505)
#endif

#ifndef JENT_RAW_COLLECTOR
#define JENT_RAW_COLLECTOR
#endif

#if defined(__linux__) && !defined(_GNU_SOURCE)
# define _GNU_SOURCE
#endif
#include "../../../arch/jitterentropy-arch-compat.h"

#include "jitterentropy-internal.h"
#include "jitterentropy-base.h"
#include "jitterentropy-gcd.h"
#include "jitterentropy-health.h"
#include "jitterentropy-noise.h"
#include "jitterentropy-timer.h"
#include "jitterentropy-sha3.h"
#include "jitterentropy-uuid.h"

#include "jitterentropy-record.c"
