/*
 * serial_test_support.h - a pseudo-terminal pair, standing in for a serial
 * line in simple_serial's tests. Off Windows only; tests only.
 *
 * Copyright (c) 2026 Larry Rix - MIT License
 */

#ifndef SERIAL_TEST_SUPPORT_H
#define SERIAL_TEST_SUPPORT_H

#if defined(_WIN32) || defined(EIF_WINDOWS)

static int sts_open_master(void) { return -1; }
static const char* sts_slave_name(int a_fd) { (void) a_fd; return ""; }
static int sts_write(int a_fd, const char* a_data, int a_count) { (void) a_fd; (void) a_data; (void) a_count; return -1; }
static int sts_read(int a_fd, char* a_buffer, int a_max, int a_timeout_ms) { (void) a_fd; (void) a_buffer; (void) a_max; (void) a_timeout_ms; return -1; }
static void sts_close(int a_fd) { (void) a_fd; }

#else

#include <fcntl.h>
#include <poll.h>
#include <stdlib.h>
#include <termios.h>
#include <unistd.h>

static int sts_open_master(void)
{
    int l_fd = posix_openpt(O_RDWR | O_NOCTTY);
    struct termios l_settings;
    if (l_fd < 0) return -1;
    if (grantpt(l_fd) != 0 || unlockpt(l_fd) != 0) {
        close(l_fd);
        return -1;
    }
    if (tcgetattr(l_fd, &l_settings) == 0) {
        cfmakeraw(&l_settings);
        tcsetattr(l_fd, TCSANOW, &l_settings);
    }
    return l_fd;
}

static const char* sts_slave_name(int a_fd) { return ptsname(a_fd); }

static int sts_write(int a_fd, const char* a_data, int a_count) { return (int) write(a_fd, a_data, (size_t) a_count); }

static int sts_read(int a_fd, char* a_buffer, int a_max, int a_timeout_ms)
{
    struct pollfd l_wait;
    l_wait.fd = a_fd;
    l_wait.events = POLLIN;
    l_wait.revents = 0;
    if (poll(&l_wait, 1, a_timeout_ms) <= 0) return 0;
    return (int) read(a_fd, a_buffer, (size_t) a_max);
}

static void sts_close(int a_fd) { close(a_fd); }

#endif

#endif /* SERIAL_TEST_SUPPORT_H */
