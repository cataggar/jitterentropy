// SPDX-License-Identifier: GPL-2.0 OR BSD-2-Clause

#ifdef CONFIG_EXTERNAL_JITTERENTROPY_KCAPI
#include <crypto/algapi.h>
#include <crypto/internal/rng.h>
#include <linux/cred.h>
#include <linux/err.h>
#include <linux/hash.h>
#include <linux/hashtable.h>
#include <linux/pid_namespace.h>
#include <linux/ratelimit.h>
#include <linux/user_namespace.h>
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
#include <linux/fs.h>
#include <linux/miscdevice.h>
#include <linux/proc_fs.h>
#include <linux/random.h>
#include <linux/sched.h>
#include <linux/seq_file.h>
#include <linux/slab.h>
#include <linux/string.h>
#include <linux/timex.h>
#include <linux/uaccess.h>
#include <linux/workqueue.h>
#ifdef CONFIG_EXTERNAL_JITTERENTROPY_HWRNG
#include <linux/hw_random.h>
#include <linux/version.h>
#endif
#ifdef CONFIG_EXTERNAL_JITTERENTROPY_TESTINTERFACE
#include <linux/debugfs.h>
#include <linux/security.h>
#endif

#include "jitterentropy.h"
#include "jitterentropy_error.h"
#include "jitterentropy_uapi.h"

#define JENT_PROC_DIRNAME "jitterentropy"

struct jent_selftest_instance {
	struct delayed_work work;
	struct mutex *lock;
	struct rand_data **entropy_collector;
	bool failed;
};

extern unsigned int jent_osr;
extern unsigned int jent_flags;
extern unsigned int jent_verbose;
extern bool jent_kparam_ntg1;
extern bool jent_kparam_force_fips;
extern bool jent_kparam_cache_all;
extern unsigned int jent_kparam_max_memsize;
extern unsigned int jent_kparam_selftest_interval;
#ifdef CONFIG_EXTERNAL_JITTERENTROPY_CHARDEV
extern unsigned int jent_kparam_max_instances;
#endif
#ifdef CONFIG_EXTERNAL_JITTERENTROPY_KCAPI
unsigned int jent_kparam_max_kcapi_instances = 256;
#endif
#ifdef CONFIG_EXTERNAL_JITTERENTROPY_HWRNG
extern unsigned int jent_kparam_hwrng_quality;
#endif
#ifdef CONFIG_EXTERNAL_JITTERENTROPY_TESTINTERFACE
extern unsigned int jent_kparam_testing_osr;
extern unsigned int jent_kparam_testing_flags;
#endif

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
#ifdef CONFIG_EXTERNAL_JITTERENTROPY_CHARDEV
module_param_named(max_instances, jent_kparam_max_instances, uint, 0444);
MODULE_PARM_DESC(max_instances, "Maximum concurrent unprivileged /dev/jitterentropy instances (0: unlimited)");
#endif
#ifdef CONFIG_EXTERNAL_JITTERENTROPY_KCAPI
module_param_named(max_kcapi_instances, jent_kparam_max_kcapi_instances, uint, 0444);
MODULE_PARM_DESC(max_kcapi_instances, "Maximum concurrent kernel crypto API instances per unprivileged user and container (0: unlimited)");
#endif
#ifdef CONFIG_EXTERNAL_JITTERENTROPY_HWRNG
module_param_named(hwrng_quality, jent_kparam_hwrng_quality, uint, 0444);
MODULE_PARM_DESC(hwrng_quality, "Jitter RNG hwrng entropy quality (bits per 1024 bits, 0..1024)");
#endif
#ifdef CONFIG_EXTERNAL_JITTERENTROPY_TESTINTERFACE
module_param_named(testing_osr, jent_kparam_testing_osr, uint, 0644);
MODULE_PARM_DESC(testing_osr, "Jitter RNG testing OSR parameter");
module_param_named(testing_flags, jent_kparam_testing_flags, uint, 0644);
MODULE_PARM_DESC(testing_flags, "Jitter RNG testing flags parameter");
#endif

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
size_t jent_kshim_copy_to_user_count(void __user *dst, const void *src,
				     size_t len);
void jent_kshim_mutex_init(struct mutex *lock);
void jent_kshim_mutex_destroy(struct mutex *lock);
bool jent_kshim_mutex_trylock(struct mutex *lock);
bool jent_kshim_signal_pending(void);
bool jent_kshim_need_resched(void);
void jent_kshim_cond_resched(void);
bool jent_kshim_capable_admin(void);
bool jent_kshim_capable_resource(void);
int jent_kshim_map_read_error(ssize_t ret, bool user);
void jent_kshim_memzero(void *ptr, size_t len);
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

size_t jent_kshim_copy_to_user_count(void __user *dst, const void *src,
				     size_t len)
{
	return copy_to_user(dst, src, len);
}

void jent_kshim_mutex_init(struct mutex *lock) { mutex_init(lock); }
void jent_kshim_mutex_destroy(struct mutex *lock) { mutex_destroy(lock); }
bool jent_kshim_mutex_trylock(struct mutex *lock) { return mutex_trylock(lock); }
bool jent_kshim_signal_pending(void) { return signal_pending(current); }
bool jent_kshim_need_resched(void) { return need_resched(); }
void jent_kshim_cond_resched(void) { cond_resched(); }
bool jent_kshim_capable_admin(void) { return capable(CAP_SYS_ADMIN); }
bool jent_kshim_capable_resource(void) { return capable(CAP_SYS_RESOURCE); }
int jent_kshim_map_read_error(ssize_t ret, bool user)
{
	return user ? jent_map_user_read_error(ret) : jent_map_read_error(ret);
}
void jent_kshim_memzero(void *ptr, size_t len) { memzero_explicit(ptr, len); }

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
	case JENT_IOCSTATUS: return 10;
	case JENT_IOCLOOPCNT: return 11;
	case JENT_IOCUUID: return 1;
	case JENT_IOCVERSION: return 2;
	case JENT_IOCOSR: return 3;
	case JENT_IOCFLAGS: return 4;
	case JENT_IOCHEALTH: return 5;
	case JENT_IOCOUTPUT: return 6;
	case JENT_IOCREINIT: return 7;
	case JENT_IOCMEMSIZE: return 8;
	case JENT_IOCHASHLOOPS: return 9;
	case JENT_IOCSELFTEST: return 12;
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

struct proc_dir_entry *jent_proc_dir;

#ifdef CONFIG_EXTERNAL_JITTERENTROPY_CHARDEV
struct jent_chardev_ctx {
	struct mutex lock;
	struct rand_data *entropy_collector;
	struct proc_dir_entry *proc;
	struct jent_selftest_instance selftest;
};
struct jent_chardev_ctx *jent_kshim_chardev_ctx_alloc(void);
void jent_kshim_chardev_ctx_free(struct jent_chardev_ctx *ctx);
struct mutex *jent_kshim_chardev_lock(struct jent_chardev_ctx *ctx);
struct rand_data **jent_kshim_chardev_ec(struct jent_chardev_ctx *ctx);
struct jent_selftest_instance *jent_kshim_chardev_selftest(
	struct jent_chardev_ctx *ctx);
struct jent_chardev_ctx *jent_kshim_chardev_file_ctx(struct file *file);
void jent_kshim_chardev_file_set_ctx(struct file *file,
				     struct jent_chardev_ctx *ctx);
bool jent_kshim_file_nonblock(struct file *file);
void jent_kshim_chardev_proc_create(struct jent_chardev_ctx *ctx,
				    const char *name);
void jent_kshim_chardev_proc_remove(struct jent_chardev_ctx *ctx);
int jent_kshim_chardev_register(void);
void jent_kshim_chardev_unregister(void);

extern int jent_zig_chardev_open(struct file *file);
extern int jent_zig_chardev_release(struct file *file);
extern ssize_t jent_zig_chardev_read(struct file *file, void __user *buf,
				     size_t len);
extern long jent_zig_chardev_ioctl(struct file *file, unsigned int cmd,
				   void __user *arg);

static int jent_chardev_open(struct inode *inode, struct file *file)
{
	return jent_zig_chardev_open(file);
}
static int jent_chardev_release(struct inode *inode, struct file *file)
{
	return jent_zig_chardev_release(file);
}
static ssize_t jent_chardev_read(struct file *file, char __user *buf,
				 size_t len, loff_t *ppos)
{
	return jent_zig_chardev_read(file, buf, len);
}
static long jent_chardev_ioctl(struct file *file, unsigned int cmd,
			       unsigned long arg)
{
	return jent_zig_chardev_ioctl(file, cmd, (void __user *)arg);
}
static const struct file_operations jent_chardev_fops = {
	.owner = THIS_MODULE,
	.open = jent_chardev_open,
	.release = jent_chardev_release,
	.read = jent_chardev_read,
	.unlocked_ioctl = jent_chardev_ioctl,
	.compat_ioctl = compat_ptr_ioctl,
};
static struct miscdevice jent_chardev_misc = {
	.minor = MISC_DYNAMIC_MINOR,
	.name = "jitterentropy",
	.fops = &jent_chardev_fops,
	.mode = 0444,
};
static struct proc_dir_entry *jent_chardev_proc_dir;
static bool jent_chardev_registered;

static int jent_chardev_status_show(struct seq_file *m, void *v)
{
	struct jent_chardev_ctx *ctx = m->private;
	extern int jent_status_seq_show(struct seq_file *, struct mutex *,
					struct rand_data **);
	return jent_status_seq_show(m, &ctx->lock, &ctx->entropy_collector);
}

struct jent_chardev_ctx *jent_kshim_chardev_ctx_alloc(void)
{
	struct jent_chardev_ctx *ctx = kvzalloc(sizeof(*ctx), GFP_KERNEL_ACCOUNT);
	if (ctx)
		mutex_init(&ctx->lock);
	return ctx;
}
void jent_kshim_chardev_ctx_free(struct jent_chardev_ctx *ctx)
{
	mutex_destroy(&ctx->lock);
	kvfree(ctx);
}
struct mutex *jent_kshim_chardev_lock(struct jent_chardev_ctx *ctx)
{
	return &ctx->lock;
}
struct rand_data **jent_kshim_chardev_ec(struct jent_chardev_ctx *ctx)
{
	return &ctx->entropy_collector;
}
struct jent_selftest_instance *jent_kshim_chardev_selftest(
	struct jent_chardev_ctx *ctx)
{
	return &ctx->selftest;
}
struct jent_chardev_ctx *jent_kshim_chardev_file_ctx(struct file *file)
{
	return file->private_data;
}
void jent_kshim_chardev_file_set_ctx(struct file *file,
				     struct jent_chardev_ctx *ctx)
{
	file->private_data = ctx;
}
bool jent_kshim_file_nonblock(struct file *file)
{
	return file->f_flags & O_NONBLOCK;
}
void jent_kshim_chardev_proc_create(struct jent_chardev_ctx *ctx,
				    const char *name)
{
	if (jent_chardev_proc_dir)
		ctx->proc = proc_create_single_data(name, 0400,
			jent_chardev_proc_dir, jent_chardev_status_show, ctx);
}
void jent_kshim_chardev_proc_remove(struct jent_chardev_ctx *ctx)
{
	proc_remove(ctx->proc);
	ctx->proc = NULL;
}
int jent_kshim_chardev_register(void)
{
	int ret;
	if (jent_proc_dir)
		jent_chardev_proc_dir = proc_mkdir_mode("instances", 0500,
						       jent_proc_dir);
	ret = misc_register(&jent_chardev_misc);
	if (ret) {
		proc_remove(jent_chardev_proc_dir);
		jent_chardev_proc_dir = NULL;
		return ret;
	}
	jent_chardev_registered = true;
	return 0;
}
void jent_kshim_chardev_unregister(void)
{
	if (jent_chardev_registered) {
		misc_deregister(&jent_chardev_misc);
		jent_chardev_registered = false;
	}
	proc_remove(jent_chardev_proc_dir);
	jent_chardev_proc_dir = NULL;
}
#endif

#ifdef CONFIG_EXTERNAL_JITTERENTROPY_HWRNG
struct jent_hwrng_ctx {
	struct mutex lock;
	struct rand_data *entropy_collector;
	struct jent_selftest_instance selftest;
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 2, 0)
	bool promotion_reported;
#endif
};
struct jent_hwrng_ctx *jent_kshim_hwrng_ctx(void);
struct mutex *jent_kshim_hwrng_lock(struct jent_hwrng_ctx *ctx);
struct rand_data **jent_kshim_hwrng_ec(struct jent_hwrng_ctx *ctx);
struct jent_selftest_instance *jent_kshim_hwrng_selftest(
	struct jent_hwrng_ctx *ctx);
int jent_kshim_hwrng_register(unsigned int quality);
void jent_kshim_hwrng_unregister(void);
void jent_kshim_hwrng_report_promotion(void);
static struct jent_hwrng_ctx jent_hwrng_ctx;
static struct proc_dir_entry *jent_hwrng_proc;
static bool jent_hwrng_registered;
#if !defined(MODULE)
static bool jent_hwrng_pending;
#endif

extern int jent_zig_hwrng_read(struct jent_hwrng_ctx *, void *, size_t, bool);
extern int jent_status_seq_show(struct seq_file *, struct mutex *,
				struct rand_data **);
static int jent_hwrng_read(struct hwrng *rng, void *data, size_t max, bool wait)
{
	return jent_zig_hwrng_read(&jent_hwrng_ctx, data, max, wait);
}
static struct hwrng jent_hwrng = {
	.name = "jitterentropy",
	.read = jent_hwrng_read,
};
static int jent_hwrng_status_show(struct seq_file *m, void *v)
{
	return jent_status_seq_show(m, &jent_hwrng_ctx.lock,
				    &jent_hwrng_ctx.entropy_collector);
}
struct jent_hwrng_ctx *jent_kshim_hwrng_ctx(void) { return &jent_hwrng_ctx; }
struct mutex *jent_kshim_hwrng_lock(struct jent_hwrng_ctx *ctx)
{
	return &ctx->lock;
}
struct rand_data **jent_kshim_hwrng_ec(struct jent_hwrng_ctx *ctx)
{
	return &ctx->entropy_collector;
}
struct jent_selftest_instance *jent_kshim_hwrng_selftest(
	struct jent_hwrng_ctx *ctx)
{
	return &ctx->selftest;
}
static int jent_hwrng_register_now(void)
{
	int ret;
	ret = hwrng_register(&jent_hwrng);
	if (ret)
		return ret;
	jent_hwrng_registered = true;
	if (jent_proc_dir)
		jent_hwrng_proc = proc_create_single("hwrng_status", 0400,
			jent_proc_dir, jent_hwrng_status_show);
	return 0;
}
void jent_kshim_hwrng_report_promotion(void)
{
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 2, 0)
	unsigned short quality = READ_ONCE(jent_hwrng.quality);

	if (jent_kparam_hwrng_quality || !quality ||
	    jent_hwrng_ctx.promotion_reported)
		return;
	jent_hwrng_ctx.promotion_reported = true;
	pr_notice("jitterentropy: hwrng_quality=0 promoted to effective quality %u by the hw_random core\n",
		  quality);
#endif
}
int jent_kshim_hwrng_register(unsigned int quality)
{
	jent_hwrng.quality = min_t(unsigned int, quality, 1024);
#if !defined(MODULE)
	jent_hwrng_pending = true;
	return 0;
#else
	return jent_hwrng_register_now();
#endif
}
void jent_kshim_hwrng_unregister(void)
{
	proc_remove(jent_hwrng_proc);
	jent_hwrng_proc = NULL;
	if (jent_hwrng_registered) {
		hwrng_unregister(&jent_hwrng);
		jent_hwrng_registered = false;
	}
#if !defined(MODULE)
	jent_hwrng_pending = false;
#endif
}
#if !defined(MODULE)
static int __init jent_hwrng_late_init(void)
{
	if (jent_hwrng_pending) {
		if (jent_hwrng_register_now()) {
			pr_warn("jitterentropy: hwrng unavailable, continuing without it\n");
		} else {
			mutex_lock(&jent_hwrng_ctx.lock);
			jent_kshim_hwrng_report_promotion();
			mutex_unlock(&jent_hwrng_ctx.lock);
		}
	}
	return 0;
}
device_initcall_sync(jent_hwrng_late_init);
#endif
#endif

#ifdef CONFIG_EXTERNAL_JITTERENTROPY_KCAPI
struct jent_kcapi_user {
	struct hlist_node node;
	kuid_t uid;
	struct pid_namespace *pid_ns;
	unsigned int count;
};
static DEFINE_HASHTABLE(jent_kcapi_users, 6);
static DEFINE_MUTEX(jent_kcapi_users_lock);

struct jent_kcapi_ctx {
	struct mutex lock;
	struct rand_data *entropy_collector;
	struct jent_kcapi_user *user;
	struct jent_selftest_instance selftest;
};
struct mutex *jent_kshim_kcapi_lock(struct jent_kcapi_ctx *ctx);
struct rand_data **jent_kshim_kcapi_ec(struct jent_kcapi_ctx *ctx);
struct jent_selftest_instance *jent_kshim_kcapi_selftest(
	struct jent_kcapi_ctx *ctx);
bool jent_kshim_kcapi_log_allowed(void);
int jent_kshim_kcapi_register(void);
void jent_kshim_kcapi_unregister(void);

static unsigned long jent_kcapi_user_hash(kuid_t uid,
					  struct pid_namespace *pid_ns)
{
	return __kuid_val(uid) ^ hash_ptr(pid_ns, 32);
}

static kuid_t jent_kcapi_charged_uid(void)
{
	struct user_namespace *ns;
	kuid_t uid = current_uid();

	for (ns = current_user_ns(); ns != &init_user_ns; ns = ns->parent)
		if (!uid_eq(ns->owner, GLOBAL_ROOT_UID))
			uid = ns->owner;
	return uid;
}

static struct pid_namespace *jent_kcapi_charged_pid_ns(void)
{
	struct pid_namespace *ns = task_active_pid_ns(current);
	struct pid_namespace *charged = &init_pid_ns;

	for (; ns && ns != &init_pid_ns; ns = ns->parent)
		if (ns->user_ns == &init_user_ns)
			charged = ns;
	return charged;
}

static struct jent_kcapi_user *jent_kcapi_instance_get(void)
{
	struct pid_namespace *pid_ns = jent_kcapi_charged_pid_ns();
	kuid_t uid = jent_kcapi_charged_uid();
	unsigned long key = jent_kcapi_user_hash(uid, pid_ns);
	struct jent_kcapi_user *user;

	mutex_lock(&jent_kcapi_users_lock);
	hash_for_each_possible(jent_kcapi_users, user, node, key)
		if (uid_eq(user->uid, uid) && user->pid_ns == pid_ns)
			goto found;
	user = kzalloc(sizeof(*user), GFP_KERNEL);
	if (!user) {
		mutex_unlock(&jent_kcapi_users_lock);
		return ERR_PTR(-ENOMEM);
	}
	user->uid = uid;
	user->pid_ns = get_pid_ns(pid_ns);
	hash_add(jent_kcapi_users, &user->node, key);
found:
	if (jent_kparam_max_kcapi_instances &&
	    user->count >= jent_kparam_max_kcapi_instances &&
	    !capable(CAP_SYS_RESOURCE)) {
		mutex_unlock(&jent_kcapi_users_lock);
		return ERR_PTR(-ENFILE);
	}
	user->count++;
	mutex_unlock(&jent_kcapi_users_lock);
	return user;
}
static void jent_kcapi_instance_put(struct jent_kcapi_user *user)
{
	struct pid_namespace *pid_ns = NULL;
	mutex_lock(&jent_kcapi_users_lock);
	if (!--user->count) {
		hash_del(&user->node);
		pid_ns = user->pid_ns;
		kfree(user);
	}
	mutex_unlock(&jent_kcapi_users_lock);
	if (pid_ns)
		put_pid_ns(pid_ns);
}

extern int jent_zig_kcapi_tfm_init(struct jent_kcapi_ctx *);
extern void jent_zig_kcapi_tfm_cleanup(struct jent_kcapi_ctx *);
extern int jent_zig_kcapi_random(struct jent_kcapi_ctx *, void *,
				 unsigned int);

static int jent_kcapi_tfm_init(struct crypto_tfm *tfm)
{
	struct jent_kcapi_ctx *ctx = crypto_tfm_ctx(tfm);
	int ret;
	ctx->user = jent_kcapi_instance_get();
	if (IS_ERR(ctx->user))
		return PTR_ERR(ctx->user);
	mutex_init(&ctx->lock);
	ret = jent_zig_kcapi_tfm_init(ctx);
	if (ret) {
		mutex_destroy(&ctx->lock);
		jent_kcapi_instance_put(ctx->user);
	}
	return ret;
}
static void jent_kcapi_tfm_cleanup(struct crypto_tfm *tfm)
{
	struct jent_kcapi_ctx *ctx = crypto_tfm_ctx(tfm);
	jent_zig_kcapi_tfm_cleanup(ctx);
	mutex_destroy(&ctx->lock);
	jent_kcapi_instance_put(ctx->user);
}
static int jent_kcapi_random(struct crypto_rng *tfm, const u8 *src,
			     unsigned int slen, u8 *dst, unsigned int dlen)
{
	return jent_zig_kcapi_random(crypto_rng_ctx(tfm), dst, dlen);
}
static int jent_kcapi_reset(struct crypto_rng *tfm, const u8 *seed,
			    unsigned int slen)
{
	return 0;
}
static struct rng_alg jent_alg = {
	.generate = jent_kcapi_random,
	.seed = jent_kcapi_reset,
	.seedsize = 0,
	.base = {
#ifdef CONFIG_BUILTIN_JITTERENTROPY
		.cra_name = "jitterentropy_rng",
		.cra_driver_name = "jitterentropy_rng",
#else
		.cra_name = "jitter_rng",
		.cra_driver_name = "jitter_rng",
#endif
		.cra_priority = 100,
		.cra_ctxsize = sizeof(struct jent_kcapi_ctx),
		.cra_module = THIS_MODULE,
		.cra_init = jent_kcapi_tfm_init,
		.cra_exit = jent_kcapi_tfm_cleanup,
	}
};
struct mutex *jent_kshim_kcapi_lock(struct jent_kcapi_ctx *ctx)
{
	return &ctx->lock;
}
struct rand_data **jent_kshim_kcapi_ec(struct jent_kcapi_ctx *ctx)
{
	return &ctx->entropy_collector;
}
struct jent_selftest_instance *jent_kshim_kcapi_selftest(
	struct jent_kcapi_ctx *ctx)
{
	return &ctx->selftest;
}
bool jent_kshim_kcapi_log_allowed(void)
{
	static DEFINE_RATELIMIT_STATE(rs, DEFAULT_RATELIMIT_INTERVAL,
				      DEFAULT_RATELIMIT_BURST);
	return __ratelimit(&rs);
}
int jent_kshim_kcapi_register(void) { return crypto_register_rng(&jent_alg); }
void jent_kshim_kcapi_unregister(void) { crypto_unregister_rng(&jent_alg); }
#endif

#ifdef CONFIG_EXTERNAL_JITTERENTROPY_TESTINTERFACE
struct jent_testing_ctx {
	void *record;
	struct rand_data *entropy_collector;
	u64 loop_count;
};
struct mutex *jent_kshim_testing_lock(void);
bool jent_kshim_testing_locked_down(void);
struct jent_testing_ctx *jent_kshim_testing_ctx_alloc(void);
void jent_kshim_testing_ctx_free(struct jent_testing_ctx *ctx);
struct jent_testing_ctx *jent_kshim_testing_file_ctx(struct file *file);
void jent_kshim_testing_file_set_ctx(struct file *file,
				     struct jent_testing_ctx *ctx);
void **jent_kshim_testing_record(struct jent_testing_ctx *ctx);
struct rand_data **jent_kshim_testing_ec(struct jent_testing_ctx *ctx);
u64 *jent_kshim_testing_loop_count(struct jent_testing_ctx *ctx);
int jent_kshim_testing_register(void);
void jent_kshim_testing_unregister(void);
static DEFINE_MUTEX(jent_testing_lock);
static struct dentry *jent_testing_root;

extern int jent_zig_testing_open(struct file *);
extern int jent_zig_testing_release(struct file *);
extern ssize_t jent_zig_testing_read(struct file *, void __user *, size_t,
				     loff_t *);
extern long jent_zig_testing_ioctl(struct file *, unsigned int, void __user *);

static int jent_testing_open(struct inode *inode, struct file *file)
{
	return jent_zig_testing_open(file);
}
static int jent_testing_release(struct inode *inode, struct file *file)
{
	return jent_zig_testing_release(file);
}
static ssize_t jent_testing_read(struct file *file, char __user *buf,
				 size_t len, loff_t *ppos)
{
	struct dentry *dentry = file->f_path.dentry;
	ssize_t ret = debugfs_file_get(dentry);
	if (ret)
		return ret;
	ret = jent_zig_testing_read(file, buf, len, ppos);
	debugfs_file_put(dentry);
	return ret;
}
static long jent_testing_ioctl(struct file *file, unsigned int cmd,
			       unsigned long arg)
{
	struct dentry *dentry = file->f_path.dentry;
	long ret = debugfs_file_get(dentry);
	if (ret)
		return ret;
	ret = jent_zig_testing_ioctl(file, cmd, (void __user *)arg);
	debugfs_file_put(dentry);
	return ret;
}
static const struct file_operations jent_testing_fops = {
	.owner = THIS_MODULE,
	.open = jent_testing_open,
	.release = jent_testing_release,
	.read = jent_testing_read,
	.unlocked_ioctl = jent_testing_ioctl,
	.compat_ioctl = compat_ptr_ioctl,
};
struct mutex *jent_kshim_testing_lock(void) { return &jent_testing_lock; }
bool jent_kshim_testing_locked_down(void)
{
	return security_locked_down(LOCKDOWN_DEBUGFS) != 0;
}
struct jent_testing_ctx *jent_kshim_testing_ctx_alloc(void)
{
	return kvzalloc(sizeof(struct jent_testing_ctx), GFP_KERNEL_ACCOUNT);
}
void jent_kshim_testing_ctx_free(struct jent_testing_ctx *ctx) { kvfree(ctx); }
struct jent_testing_ctx *jent_kshim_testing_file_ctx(struct file *file)
{
	return file->private_data;
}
void jent_kshim_testing_file_set_ctx(struct file *file,
				     struct jent_testing_ctx *ctx)
{
	file->private_data = ctx;
}
void **jent_kshim_testing_record(struct jent_testing_ctx *ctx)
{
	return &ctx->record;
}
struct rand_data **jent_kshim_testing_ec(struct jent_testing_ctx *ctx)
{
	return &ctx->entropy_collector;
}
u64 *jent_kshim_testing_loop_count(struct jent_testing_ctx *ctx)
{
	return &ctx->loop_count;
}
int jent_kshim_testing_register(void)
{
	struct dentry *file;
	if (!IS_ENABLED(CONFIG_DEBUG_FS) || jent_kshim_testing_locked_down())
		return 0;
	jent_testing_root = debugfs_create_dir(KBUILD_MODNAME, NULL);
	if (IS_ERR(jent_testing_root)) {
		int ret = PTR_ERR(jent_testing_root);
		jent_testing_root = NULL;
		return ret == -EPERM || ret == -ENOENT ? 0 : ret;
	}
	file = debugfs_create_file_unsafe("jent_raw_hires", 0400,
		jent_testing_root, NULL, &jent_testing_fops);
	if (IS_ERR(file)) {
		int ret = PTR_ERR(file);
		debugfs_remove_recursive(jent_testing_root);
		jent_testing_root = NULL;
		return ret;
	}
	return 0;
}
void jent_kshim_testing_unregister(void)
{
	debugfs_remove_recursive(jent_testing_root);
	jent_testing_root = NULL;
}
#endif

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
