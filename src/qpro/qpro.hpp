#pragma once

/* ProDOS volumes. qpro creates an image, copies files in and out of
   directories, deletes them, and sets the file type and auxiliary type.
   Block size is 512. A path is DIR/FILE, or /VOLUME/DIR/FILE when the
   first component is the volume name. Names are stored in upper case.
   GS/OS extended files (storage type $05) are not read or written. */

#include <cstdint>
#include <string>
#include <vector>

namespace qasm {

struct ProFileInfo {
    std::string name;
    uint8_t storage = 0;
    uint8_t type = 0;
    uint8_t access = 0;
    uint16_t aux = 0;
    uint16_t blocks = 0;
    uint32_t eof = 0;
    uint16_t create_date = 0;
    uint16_t create_time = 0;
    uint16_t mod_date = 0;
    uint16_t mod_time = 0;
    bool directory = false;
};

struct ProVolume {
    std::vector<uint8_t> blocks;
    bool wrapped_2mg = false;
};

/* 140k is 280 blocks, 800k is 1600, 32m is 65535. */
bool pro_parse_size(const std::string &spec, uint16_t &blocks, std::string &err);

bool pro_create(ProVolume &vol, const std::string &name, uint16_t nblocks, std::string &err);
bool pro_load(ProVolume &vol, const std::string &path, std::string &err);
bool pro_save(const ProVolume &vol, const std::string &path, std::string &err);

std::string pro_volume_name(const ProVolume &vol);
uint16_t pro_total_blocks(const ProVolume &vol);
uint16_t pro_free_blocks(const ProVolume &vol);

/* An empty path, "/", or "/VOLUME" is the volume directory.
   A directory lists its entries. A file yields that one entry. */
bool pro_catalog(const ProVolume &vol, const std::string &path,
                 std::vector<ProFileInfo> &out, std::string &err);

bool pro_add(ProVolume &vol, const std::string &path, const std::vector<uint8_t> &data,
             uint8_t type, uint16_t aux, std::string &err);
bool pro_get(const ProVolume &vol, const std::string &path, std::vector<uint8_t> &data,
             std::string &err);
bool pro_mkdir(ProVolume &vol, const std::string &path, std::string &err);
bool pro_remove(ProVolume &vol, const std::string &path, std::string &err);

/* set_type and set_aux select which fields change. At least one must be set. */
bool pro_set_type(ProVolume &vol, const std::string &path, bool set_type, uint8_t type,
                  bool set_aux, uint16_t aux, std::string &err);

/* Write a 1024-byte boot program into blocks 0 and 1. Those blocks are
   already marked used, so the bitmap does not change. */
bool pro_write_boot(ProVolume &vol, const std::vector<uint8_t> &boot, std::string &err);

} // namespace qasm
