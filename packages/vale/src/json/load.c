#include <jansson.h>

void main(int argc, char **argv) {
json_t *o;
json_error_t errors;
size_t index;
json_t *value;
o = json_load_file("./test",0,&errors);
if(o != NULL) {
printf("%u\n",(unsigned int)json_array_size(o));
json_array_foreach(o,index,value) {
json_int_t from = json_integer_value(json_object_get(value,"from"));
json_int_t to = json_integer_value(json_object_get(value,"to"));
printf("from %" JSON_INTEGER_FORMAT "to %" JSON_INTEGER_FORMAT "\n",from,to);
}
}
}
