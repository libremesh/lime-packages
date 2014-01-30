#include "jsmn.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>

char *load_file(char *path);
typedef struct group {
    int from;
    int to;
    char *key;
} group;
    
int main(int argc, char **argv)
{
    jsmntok_t tokens[1024] = {0};
    jsmn_parser parser;
    jsmnerr_t err;
    int i,total,g=0;
    group *groups;
    char *data= load_file(argv[1]);
    
    jsmn_init(&parser);
    err = jsmn_parse(&parser,data,tokens,sizeof(tokens));
    total = tokens[0].size;
    
    if(err != JSMN_SUCCESS || total <= 0) 
        return 1;
        
    groups = malloc(total * sizeof(group));
    printf("total:%d\n",tokens[0].size);
    
    for(i = 1; i < total ;i++) {
    printf("%d\n",tokens[i].size);
       if (tokens[i].size == 3 && tokens[i].type == JSMN_ARRAY) {
        /*next three tokens have the group data*/
         groups[g].from = atoi(&data[tokens[i+1].start]);
         groups[g].to = atoi(&data[tokens[i+2].start]);
         groups[g].key = &data[tokens[i+3].start];
         data[tokens[i+3].end] = '\0';
         group *gr = &groups[g];
         g++;
         printf("%d %d %s\n",gr->from,gr->to,gr->key);
       }
       if (tokens[i].type == JSMN_ARRAY || tokens[i].type == JSMN_OBJECT) {
            total += tokens[i].size;
            i+= tokens[i].size;
        }

    }
}


char *load_file(char *path)
{
    int fd = open(path, O_RDONLY);
    char *buf;
    off_t size;
 
    if (fd == -1)
    	return NULL;
 
    size = lseek(fd, 0, SEEK_END);
    lseek(fd, 0, SEEK_SET);

    buf = malloc(size + 1);
    buf[size] = '\0';
    
    if (read(fd, buf, size) == size) {
        close(fd);
	    return buf;
	}
	
	close(fd);
	free(buf);
    return NULL;
}
