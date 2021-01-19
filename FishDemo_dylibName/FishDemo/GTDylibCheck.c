//
//  GTDylibCheck.c
//  FishDemo
//
//  Created by ak on 2021/1/19.
//

#include "GTDylibCheck.h"
#import <stdio.h>
#import <dlfcn.h>
#import <stdlib.h>
#import <string.h>
#import <sys/types.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <mach-o/nlist.h>
#ifdef __LP64__
typedef struct mach_header_64 mach_header_t;
typedef struct segment_command_64 segment_command_t;
typedef struct section_64 section_t;
typedef struct nlist_64 nlist_t;
#define LC_SEGMENT_ARCH_DEPENDENT LC_SEGMENT_64
#else
typedef struct mach_header mach_header_t;
typedef struct segment_command segment_command_t;
typedef struct section section_t;
typedef struct nlist nlist_t;
#define LC_SEGMENT_ARCH_DEPENDENT LC_SEGMENT
#endif
#ifndef SEG_DATA_CONST
#define SEG_DATA_CONST  "__DATA_CONST"
#endif


static char *gt_checkname = NULL;
static int gt_hasfind = 0;

static void gt_check_symbols_for_image(const struct mach_header *header,
                                    intptr_t slide) {
  if (gt_hasfind == 1) {
    return;
  }
  Dl_info info;
  if (dladdr(header, &info) == 0) {
    return;
  }
  //printf("---->filetype:%d",header->filetype);
  if (header->filetype != MH_EXECUTE) {
    return;
  }
  struct load_command *cur_load_cmd;
  uintptr_t cur = (uintptr_t)header + sizeof(mach_header_t);
  for (uint i = 0; i < header->ncmds; i++, cur += cur_load_cmd->cmdsize) {
    cur_load_cmd = (struct load_command *)cur;
    switch (cur_load_cmd->cmd) {
      case LC_LOAD_DYLIB:
        //      case LC_LOAD_WEAK_DYLIB:
        //      case LC_REEXPORT_DYLIB:
        //      case LC_LOAD_UPWARD_DYLIB:
        //      case LC_LAZY_LOAD_DYLIB:
      {
        if ((header->flags & MH_TWOLEVEL) == 0) {
          break;
        }
        struct dylib_command *dylib_cmd = (struct dylib_command *)cur_load_cmd;
        char *dylib = (char *)(cur + dylib_cmd->dylib.name.offset);
        //printf("%s\n", dylib);//akak 输出动态库名称
        if (strcmp(gt_checkname, dylib) == 0) {
          gt_hasfind = 1;
        }
        break;
      }
      default:
        break;
    }
  }
}

static void _gt_check_symbols_for_image(const struct mach_header *header,
                                     intptr_t slide) {
  gt_check_symbols_for_image(header, slide);
}

int gt_has_dylib_name(char *name) {
  if (name!=NULL && gt_checkname!=NULL && strcmp(name, gt_checkname) == 0) {
    return gt_hasfind;
  }
  gt_hasfind = 0;
  if (gt_checkname == NULL) {
    gt_checkname = name;
    _dyld_register_func_for_add_image(_gt_check_symbols_for_image);
  }
  else {
    gt_checkname = name;
    uint32_t c = _dyld_image_count();
    for (uint32_t i = 0; i < c; i++) {
      _gt_check_symbols_for_image(_dyld_get_image_header(i), _dyld_get_image_vmaddr_slide(i));
    }
  }
  return gt_hasfind;
}
