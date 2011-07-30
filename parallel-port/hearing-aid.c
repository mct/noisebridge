// vim:set ts=4 sw=4 ai:

/*
 * At <https://www.noisebridge.net/pipermail/socialengineering/2011-July/000007.html>,
 * Miloh wrote:
 * 
 *     "Mike Kahn and I fixed up the WYSE box/Door opener to trigger
 *     a parallel input when someone presses the buzzer downstairs.
 *     Right now, /usr/local/bin/open-door just opens the door by
 *     running a high voltage on parallel port pin 6.  Now I need
 *     someone to help me get parallel port 13 to read every 10
 *     seconds for a low (normally high) and get the data to a count
 *     logger, noisedoor, and irc."
 * 
 * This program polls the parallel port status lines every 100ms.
 * When it sees that pin 13 is held low, it prints a timestamp.  It
 * holds an fd open to /dev/parport0 the entire time, but only sets
 * PPCLAIM immediately before each polls, and sets PPRELEASE while
 * sleeping.  Some brief experiments indicate that this behavior does
 * not seem to interfere with the open-door.c program, but it's
 * something we'll want to keep an eye on.
 * 
 *                          -- Michael C. Toren <mct@toren.net>
 *                             Thu Jul 28 16:27:13 PDT 2011
 */

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <err.h>
#include <unistd.h>
#include <linux/ppdev.h>
#include <sys/ioctl.h>
#include <time.h>

#define PIN13 0b10000

char *device = "/dev/parport0";

void buzz()
{
	static time_t last;
	time_t now;
	char buf[1024];

	now = time(NULL);
	if (now > last + 1)
		last = now;
	else
		return;

	strftime(buf, 1024, "%Y-%m-%d %l:%M:%S%P", localtime(&now));
	printf("%s Buzz!\n", buf);
}

int main(int argc, char *argv[])
{
	int fd;
	unsigned char c;
	struct timeval tv;

	setlinebuf(stdout);

	// Kludge, because the wyse don't have a timezone set
	setenv("TZ", "PST8PDT", 1);

	fd = open(device, O_RDONLY|O_NOCTTY);
	if (fd < 0)
		err(1, "open");

	while (1) {
		tv.tv_sec  = 0;
		tv.tv_usec = 1000000/10;
		select(0, NULL, NULL, NULL, &tv);

		if (ioctl(fd, PPCLAIM) < 0) {
			perror("ioctl PPCLAIM");
			continue;
		}

		if (ioctl(fd, PPRSTATUS, &c) < 0)
			err(1, "ioctl PPRSTATUS");
		
		if (ioctl(fd, PPRELEASE) < 0)
			err(1, "ioctl PPRELEASE");
		
		// The doorbell drives the pin low
		if ((c & PIN13) == 0)
			buzz();
	}

	close(fd);
	return 0;
}
