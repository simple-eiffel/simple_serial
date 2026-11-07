/*
 * simple_serial_posix.h - serial ports for macOS and Linux, on termios.
 *
 * Timeouts follow the Windows settings in SERIAL_PORT: a read returns when it
 * has `a_max' bytes, when no first byte came within the timeout, or when a
 * started read goes quiet for SSP_INTERVAL_MS.
 *
 * Copyright (c) 2026 Larry Rix - MIT License
 */

#ifndef SIMPLE_SERIAL_POSIX_H
#define SIMPLE_SERIAL_POSIX_H

#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <stdint.h>
#include <string.h>
#include <sys/file.h>
#include <sys/ioctl.h>
#include <termios.h>
#include <unistd.h>

#define SSP_INTERVAL_MS 50

static int ssp_fd(void* a_handle) { return (int) (intptr_t) a_handle; }

/* The port, exclusively, or (void*) -1. O_NONBLOCK keeps the open from waiting
   for carrier detect; it is cleared once open. flock refuses a second open as
   Windows does; TIOCEXCL alone is not honoured by every device. */
static void* ssp_open(const char* a_path)
{
    int l_fd = open(a_path, O_RDWR | O_NOCTTY | O_NONBLOCK);
    int l_flags;
    if (l_fd < 0) return (void*) (intptr_t) -1;
    if (flock(l_fd, LOCK_EX | LOCK_NB) != 0) {
        close(l_fd);
        return (void*) (intptr_t) -1;
    }
    ioctl(l_fd, TIOCEXCL);
    fcntl(l_fd, F_SETFD, FD_CLOEXEC);
    l_flags = fcntl(l_fd, F_GETFL, 0);
    if (l_flags >= 0) fcntl(l_fd, F_SETFL, l_flags & ~O_NONBLOCK);
    return (void*) (intptr_t) l_fd;
}

/* The speed constant for `a_baud', or 0 if there is none. On macOS the
   constants are the numbers themselves. */
static speed_t ssp_speed(int a_baud)
{
#ifdef __APPLE__
    return (speed_t) a_baud;
#else
    switch (a_baud) {
    case 300: return B300;
    case 600: return B600;
    case 1200: return B1200;
    case 2400: return B2400;
    case 4800: return B4800;
    case 9600: return B9600;
    case 19200: return B19200;
    case 38400: return B38400;
    case 57600: return B57600;
    case 115200: return B115200;
    case 230400: return B230400;
#ifdef B460800
    case 460800: return B460800;
#endif
#ifdef B921600
    case 921600: return B921600;
#endif
    default: return 0;
    }
#endif
}

/* `a_stop_bits', `a_parity' and `a_flow' take SERIAL_PORT_CONFIG's numbers,
   which are Windows's. POSIX has no 1.5 stop bits, nor mark or space parity
   in the portable set: those answer 0. 1 on success. */
static int ssp_configure(void* a_handle, int a_baud, int a_data_bits, int a_stop_bits, int a_parity, int a_flow)
{
    struct termios l_settings;
    speed_t l_speed = ssp_speed(a_baud);
    int l_fd = ssp_fd(a_handle);

    if (l_speed == 0 || tcgetattr(l_fd, &l_settings) != 0) return 0;
    cfmakeraw(&l_settings);
    if (cfsetispeed(&l_settings, l_speed) != 0 || cfsetospeed(&l_settings, l_speed) != 0) return 0;

    l_settings.c_cflag |= CLOCAL | CREAD;
    l_settings.c_cflag &= ~(tcflag_t) CSIZE;
    switch (a_data_bits) {
    case 5: l_settings.c_cflag |= CS5; break;
    case 6: l_settings.c_cflag |= CS6; break;
    case 7: l_settings.c_cflag |= CS7; break;
    default: l_settings.c_cflag |= CS8; break;
    }
    if (a_stop_bits == 2) {
        l_settings.c_cflag |= CSTOPB;
    } else if (a_stop_bits == 0) {
        l_settings.c_cflag &= ~(tcflag_t) CSTOPB;
    } else {
        return 0;
    }
    switch (a_parity) {
    case 0: l_settings.c_cflag &= ~(tcflag_t) (PARENB | PARODD); break;
    case 1: l_settings.c_cflag |= PARENB | PARODD; break;
    case 2: l_settings.c_cflag |= PARENB; l_settings.c_cflag &= ~(tcflag_t) PARODD; break;
    default: return 0;
    }
    l_settings.c_cflag &= ~(tcflag_t) CRTSCTS;
    l_settings.c_iflag &= ~(tcflag_t) (IXON | IXOFF | IXANY);
    if (a_flow == 1) {
        l_settings.c_cflag |= CRTSCTS;
    } else if (a_flow == 2) {
        l_settings.c_iflag |= IXON | IXOFF;
        l_settings.c_cc[VSTART] = 0x11;
        l_settings.c_cc[VSTOP] = 0x13;
    }
    l_settings.c_cc[VMIN] = 0;
    l_settings.c_cc[VTIME] = 0;
    return tcsetattr(l_fd, TCSANOW, &l_settings) == 0 ? 1 : 0;
}

/* 1 when `a_fd' is ready for `a_events' within `a_ms', 0 on timeout, -1 on error. */
static int ssp_wait(int a_fd, short a_events, int a_ms)
{
    struct pollfd l_wait;
    int l_result;
    l_wait.fd = a_fd;
    l_wait.events = a_events;
    l_wait.revents = 0;
    do {
        l_result = poll(&l_wait, 1, a_ms);
    } while (l_result < 0 && errno == EINTR);
    return l_result > 0 ? 1 : l_result;
}

/* Bytes read, or -1 on error. A timeout with nothing read answers 0. */
static int ssp_read(void* a_handle, void* a_buffer, int a_max, int a_timeout_ms)
{
    int l_fd = ssp_fd(a_handle);
    int l_total = 0;
    int l_ready;
    ssize_t l_read;

    while (l_total < a_max) {
        l_ready = ssp_wait(l_fd, POLLIN, l_total == 0 ? a_timeout_ms : SSP_INTERVAL_MS);
        if (l_ready < 0) return -1;
        if (l_ready == 0) break;
        l_read = read(l_fd, (char*) a_buffer + l_total, (size_t) (a_max - l_total));
        if (l_read > 0) {
            l_total += (int) l_read;
        } else if (l_read == 0) {
            break;
        } else if (errno != EINTR && errno != EAGAIN) {
            return l_total > 0 ? l_total : -1;
        }
    }
    return l_total;
}

/* Bytes written, or -1 on error. Stops early if the port will not take more
   within the timeout. */
static int ssp_write(void* a_handle, const void* a_buffer, int a_count, int a_timeout_ms)
{
    int l_fd = ssp_fd(a_handle);
    int l_total = 0;
    int l_ready;
    ssize_t l_written;

    while (l_total < a_count) {
        l_ready = ssp_wait(l_fd, POLLOUT, a_timeout_ms);
        if (l_ready < 0) return -1;
        if (l_ready == 0) break;
        l_written = write(l_fd, (const char*) a_buffer + l_total, (size_t) (a_count - l_total));
        if (l_written > 0) {
            l_total += (int) l_written;
        } else if (l_written < 0 && errno != EINTR && errno != EAGAIN) {
            return l_total > 0 ? l_total : -1;
        }
    }
    return l_total;
}

static int ssp_bytes_available(void* a_handle)
{
    int l_count = 0;
    return ioctl(ssp_fd(a_handle), FIONREAD, &l_count) == 0 ? l_count : -1;
}

static void ssp_set_line(void* a_handle, int a_line, int a_state)
{
    ioctl(ssp_fd(a_handle), a_state ? TIOCMBIS : TIOCMBIC, &a_line);
}

static void ssp_set_dtr(void* a_handle, int a_state) { ssp_set_line(a_handle, TIOCM_DTR, a_state); }

static void ssp_set_rts(void* a_handle, int a_state) { ssp_set_line(a_handle, TIOCM_RTS, a_state); }

#endif /* SIMPLE_SERIAL_POSIX_H */
