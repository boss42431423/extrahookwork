#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <mach-o/loader.h>
#import <mach-o/fat.h>
#import <mach-o/dyld.h>
#import <mach-o/fat.h>
#import <mach-o/loader.h>
#import <mach-o/dyld.h>
#include <mach-o/dyld_images.h>
#import <mach/mach.h>
#import <mach/vm_page_size.h>
#import <mach/mach.h>
#import <mach/task_info.h>
#import <mach/mach_traps.h>
#import <stdio.h>
#import <stdlib.h>
#import <libgen.h>
#import <map>
#import <deque>
#import <vector>
#import <array>
#import <string>
#import <UIKit/UIKit.h>
#include <mach/mach.h>
#include <mach-o/dyld_images.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#import "pid.h"


struct dyld_uuid_info64 {
    mach_vm_address_t    imageLoadAddress;
    uuid_t               imageUUID;
};

struct dyld_image_info64 {
    mach_vm_address_t    imageLoadAddress;
    mach_vm_address_t    imageFilePath;
    mach_vm_size_t       imageFileModDate;
};

struct dyld_all_image_infos64 {
    uint32_t version;
    uint32_t infoArrayCount;
    mach_vm_address_t infoArray;
    dyld_image_notifier  notification;
    bool                 processDetachedFromSharedRegion;
    bool libSystemInitialized;
    mach_vm_address_t            dyldImageLoadAddress;
    mach_vm_address_t            jitInfo;
    mach_vm_address_t            dyldVersion;
    mach_vm_address_t            errorMessage;
    uint64_t                    terminationFlags;
    mach_vm_address_t            coreSymbolicationShmPage;
    uint64_t                    systemOrderFlag;
    uint64_t                    uuidArrayCount;
    mach_vm_address_t            uuidArray;
    mach_vm_address_t            dyldAllImageInfosAddress;
    uint64_t                    initialImageCount;
    uint64_t                    errorKind;
    mach_vm_address_t            errorClientOfDylibPath;
    mach_vm_address_t            errorTargetDylibPath;
    mach_vm_address_t            errorSymbol;
    uint64_t                    sharedCacheSlide;
};



mach_port_t get_task_for_PID(pid_t pid)
{
    mach_port_t task;
    kern_return_t kr = task_for_pid(mach_task_self(), pid, &task);
    if (kr == KERN_SUCCESS)
    {
        return task;
    }
    
    return MACH_PORT_NULL;
}

pid_t get_pid_by_name(const char *keyword)
{
    int count = proc_listallpids(NULL, 0);
    std::vector<pid_t> pids(count);
    proc_listallpids(pids.data(), (int)(pids.size() * sizeof(pid_t)));
    
    for (int i = 0; i < count; i++)
    {
        char name[1000];
        proc_name(pids[i], name, sizeof(name));
        if (strcasestr(name, keyword) != NULL) // Ищем без учета регистра
        {
            return pids[i];
        }
    }
    
    return -1;
}

task_t get_task_by_pid(pid_t pid)
__attribute__((__annotate__("indibran_use_stack bcf_prob=100 bcf_junkasm bcf_junkasm_minnum=3 bcf_junkasm_maxnum=6 constenc constenc_times=2 constenc_subxor constenc_subxor_prob=60 constenc_togv constenc_togv_prob=80 split_num=3 sub_prob=100 strcry_prob=100 adb antihook")))
{
    task_port_t psDefault;
    task_port_t psDefault_control;

    task_array_t tasks;
    mach_msg_type_number_t numTasks;
    kern_return_t kr;

   
    host_t self_host = mach_host_self();
    kr = processor_set_default(self_host, &psDefault);
    if (kr != KERN_SUCCESS)
    {
        fprintf(stderr, "Error in processor_set_default: %x\n", kr);
        return MACH_PORT_NULL;
    }

   
    kr = host_processor_set_priv(self_host, psDefault, &psDefault_control);
    if (kr != KERN_SUCCESS)
    {
        fprintf(stderr, "Error in host_processor_set_priv: %x\n", kr);
        return MACH_PORT_NULL;
    }

  
    kr = processor_set_tasks(psDefault_control, &tasks, &numTasks);
    if (kr != KERN_SUCCESS) {
        fprintf(stderr, "Error in processor_set_tasks: %x\n", kr);
        return MACH_PORT_NULL;
    }

  
    for (int i = 0; i < numTasks; i++)
    {
        int task_pid;
        kr = pid_for_task(tasks[i], &task_pid);
        if (kr != KERN_SUCCESS) {
            continue;
        }

        if (task_pid == pid) return tasks[i];
    }

    return MACH_PORT_NULL;
}

mach_vm_address_t get_image_base_address(mach_port_t task, const char *image_name)
__attribute__((__annotate__("indibran_use_stack bcf_prob=100 bcf_junkasm bcf_junkasm_minnum=3 bcf_junkasm_maxnum=6 constenc constenc_times=2 constenc_subxor constenc_subxor_prob=60 constenc_togv constenc_togv_prob=80 split_num=3 sub_prob=100 strcry_prob=100 adb antihook")))
{
    task_dyld_info_data_t dyld_info;
    mach_msg_type_number_t count = TASK_DYLD_INFO_COUNT;
    kern_return_t kr = task_info(task, TASK_DYLD_INFO, (task_info_t)&dyld_info, &count);
    if (kr != KERN_SUCCESS)
    {
        fprintf(stderr, "task_info failed: %s\n", mach_error_string(kr));
        return 0;
    }

    struct dyld_all_image_infos64 infos;
    vm_size_t size = sizeof(infos);
    mach_msg_type_number_t read_size = 0;
    vm_offset_t read_mem = 0;

    kr = vm_read(task, (vm_address_t)dyld_info.all_image_info_addr, size, &read_mem, &read_size);
    if (kr != KERN_SUCCESS || read_size < sizeof(infos))
    {
        fprintf(stderr, "vm_read for dyld_all_image_infos64 failed: %s\n", mach_error_string(kr));
        return 0;
    }
    memcpy(&infos, (void *)read_mem, sizeof(infos));
    vm_deallocate(mach_task_self(), read_mem, read_size);

    uint32_t image_count = infos.infoArrayCount;
    mach_vm_address_t info_array_addr = infos.infoArray;
    vm_size_t image_info_size = image_count * sizeof(struct dyld_image_info64);
    struct dyld_image_info64 *image_infos = (struct dyld_image_info64 *)malloc(image_info_size);
    if (!image_infos) return 0;

    read_mem = 0;
    read_size = 0;
    kr = vm_read(task, (vm_address_t)info_array_addr, image_info_size, &read_mem, &read_size);
    if (kr != KERN_SUCCESS || read_size < image_info_size)
    {
        fprintf(stderr, "vm_read for image infos failed: %s\n", mach_error_string(kr));
        free(image_infos);
        return 0;
    }
    memcpy(image_infos, (void *)read_mem, image_info_size);
    vm_deallocate(mach_task_self(), read_mem, read_size);

    for (uint32_t i = 0; i < image_count; ++i)
    {
        char path_buffer[PATH_MAX] = {0};
        read_mem = 0;
        read_size = 0;
        kr = vm_read(task, (vm_address_t)image_infos[i].imageFilePath, PATH_MAX, &read_mem, &read_size);
        if (kr == KERN_SUCCESS)
        {
            size_t to_copy = read_size > PATH_MAX ? PATH_MAX : read_size;
            memcpy(path_buffer, (void *)read_mem, to_copy);
            vm_deallocate(mach_task_self(), read_mem, read_size);
        }

        if (kr == KERN_SUCCESS && strstr(path_buffer, image_name))
        {
            mach_vm_address_t base = image_infos[i].imageLoadAddress;
            free(image_infos);
            return base;
        }
    }

    free(image_infos);
    return 0;
}

// ──────────────────────────────────────────────────────────────────────────────
// PlayerManager Il2CppClass* offset scanner
// Searches ±8 MB around the last-known offset for a valid typeInfo chain.
// Runs in a background thread – do NOT call this on the main thread.
// ──────────────────────────────────────────────────────────────────────────────
static inline bool _is_vm_ptr(uint64_t v) {
    return v > 0x1000000ULL && v < 0x1000000000000ULL;
}

static uint64_t _safe64(task_t task, uint64_t addr) {
    if (!_is_vm_ptr(addr)) return 0;
    uint64_t val = 0;
    mach_vm_size_t sz = sizeof(val);
    mach_vm_read_overwrite(task, addr, sizeof(val), (mach_vm_address_t)&val, &sz);
    return val;
}

uint64_t find_pm_typeinfo_offset(task_t task, mach_vm_address_t unity_base) {
    const uint64_t KNOWN_OFF  = 164201496ULL; // 0x9CA0A18 — last known (old version)
    const uint64_t SCAN_RADIUS = 8ULL * 1024 * 1024; // search ±8 MB
    const uint32_t CHUNK_BYTES = 256 * 1024;          // read 256 KB per chunk

    uint64_t scan_start = (KNOWN_OFF > SCAN_RADIUS) ? (KNOWN_OFF - SCAN_RADIUS) : 0;
    scan_start &= ~7ULL; // 8-byte align
    uint64_t scan_end   = KNOWN_OFF + SCAN_RADIUS;

    for (uint64_t off = scan_start; off < scan_end; off += CHUNK_BYTES) {
        vm_offset_t           buf = 0;
        mach_msg_type_number_t cnt = 0;
        if (vm_read(task, unity_base + off, CHUNK_BYTES, &buf, &cnt) != KERN_SUCCESS)
            continue;

        uint32_t  n_words = cnt / 8;
        uint64_t *words   = (uint64_t *)buf;

        for (uint32_t i = 0; i < n_words; i++) {
            uint64_t ti = words[i];
            if (!_is_vm_ptr(ti)) continue;

            // parentTypeInfo = typeInfo->parent  (+0x58 in Il2CppClass)
            uint64_t pt = _safe64(task, ti + 0x58);
            if (!_is_vm_ptr(pt)) continue;

            // staticFields = parent->static_fields  (+0xB8, fallback +0xB0)
            uint64_t sf = _safe64(task, pt + 0xB8);
            if (!_is_vm_ptr(sf)) sf = _safe64(task, pt + 0xB0);
            if (!_is_vm_ptr(sf)) continue;

            // playerManager = *staticFields
            uint64_t pm = _safe64(task, sf);
            if (!_is_vm_ptr(pm)) continue;

            // players dict = playerManager+0x28
            uint64_t dict = _safe64(task, pm + 0x28);
            if (!_is_vm_ptr(dict)) continue;

            // dict must carry a reasonable player count in any of three count slots
            int32_t c18 = 0, c20 = 0, c40 = 0;
            mach_vm_size_t sz = 4;
            mach_vm_read_overwrite(task, dict + 0x18, 4, (mach_vm_address_t)&c18, &sz); sz = 4;
            mach_vm_read_overwrite(task, dict + 0x20, 4, (mach_vm_address_t)&c20, &sz); sz = 4;
            mach_vm_read_overwrite(task, dict + 0x40, 4, (mach_vm_address_t)&c40, &sz);

            bool count_ok = (c18 >= 0 && c18 <= 64) ||
                            (c20 >= 0 && c20 <= 64) ||
                            (c40 >= 0 && c40 <= 64);
            if (!count_ok) continue;

            vm_deallocate(mach_task_self(), buf, cnt);
            return off + (uint64_t)i * 8; // ← found offset
        }

        vm_deallocate(mach_task_self(), buf, cnt);
    }
    return 0; // not found in this scan range
}

