#define _XOPEN_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <time.h>
#include <polarssl/sha1.h>
#include <json/jsmn.h>
#include "vale.h"
unsigned char b32[256] = { 0 };
unsigned char b16[256] = { 0 };

time_t client_timeleft(client * client);
int main(int argc, char **argv)
{
    unsigned char *valebits = NULL;
    unsigned char *key;
    vale *v;

    genb32table();
    genb16table();

    if (argc < 2)
	return 1;

    client *clients = load_clients();
    group *groups = load_groups();
    vale_used *used = load_vale_used();

    if (argc == 3 && b32dec(argv[2], &valebits) == VALE_BITS) {
	v = vale_decode(valebits);
	key = vale_getkey(v, groups);
	if (key != NULL && !vale_isauth(valebits, key) && !vale_used_is(used,argv[2]) ) {
	    client_insertvale(argv[1], v, clients);
        vale_used_insert(used,argv[1],argv[2]);
	}
    }
    
    client *c = client_getbyid(clients, argv[1]);


    printf("%u\n", (unsigned int) client_timeleft(c));
    return 1;
}

void client_insertvale(char *id, vale * v, client * clients)
{
    client c;
    size_t idlen = strlen(id)+1;
    idlen = idlen > 24 - 1 ? 24 - 1 : idlen;
    memcpy(c.id, id, idlen);
    c.id[23] = '\0';
    c.expire = time(NULL) + v->val * 24 * 3600;
    client_insert(clients, &c);
    save_clients("./clients.new",clients);
    rename("./clients.new","./clients");
}

time_t client_timeleft(client * client)
{
    time_t current_time = time(NULL);
    time_t seconds_left;

    if (client == NULL || client->expire < current_time)
	seconds_left = 0;
    else
	seconds_left = client->expire - current_time;
    return seconds_left;
}

unsigned char *vale_getkey(vale * v, group * groups)
{
    int i = 0;

    if (v == NULL || groups == NULL)
	return NULL;

    int group = v->id;

    while (groups[i].from != -1
	   && !(groups[i].from <= group && groups[i].to >= group))
	i++;

    if (groups[i].from != -1) {
	unsigned char *key;
	if (b16dec(groups[i].key, &key) == VALE_KEY_BITS)
	    return key;
	else
	    return (unsigned char *) groups[i].key;
    }
    return NULL;
}

vale *vale_decode(unsigned char *valebits)
{
    vale *v;

    if (valebits == NULL)
	return NULL;

    v = malloc(sizeof(*v));
    v->id = (valebits[0] << 8) | valebits[1];
    v->type = valebits[2] >> 5;
    v->val = ((valebits[2] & 0x1F) << 8) | valebits[3];
    return v;
}
void vale_used_insert(vale_used *used, char *client_id, char *valestr) {
    int i = 0;
    vale_used vale_used;
    while (used[i].when
	   && strcasecmp((char *) used[i].valestr, valestr ))
	i++;
    vale_used.when = time(NULL);
    strncpy(vale_used.client_id,client_id,24);
    vale_used.client_id[24-1] = '\0';
    strncpy(vale_used.valestr,valestr,VALE_CHARS);
    vale_used.valestr[VALE_CHARS-1] = '\0';
    memcpy(&used[i], &vale_used, sizeof(vale_used));
    used[i + 1].when = 0;
    save_vale_used("./vale_used.new",used);
    rename("./vale_used.new","./vale_used");
}

int vale_used_is(vale_used *used, char *valestr) {
    int i = 0;
   while (used[i].when
	   && strcasecmp((char *) used[i].valestr, valestr ))
	i++;
   return(used[i].when);
}
//xxx replace harcoded lengths for variables
int vale_isauth(unsigned char *data, unsigned char *key)
{
    sha1_context ctx;
    unsigned char hmacsha1[20];
    sha1_hmac_starts(&ctx, key, VALE_KEY_BITS / 8);
    sha1_hmac_update(&ctx, data, 4);
    sha1_hmac_finish(&ctx, hmacsha1);
    //28 bits trucated hmac, mask last 4 bits of first 32 bits
    hmacsha1[3] &= 0xF0;
    return memcmp(hmacsha1, &data[4], 4);
}

//clients and config load/save
char *parse_file(char *file, jsmntok_t ** otokens)
{
    jsmntok_t *tokens;
    jsmn_parser parser;
    jsmnerr_t err;

    char *data = load_file(file);
    if (data == NULL)
	return data;

    tokens = malloc(1024 * sizeof(jsmntok_t));
    jsmn_init(&parser);
    err = jsmn_parse(&parser, data, tokens, 1024 * sizeof(jsmntok_t));

    if (err != JSMN_SUCCESS) {
	free(data);
	free(tokens);
	return NULL;
    }

    *otokens = tokens;
    return data;
}

group *load_groups()
{
    group *groups;
    int i, g = 0;
    jsmntok_t *tokens;
    char *data = parse_file("./config", &tokens);
    if (data == NULL)
	return NULL;

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
	}
	if (tokens[i].type == JSMN_ARRAY || tokens[i].type == JSMN_OBJECT) {
	    total += tokens[i].size;
	    i += tokens[i].size;
	}
    }
    //mark the last one
    groups[g].from = -1;
    return groups;
}
vale_used *load_vale_used()
{
    vale_used *used;
    int i, v = 0;
    jsmntok_t *tokens;
    struct tm tm;
    char *data = parse_file("./vale_used",&tokens);
    if (data == NULL)
        return NULL;
        
    int total = tokens[0].size;

    if (total <= 0)
        return NULL;
//XXX +100, expand array 
    used = malloc(total + 100 * sizeof(vale_used));
    for (i = 1; i <= total; i++) {
 	if (tokens[i].size == 3 && tokens[i].type == JSMN_ARRAY) {
	    size_t valelen = tokens[i + 1].end - tokens[i + 1].start;
    	valelen = valelen > VALE_CHARS - 1 ? VALE_CHARS - 1 : valelen;
	    data[tokens[i + 1].start + valelen] = '\0';
	    memcpy(used[v].valestr, &data[tokens[i + 1].start],valelen);

	    size_t idlen = tokens[i + 2].end - tokens[i + 2].start;
	    idlen = idlen > 24 - 1 ? 24 - 1 : idlen;
	    data[tokens[i + 2].start + idlen] = '\0';
	    memcpy(used[v].client_id, &data[tokens[i + 2].start], idlen);

	    memset(&tm, 0, sizeof(tm));
	    if (!strptime(&data[tokens[i + 3].start], DATE_FORMAT, &tm))
		    used[v].when = -1;
	    else
		    used[v].when = mktime(&tm);
	    v++;
	}
	if (tokens[i].type == JSMN_ARRAY || tokens[i].type == JSMN_OBJECT) {
	    total += tokens[i].size;
	    i += tokens[i].size;
	}
    }
    used[v].when = 0;

    return used;
}
client *load_clients()
{
    client *clients;
    int i, c = 0;
    jsmntok_t *tokens;
    struct tm tm;
    char *data = parse_file("./clients", &tokens);
    if (data == NULL)
	return NULL;

    int total = tokens[0].size;

    if (total <= 0)
	    return NULL;
//XXX +100, expand array 
    clients = malloc(total + 100 * sizeof(client));
    for (i = 1; i <= total; i++) {
	if (tokens[i].size == 2 && tokens[i].type == JSMN_ARRAY) {

	    size_t idlen = tokens[i + 1].end - tokens[i + 1].start;
	    idlen = idlen > 24 - 1 ? 24 - 1 : idlen;
	    data[tokens[i + 1].start + idlen] = '\0';
	    memcpy(clients[c].id, &data[tokens[i + 1].start], idlen);
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
void client_insert(client * clients, client * newclient)
{
    int i = 0;
    while (clients[i].expire
	   && strcasecmp((char *) clients[i].id, (char *) newclient->id))
	i++;
    memcpy(&clients[i], newclient, sizeof(client));
    clients[i + 1].expire = 0;
}

client *client_getbyid(client * clients, char *id)
{
    int i = 0;
    while (clients[i].expire && strcasecmp((char *) clients[i].id, id))
	i++;
    if (clients[i].expire)
	return &clients[i];
    return NULL;
}

int save_clients(char *path, client * clients)
{
    FILE *out = fopen(path, "w");
    if (!out)
	return -1;
    print_clients(out, clients);
    fclose(out);
    return 0;
}
int save_vale_used(char *path, vale_used *used) 
{
    FILE *out = fopen(path, "w");
    if (!out)
	    return -1;
    print_vale_used(out, used);
    fclose(out);
    return 0;
}
void print_clients(FILE * out, client * clients)
{
    struct tm tm;
    char buf[256];
    int i = 0;
    if (out == NULL || clients == NULL)
	return;
    fprintf(out, "[\n");
    while (clients[i].expire) {
	    gmtime_r(&clients[i].expire, &tm);
	    strftime(buf, sizeof(buf), DATE_FORMAT, &tm);
	    fprintf(out, "[\"%s\",\"%s\"],\n", clients[i].id, buf);
	    i++;
    }
    fprintf(out, "]\n");
}
void print_vale_used(FILE * out, vale_used * used)
{
    struct tm tm;
    char buf[256];
    int i = 0;
    if (out == NULL || used == NULL)
	return;
    fprintf(out, "[\n");
    while (used[i].when) {
        
	    gmtime_r(&used[i].when, &tm);
	    strftime(buf, sizeof(buf), DATE_FORMAT, &tm);
	    fprintf(out, "[\"%s\",\"%s\",\"%s\"],\n",used[i].valestr,used[i].client_id, buf);
	    i++;
    }
    fprintf(out, "]\n");
}
//xxx move to db.c
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


int save_file(char *path, char *data, size_t size)
{
    int fd = open(path, O_CREAT | O_WRONLY | O_TRUNC);
    if (fd == -1)
	return fd;

    if (write(fd, data, size) == size) {
	close(fd);
	return size;
    }
    close(fd);
    return -1;
}

//xxx move to encoding.c
//xxx replace with fixed table in .h file
void genb32table()
{
    int i = 0;
    memset(b32, 0xFF, sizeof(b32));
    for (i = 0; i < 32; i++) {
	b32[charset[i]] = i;
	if (charset[i] >= 'a' && charset[1] <= 'z')
	    b32[charset[i] ^ 0x20] = i;
    }
    b32['0'] = b32['o'];
    b32['1'] = b32['l'];
    b32['8'] = b32['B'];
    b32['9'] = b32['g'];
}

//xxx replace with fixed table in .h file
void genb16table()
{
    unsigned char c, i;
    memset(b16, 0xFF, sizeof(b16));

    for (i = 0; i < 10; i++) {
	b16['0' + i] = i;
    }

    for (c = 'a'; c <= 'f'; c++) {
	b16[c] = i;
	b16[c ^ 0x20] = i;
	i++;
    }

}

int b32dec(char *in, unsigned char **outp)
{
    unsigned char *p, *out;
    unsigned int outbits = 0;
    size_t outlen = strlen(in) * 5;

    if (!outlen)
	return 0;
    outlen = (outlen + 8) / 8;
    out = malloc(outlen);
    *outp = out;
    memset(out, 0, outlen);
    for (p = (unsigned char *) in; *p; p++) {
	unsigned char fivebits = b32[*p];
	unsigned int emptybits = 8 - outbits % 8;

	if (fivebits >= 32)
	    continue;

	if (emptybits < 5) {
	    *out++ |= fivebits >> (5 - emptybits);
	    emptybits += 8;
	}

	*out |= fivebits << (emptybits - 5);
	outbits += 5;
	if (outbits % 8 == 0)
	    out++;
    }

    return outbits;
}

int b16dec(char *in, unsigned char **outp)
{
    unsigned char *p, *out;
    size_t outlen = strlen(in) / 2;
    if (!outlen)
	return 0;
    out = malloc(outlen);
    *outp = out;
    for (p = (unsigned char *) in; *p && *(p + 1); p++) {
	if (b16[*p] >= 16)
	    continue;
	*out = b16[*p++] << 4;
	*out++ |= b16[*p];
    }
    return (out - *outp) * 8;
}
