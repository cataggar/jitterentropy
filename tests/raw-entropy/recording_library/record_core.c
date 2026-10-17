/*
 * Private libjitterentropy core used by the Zig recording library.
 *
 * The core is still implemented in C while it is being ported independently.
 * Keep it in one private translation unit and expose only this hidden table to
 * record_lib.zig, so libjitterentropy-record remains safely co-linkable with
 * libjitterentropy.
 */

#define JENT_PRIVATE_COMPILE
#define JENT_RAW_COLLECTOR

#if defined(__linux__) && !defined(_GNU_SOURCE)
# define _GNU_SOURCE
#endif

#include <errno.h>
#include <limits.h>

#ifdef __linux__
# include <sched.h>
#endif

#ifdef __APPLE__
# include <pthread.h>
# include <sys/qos.h>
# include <sys/resource.h>
#endif

#include "../../../arch/jitterentropy-arch-compat.h"

#include "../../../arch/jitterentropy-arch-atomic.c"

#include "../../../src/jitterentropy-sha3.c"
#include "../../../src/jitterentropy-gcd.c"
#include "../../../src/jitterentropy-health.c"
#include "../../../src/jitterentropy-noise.c"
#include "../../../src/jitterentropy-timer.c"
#include "../../../src/jitterentropy-base.c"
#include "../../../src/jitterentropy-uuid.c"
#include "../../../src/jitterentropy-status.c"

#include "../../../arch/jitterentropy-arch-cache.c"
#include "../../../arch/jitterentropy-arch-fips.c"
#include "../../../arch/jitterentropy-arch-memory.c"
#include "../../../arch/jitterentropy-arch-ncpu.c"
#include "../../../arch/jitterentropy-arch-sched.c"
#include "../../../arch/jitterentropy-arch-thread.c"
#include "../../../arch/jitterentropy-arch-timer.c"
#include "../../../arch/jitterentropy-arch-random.c"

#include "jitterentropy-record.h"

typedef unsigned int (*jent_record_measure_t)(struct rand_data *, uint64_t,
					      uint64_t *, int);

struct jent_record_core_api {
	int (*raw_selftest)(unsigned int);
	struct rand_data *(*collector_alloc_raw)(unsigned int, unsigned int);
	void (*collector_free)(struct rand_data *);
	int (*notime_settick)(struct rand_data *);
	void (*notime_unsettick)(struct rand_data *);
	int (*status)(const struct rand_data *, char *, size_t);
	unsigned int (*health_failure)(struct rand_data *);
	jent_record_measure_t measure_common;
	jent_record_measure_t measure_hashloop;
	jent_record_measure_t measure_memaccess;
	void *(*zalloc_unlocked)(size_t);
	void (*zfree)(void *, size_t);
	int (*enable_notime)(const struct rand_data *);
	void (*set_fips_enabled)(struct rand_data *);
	void (*set_common_timer_gcd)(struct rand_data *, uint64_t);
	void (*result)(const struct rand_data *, struct jent_record_result *);
	int (*pin_cpu)(unsigned long);
	int (*select_cores)(int);
	int (*get_errno)(void);
	void (*set_errno)(int);
	char *(*error_string)(int);
};

static int jent_record_core_enable_notime(const struct rand_data *ec)
{
	return ec->enable_notime;
}

static void jent_record_core_set_fips_enabled(struct rand_data *ec)
{
	ec->is_fips_enabled = 1;
}

static void jent_record_core_set_common_timer_gcd(struct rand_data *ec,
						  uint64_t gcd)
{
	ec->jent_common_timer_gcd = gcd;
}

static void jent_record_core_result(const struct rand_data *ec,
				    struct jent_record_result *result)
{
	result->health_failure = 0;
	result->memsize = ec->mem ? ec->memmask + 1 : 0;
	result->hashloopcnt = ec->hashloopcnt;
	result->internal_timer = ec->enable_notime;
}

static int jent_record_core_pin_cpu(unsigned long cpu)
{
#ifdef JENT_CONF_ENABLE_INTERNAL_TIMER
	return jent_thread_pin_to_cpu(cpu);
#elif defined(__linux__)
	cpu_set_t set;

	if (cpu >= (unsigned long)CPU_SETSIZE)
		return -EINVAL;
	CPU_ZERO(&set);
	CPU_SET((size_t)cpu, &set);
	if (sched_setaffinity(0, sizeof(set), &set))
		return -errno;
	return 0;
#else
	(void)cpu;
	return -ENOSYS;
#endif
}

static int jent_record_core_select_cores(int performance)
{
#ifdef __APPLE__
	int ret;

	if (performance && setpriority(PRIO_DARWIN_PROCESS, 0, 0))
		return -errno;

	ret = pthread_set_qos_class_self_np(performance ?
					    QOS_CLASS_USER_INTERACTIVE :
					    QOS_CLASS_BACKGROUND, 0);
	return ret ? -ret : 0;
#else
	(void)performance;
	return -ENOSYS;
#endif
}

static int jent_record_core_get_errno(void)
{
	return errno;
}

static void jent_record_core_set_errno(int err)
{
	errno = err;
}

#if defined(__GNUC__) || defined(__clang__)
# define JENT_RECORD_HIDDEN __attribute__((visibility("hidden")))
#else
# define JENT_RECORD_HIDDEN
#endif

JENT_RECORD_HIDDEN
const struct jent_record_core_api jent_record_core_api = {
	.raw_selftest = jent_raw_selftest,
	.collector_alloc_raw = jent_entropy_collector_alloc_raw,
	.collector_free = jent_entropy_collector_free,
	.notime_settick = jent_notime_settick,
	.notime_unsettick = jent_notime_unsettick,
	.status = jent_status,
	.health_failure = jent_health_failure,
	.measure_common = jent_measure_jitter,
	.measure_hashloop = jent_measure_jitter_ntg1_sha3,
	.measure_memaccess = jent_measure_jitter_ntg1_memaccess,
	.zalloc_unlocked = jent_zalloc_unlocked,
	.zfree = jent_zfree,
	.enable_notime = jent_record_core_enable_notime,
	.set_fips_enabled = jent_record_core_set_fips_enabled,
	.set_common_timer_gcd = jent_record_core_set_common_timer_gcd,
	.result = jent_record_core_result,
	.pin_cpu = jent_record_core_pin_cpu,
	.select_cores = jent_record_core_select_cores,
	.get_errno = jent_record_core_get_errno,
	.set_errno = jent_record_core_set_errno,
	.error_string = strerror,
};
