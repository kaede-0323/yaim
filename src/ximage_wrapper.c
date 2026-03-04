#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif


uint32_t* wrap_getXImageData(XImage* img) {
    return (uint32_t*)img->data;
}

Display* wrap_XOpenDisplay(const char* name) {
    return XOpenDisplay(name);
}

Window wrap_XDefaultRootWindow(Display* dpy) {
    return XDefaultRootWindow(dpy);
}

XImage* wrap_XGetImage(Display* dpy, Window win, int x, int y, unsigned int width, unsigned int height, unsigned long plane_mask, int format) {
    return XGetImage(dpy, win, x, y, width, height, plane_mask, format);
}

int wrap_XDestroyImage(XImage* img) {
    return XDestroyImage(img);
}

int wrap_XCloseDisplay(Display* dpy) {
    return XCloseDisplay(dpy);
}

#ifdef __cplusplus
}
#endif
