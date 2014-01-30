#include "jsmn.h"
#define _XOPEN_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <time.h>


#define DATE_FORMAT "%Y-%m-%d %H:%M:%S"
char *load_file(char *path);

typedef struct group {
    int from;
    int to;
    char *key;
} group;

typedef struct client {
    unsigned char id[24];
    time_t expire;
} client;

group *load_groups(jsmntok_t * tokens, char *data);
client *load_clients(jsmntok_t * tokens, char *data);
void print_clients(FILE *out, client *clients);
int main(int argc, char **argv)
{
    jsmntok_t tokens[1024] = {{0}};
    jsmn_parser parser;
    jsmnerr_t err;
    if (argc < 2)
	return 1;
    char *data = load_file(argv[1]);

    jsmn_init(&parser);
    err = jsmn_parse(&parser, data, tokens, sizeof(tokens));

    if (err != JSMN_SUCCESS)
	    return 1;
	client *clients = load_clients(tokens, data);
int i;

    client p = {"test2",time(NULL)};
    client_insert(clients,&p);
    save_clients("./clients.new",clients);
    rename("./clients.new","./clients");
    
    return 0;
}

group *load_groups(jsmntok_t * tokens, char *data)
{
    group *groups;
    int i, g = 0;
    int total = tokens[0].size;

    if (total <= 0)
	return NULL;

    groups = malloc(total * sizeof(group));
    for (i = 1; i <= total; i++) {
	if (tokens[i].size == 3 && tokens[i].type == JSMN_ARRAY) {
	    /*next three tokens have the group data */
	    groups[g].from = atoi(&data[tokens[i + 1].start]);
	    groups[g].to = atoi(&data[tokens[i + 2].start]);
	    groups[g].key = &data[tokens[i + 3].start];
	    data[tokens[i + 3].end] = '\0';
	    group *gr = &groups[g];
	    g++;
	    printf("%d %d %s\n", gr->from, gr->to, gr->key);
	}
	if (tokens[i].type == JSMN_ARRAY || tokens[i].type == JSMN_OBJECT) {
	    total += tokens[i].size;
	    i += tokens[i].size;
	}
    }

    return groups;
}

client *load_clients(jsmntok_t * tokens, char *data)
{
    client *clients;
    int i, c = 0;
    int total = tokens[0].size;
    struct tm tm;
    if (total <= 0)
	return NULL;
//XXX +100, expand array 
    clients = malloc(total+100 * sizeof(client));
    for (i = 1; i <= total; i++) {
	if (tokens[i].size == 2 && tokens[i].type == JSMN_ARRAY) {
	    
	    size_t idlen = tokens[i + 1].end - tokens[i + 1].start;
	    idlen = idlen > 24-1 ? 24-1 : idlen; 
	    data[tokens[i + 1].start+idlen] = '\0';
	    memcpy(clients[c].id, &data[tokens[i + 1].start],idlen);
	    memset(&tm, 0, sizeof(tm));
	    if (!strptime(&data[tokens[i + 2].start], DATE_FORMAT, &tm))
		clients[c].expire = -1;
	    else
		clients[c].expire = mktime(&tm);
	    c++;
	}
	if (tokens[i].type == JSMN_ARRAY || tokens[i].type == JSMN_OBJECT) {
	    total += tokens[i].size;
	    i += tokens[i].size;
	}
    }
    clients[c].expire = 0;

    return clients;
}

//XXX replace by dynamic array
void client_insert(client *clients, client *newclient) {
int i = 0;
while(clients[i].expire && strcmp((char *)clients[i].id,(char *)newclient->id)) i++;
memcpy(&clients[i],newclient,sizeof(client));
clients[i+1].expire = 0;
}

int save_clients(char *path, client *clients) {
    FILE *out = fopen(path,"w");
    if(!out) 
        return -1;
    print_clients(out,clients);
    fclose(out);
    return 0;
}
void print_clients(FILE *out, client *clients) {
    struct tm tm;
	char buf[256];
	int i = 0;
	fprintf(out,"[\n");
	while(clients[i].expire) {
	gmtime_r(&clients[i].expire, &tm);
	strftime(buf, sizeof(buf), DATE_FORMAT, &tm);
	fprintf(out,"[\"%s\",\"%s\"],\n", clients[i].id, buf);
	i++;
	}
	fprintf(out,"]\n");
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


int save_file(char *path, char *data, size_t size) {
    int fd = open(path,O_CREAT|O_WRONLY|O_TRUNC);
    if (fd == -1) return fd;
    
    if (write(fd,data,size) == size) {
        close(fd);
        return size;
    }
    close(fd);
    return -1;
}

