// SPDX-License-Identifier: GPL-2.0 OR BSD-2-Clause

#ifdef CONFIG_EXTERNAL_JITTERENTROPY_KCAPI
#include <crypto/algapi.h>
#endif
#include <linux/capability.h>
#include <linux/cpumask.h>
#include <linux/delay.h>
#include <linux/errno.h>
#include <linux/fips.h>
#include <linux/init.h>
#include <linux/jiffies.h>
#include <linux/kernel.h>
#include <linux/log2.h>
#include <linux/mm.h>
#include <linux/module.h>
#include <linux/mutex.h>
#include <linux/proc_fs.h>
#include <linux/random.h>
#include <linux/sched.h>
#include <linux/seq_file.h>
#include <linux/slab.h>
#include <linux/string.h>
#include <linux/timex.h>
#include <linux/uaccess.h>
#include <linux/workqueue.h>

#include "jitterentropy.h"
#include "jitterentropy_chardev.h"
#include "jitterentropy_hwrng.h"
#include "jitterentropy_ioctl.h"
#include "jitterentropy_kcapi.h"
#include "jitterentropy_proc.h"
#include "jitterentropy_selftest.h"
#include "jitterentropy_testing.h"
#include "jitterentropy_uapi.h"

unsigned int jent_osr;
unsigned int jent_flags;
unsigned int jent_verbose;
bool jent_kparam_ntg1;
bool jent_kparam_force_fips;
bool jent_kparam_cache_all;
unsigned int jent_kparam_max_memsize;
unsigned int jent_kparam_selftest_interval;

module_param_named(osr, jent_osr, uint, 0444);
MODULE_PARM_DESC(osr, "Jitter RNG OSR parameter");
module_param_named(flags, jent_flags, uint, 0444);
MODULE_PARM_DESC(flags, "Jitter RNG flags parameter");
module_param_named(verbose, jent_verbose, uint, 0444);
MODULE_PARM_DESC(verbose, "Jitter RNG verbose logging");
module_param_named(ntg1, jent_kparam_ntg1, bool, 0444);
MODULE_PARM_DESC(ntg1, "Enable AIS 20/31 NTG.1 compliant operation");
module_param_named(force_fips, jent_kparam_force_fips, bool, 0444);
MODULE_PARM_DESC(force_fips, "Force FIPS compliant operation");
module_param_named(cache_all, jent_kparam_cache_all, bool, 0444);
MODULE_PARM_DESC(cache_all, "Derive the memory region from all caches");
module_param_named(max_memsize, jent_kparam_max_memsize, uint, 0444);
MODULE_PARM_DESC(max_memsize, "Memory access region of an instance in kB");
module_param_named(selftest_interval, jent_kparam_selftest_interval, uint, 0444);
MODULE_PARM_DESC(selftest_interval, "Seconds between cryptographic self tests");

extern int jent_zig_mod_init(void);
extern void jent_zig_mod_exit(void);
extern void jent_zig_selftest_work(struct jent_selftest_instance *st);

void *jent_kshim_kvzalloc(size_t len);
void jent_kshim_kvfree_sensitive(void *ptr, size_t len);
u64 jent_kshim_random_get_entropy(void);
void jent_kshim_schedule(void);
int jent_kshim_fips_enabled(void);
long jent_kshim_num_online_cpus(void);
void jent_kshim_get_random_bytes(u8 *buf, size_t len);
unsigned int jent_kshim_max_memsize_kb(void);
int jent_kshim_mutex_lock_interruptible(struct mutex *lock);
void jent_kshim_mutex_lock(struct mutex *lock);
void jent_kshim_mutex_unlock(struct mutex *lock);
int jent_kshim_copy_from_user(void *dst, const void __user *src, size_t len);
int jent_kshim_copy_to_user(void __user *dst, const void *src, size_t len);
int jent_kshim_seq_write(struct seq_file *m, const void *data, size_t len);
void jent_kshim_log(int level, const char *data, size_t len);
void __noreturn jent_kshim_panic_init(int ret);
void __noreturn jent_kshim_panic_selftest(int ret);
int jent_kshim_ioctl_kind(unsigned int cmd);
void jent_kshim_selftest_setup(struct jent_selftest_instance *st,
			       struct mutex *lock, struct rand_data **ec);
struct mutex *jent_kshim_selftest_lock(struct jent_selftest_instance *st);
struct rand_data **jent_kshim_selftest_ec(struct jent_selftest_instance *st);
bool jent_kshim_selftest_failed(struct jent_selftest_instance *st);
void jent_kshim_selftest_set_failed(struct jent_selftest_instance *st,
				    bool failed);
void jent_kshim_selftest_schedule(struct jent_selftest_instance *st,
				  unsigned int seconds);
void jent_kshim_selftest_cancel(struct jent_selftest_instance *st);
unsigned int jent_kshim_selftest_interval_max(void);
int __init jent_kshim_chardev_init(void);
void jent_kshim_chardev_exit(void);
int __init jent_kshim_hwrng_init(void);
void jent_kshim_hwrng_exit(void);
int __init jent_kshim_kcapi_init(void);
void jent_kshim_kcapi_exit(void);
int __init jent_kshim_testing_init(void);
void jent_kshim_testing_exit(void);
unsigned int jent_kshim_interface_enabled(unsigned int which);
int jent_kshim_proc_create(void);
void jent_kshim_proc_remove(void);

static int __init jent_mod_init(void)
{
	return jent_zig_mod_init();
}

static void __exit jent_mod_exit(void)
{
	jent_zig_mod_exit();
}

module_init(jent_mod_init);
module_exit(jent_mod_exit);

MODULE_LICENSE("Dual BSD/GPL");
MODULE_AUTHOR("Stephan Mueller <smueller@chronox.de>");
MODULE_AUTHOR("Markus Theil <theil.markus@gmail.com>");
MODULE_DESCRIPTION("Non-physical True Random Number Generator based on CPU Jitter");
#ifdef CONFIG_EXTERNAL_JITTERENTROPY_KCAPI
# ifdef CONFIG_BUILTIN_JITTERENTROPY
MODULE_ALIAS_CRYPTO("jitterentropy_rng");
# else
MODULE_ALIAS_CRYPTO("jitter_rng");
# endif
#endif

void *jent_kshim_kvzalloc(size_t len)
{
	return kvzalloc(len, GFP_KERNEL_ACCOUNT);
}

void jent_kshim_kvfree_sensitive(void *ptr, size_t len)
{
	if (ptr)
		kvfree_sensitive(ptr, len);
}

u64 jent_kshim_random_get_entropy(void)
{
	return random_get_entropy();
}

void jent_kshim_schedule(void)
{
	schedule();
}

int jent_kshim_fips_enabled(void)
{
	return fips_enabled;
}

long jent_kshim_num_online_cpus(void)
{
	return num_online_cpus();
}

void jent_kshim_get_random_bytes(u8 *buf, size_t len)
{
	get_random_bytes(buf, len);
}

unsigned int jent_kshim_max_memsize_kb(void)
{
#if BITS_PER_LONG == 32
	return 65536U;
#else
	return 524288U;
#endif
}

int jent_kshim_mutex_lock_interruptible(struct mutex *lock)
{
	return mutex_lock_interruptible(lock);
}

void jent_kshim_mutex_lock(struct mutex *lock)
{
	mutex_lock(lock);
}

void jent_kshim_mutex_unlock(struct mutex *lock)
{
	mutex_unlock(lock);
}

int jent_kshim_copy_from_user(void *dst, const void __user *src, size_t len)
{
	return copy_from_user(dst, src, len) != 0;
}

int jent_kshim_copy_to_user(void __user *dst, const void *src, size_t len)
{
	return copy_to_user(dst, src, len) != 0;
}

int jent_kshim_seq_write(struct seq_file *m, const void *data, size_t len)
{
	return seq_write(m, data, len);
}

void jent_kshim_log(int level, const char *data, size_t len)
{
	switch (level) {
	case 3:
		printk(KERN_ERR "%.*s", (int)len, data);
		break;
	case 2:
		printk(KERN_WARNING "%.*s", (int)len, data);
		break;
	case 1:
		printk(KERN_INFO "%.*s", (int)len, data);
		break;
	default:
		printk(KERN_NOTICE "%.*s\n", (int)len, data);
		break;
	}
}

void __noreturn jent_kshim_panic_init(int ret)
{
	panic("jitterentropy: Initialization failed with host not compliant with requirements: %d\n",
	      ret);
}

void __noreturn jent_kshim_panic_selftest(int ret)
{
	panic("jitterentropy: cryptographic self test failed: %d\n", ret);
}

int jent_kshim_ioctl_kind(unsigned int cmd)
{
	switch (cmd) {
	case JENT_IOCUUID: return 1;
	case JENT_IOCVERSION: return 2;
	case JENT_IOCOSR: return 3;
	case JENT_IOCFLAGS: return 4;
	case JENT_IOCHEALTH: return 5;
	case JENT_IOCOUTPUT: return 6;
	case JENT_IOCREINIT: return 7;
	case JENT_IOCMEMSIZE: return 8;
	case JENT_IOCHASHLOOPS: return 9;
	default: return 0;
	}
}

static void jent_kshim_selftest_work_fn(struct work_struct *work)
{
	struct jent_selftest_instance *st =
		container_of(to_delayed_work(work),
			     struct jent_selftest_instance, work);
	jent_zig_selftest_work(st);
}

void jent_kshim_selftest_setup(struct jent_selftest_instance *st,
			       struct mutex *lock,
			       struct rand_data **ec)
{
	st->lock = lock;
	st->entropy_collector = ec;
	st->failed = false;
	INIT_DELAYED_WORK(&st->work, jent_kshim_selftest_work_fn);
}

struct mutex *jent_kshim_selftest_lock(struct jent_selftest_instance *st)
{
	return st->lock;
}

struct rand_data **jent_kshim_selftest_ec(struct jent_selftest_instance *st)
{
	return st->entropy_collector;
}

bool jent_kshim_selftest_failed(struct jent_selftest_instance *st)
{
	return st->failed;
}

void jent_kshim_selftest_set_failed(struct jent_selftest_instance *st,
				    bool failed)
{
	st->failed = failed;
}

void jent_kshim_selftest_schedule(struct jent_selftest_instance *st,
				  unsigned int seconds)
{
	queue_delayed_work(system_power_efficient_wq, &st->work,
			   (unsigned long)seconds * HZ);
}

void jent_kshim_selftest_cancel(struct jent_selftest_instance *st)
{
	cancel_delayed_work_sync(&st->work);
}

unsigned int jent_kshim_selftest_interval_max(void)
{
	return min_t(unsigned long, 30UL * 24UL * 60UL * 60UL,
		     MAX_JIFFY_OFFSET / HZ);
}

int __init jent_kshim_chardev_init(void) { return jent_chardev_init(); }
void jent_kshim_chardev_exit(void) { jent_chardev_exit(); }

#if !defined(MODULE) && defined(CONFIG_EXTERNAL_JITTERENTROPY_HWRNG)
static bool jent_kshim_hwrng_pending __initdata;
static bool jent_kshim_hwrng_registered;

int __init jent_kshim_hwrng_init(void)
{
	jent_kshim_hwrng_pending = true;
	return 0;
}

void jent_kshim_hwrng_exit(void)
{
	if (jent_kshim_hwrng_registered) {
		jent_hwrng_exit();
		jent_kshim_hwrng_registered = false;
	} else {
		jent_kshim_hwrng_pending = false;
	}
}

static int __init jent_kshim_hwrng_late_init(void)
{
	if (jent_kshim_hwrng_pending) {
		if (jent_hwrng_init())
			pr_warn("jitterentropy: hwrng unavailable, continuing without it\n");
		else
			jent_kshim_hwrng_registered = true;
	}
	return 0;
}
device_initcall_sync(jent_kshim_hwrng_late_init);
#else
int __init jent_kshim_hwrng_init(void) { return jent_hwrng_init(); }
void jent_kshim_hwrng_exit(void) { jent_hwrng_exit(); }
#endif

int __init jent_kshim_kcapi_init(void) { return jent_kcapi_init(); }
void jent_kshim_kcapi_exit(void) { jent_kcapi_exit(); }
int __init jent_kshim_testing_init(void) { return jent_testing_init(); }
void jent_kshim_testing_exit(void) { jent_testing_exit(); }

struct proc_dir_entry *jent_proc_dir;

extern int jent_zig_proc_statistics_show(struct seq_file *m);
extern int jent_zig_proc_version_show(struct seq_file *m);
extern int jent_zig_proc_flags_show(struct seq_file *m);
extern int jent_zig_proc_flags_raw_show(struct seq_file *m);
extern int jent_zig_proc_osr_show(struct seq_file *m);
extern int jent_zig_proc_ntg1_show(struct seq_file *m);
extern int jent_zig_proc_fips_show(struct seq_file *m);
extern int jent_zig_proc_interface_show(struct seq_file *m, unsigned int which);

static int jent_proc_statistics_show(struct seq_file *m, void *v)
{
	return jent_zig_proc_statistics_show(m);
}
static int jent_proc_version_show(struct seq_file *m, void *v)
{
	return jent_zig_proc_version_show(m);
}
static int jent_proc_flags_show(struct seq_file *m, void *v)
{
	return jent_zig_proc_flags_show(m);
}
static int jent_proc_flags_raw_show(struct seq_file *m, void *v)
{
	return jent_zig_proc_flags_raw_show(m);
}
static int jent_proc_osr_show(struct seq_file *m, void *v)
{
	return jent_zig_proc_osr_show(m);
}
static int jent_proc_ntg1_show(struct seq_file *m, void *v)
{
	return jent_zig_proc_ntg1_show(m);
}
static int jent_proc_fips_show(struct seq_file *m, void *v)
{
	return jent_zig_proc_fips_show(m);
}
static int jent_proc_interface_show(struct seq_file *m, void *v)
{
	return jent_zig_proc_interface_show(m, (unsigned long)m->private);
}

unsigned int jent_kshim_interface_enabled(unsigned int which)
{
	switch (which) {
	case 0: return IS_ENABLED(CONFIG_EXTERNAL_JITTERENTROPY_KCAPI);
	case 1: return IS_ENABLED(CONFIG_EXTERNAL_JITTERENTROPY_HWRNG);
	case 2: return IS_ENABLED(CONFIG_EXTERNAL_JITTERENTROPY_CHARDEV);
	case 3: return IS_ENABLED(CONFIG_EXTERNAL_JITTERENTROPY_TESTINTERFACE);
	default: return 0;
	}
}

int jent_kshim_proc_create(void)
{
	struct proc_dir_entry *config, *interfaces;

	if (!IS_ENABLED(CONFIG_PROC_FS))
		return 0;
	jent_proc_dir = proc_mkdir(JENT_PROC_DIRNAME, NULL);
	if (!jent_proc_dir)
		return -ENOMEM;
	if (!proc_create_single("statistics", 0400, jent_proc_dir,
				jent_proc_statistics_show) ||
	    !proc_create_single("version", 0444, jent_proc_dir,
				jent_proc_version_show))
		goto err;
	config = proc_mkdir("config", jent_proc_dir);
	if (!config)
		goto err;
	if (!proc_create_single("flags", 0444, config, jent_proc_flags_show) ||
	    !proc_create_single("flags_raw", 0444, config,
				jent_proc_flags_raw_show) ||
	    !proc_create_single("osr", 0444, config, jent_proc_osr_show) ||
	    !proc_create_single("ntg1", 0444, config, jent_proc_ntg1_show) ||
	    !proc_create_single("fips", 0444, config, jent_proc_fips_show))
		goto err;
	interfaces = proc_mkdir("interfaces", jent_proc_dir);
	if (!interfaces)
		goto err;
	if (!proc_create_single_data("kcapi", 0444, interfaces,
				     jent_proc_interface_show, (void *)0) ||
	    !proc_create_single_data("hwrng", 0444, interfaces,
				     jent_proc_interface_show, (void *)1) ||
	    !proc_create_single_data("chardev", 0444, interfaces,
				     jent_proc_interface_show, (void *)2) ||
	    !proc_create_single_data("testing", 0444, interfaces,
				     jent_proc_interface_show, (void *)3))
		goto err;
	return 0;
err:
	proc_remove(jent_proc_dir);
	jent_proc_dir = NULL;
	return -ENOMEM;
}

void jent_kshim_proc_remove(void)
{
	proc_remove(jent_proc_dir);
	jent_proc_dir = NULL;
}
