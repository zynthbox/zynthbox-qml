# Core Isolation Layout for Zynthbox

The intention here is to ensure we have as much space available to the DSP as
we can reasonably get away with. The primary issue is that the UI can
potentially be very heavy, and so we optimally want to ensure there is only the
one core used for that, but also we want to ensure the most rapid bootup time,
and so during bootup we ensure we give it all cores by default, and once
startup is completed, we change the affinity at runtime to be core 3 only.

We do not perform core isolation at the kernel level, because basically we don't
really need that. (we may later switch to a realtime kernel, but for now the
ultra low latency kernel seems to work)

On bootup, we have systemd set to do everything on cores 0, 1, and 2, by adding
the line

`CPUAffinity=0 1 2`

to `/etc/systemd/system.conf`, so it will put all tasks onto the first three
cores.

## Zynthbox UI Isolation And Startup Optimisation

We want to fix the UI to core 3, but we also want to be able to use all the
cores to initialise things during startup. So, to ensure the fastest bootup
speed, we first set zynthbox to start on only core 3, by adding the line

`CPUAffinity=3`

to the `[Service]` section of `/etc/systemd/system/zynthbox-qml.service`.

To ensure we actually use all the cores during startup, we set the UI
application's thread affinity to all four cores before loading it up, by
running it using taskset, adjusting start.sh to do so using this command:

`taskset --cpu-list 0-3 (the zynthian start command) &`

Once bootup has completed, we set the zynthbox process to have affinity for
only core 3, by adding the following to the `stop_splash` function:

`os.sched_setaffinity(os.getpid(), [3])`

This uses the python os module, and specifically this function:

`os.sched_setaffinity(pid, mask, /)`

Restrict the process with PID pid (or the current process if zero) to a set of
CPUs. mask is an iterable of integers representing the set of CPUs to which the
process should be restricted.

## Put Non-DSP Things On The UI Core

We also want to ensure that most things run on the UI core, so the DSP cores
can just spend their time doing basically just that and not get interrupted by
heavy things. So, we add the line `CPUAffinity=3` to the `[Service]` sections
of the files:

`/etc/systemd/system/dbus-org.bluez.service`
`/etc/systemd/system/dbus-org.freedesktop.Avahi.service`
`/etc/systemd/system/dbus-org.freedesktop.ModemManager1.service`
`/etc/systemd/system/dbus-org.freedesktop.timesync1.service`
`/etc/systemd/system/sshd.service`
`/etc/systemd/system/zynthian-webconf.service`
`/etc/systemd/system/zynthian-webconf-fmserver.service`

This might seem to contrast with our instructions to run everything on the
first three cores during bootup, however the intention here is to allow kernel
and dsp related things to live on those cores, and have ui and io heavy things,
including network traffic stuff, to live on the UI core. The reasoning here is
that Alsa runs in the kernel, and we can't move that anywhere else without a
whole lot of trouble, so we leave the kernel where it is, and just move
everything we reasonably can do out of the DSP chain's way.

## DSP Locations

Further, we set the affinity of our jack threads in libzynthbox by getting the
jack clients' thread IDs and requesting pthread to give them affinity for cores
0, 1, and 2.

This is done by explicitly setting the jack clients' affinity to cores 0, 1,
and 2 upon creation, which is done using `pthread_setaffinity_np()`. We also
do this to the SyncTimer thread, so all the playback stuff can be done in as
expedient a manner as possible.

As zyngine has a central point for launching all applications, we add the
following line to the `start(self)` function in `zynthian_engine.py`:

`os.sched_setaffinity(self.proc.pid, [0,1,2])`

which ensures that the engines are give affinity for the DSP cores.

## ZynMidiRouter Affinity

Finally, zyncoder's ZynMidiRouter jack client's process thread needs relocating
as well, which requires changing the location where that gets created.

First, include the pthread things (and because it's pure c code, also make sure
to define _GNU_SOURCE):

```
#define _GNU_SOURCE
#include <pthread.h>
#include <sched.h>
```

Then the code that does the actual affinity setting work:

```
// Set CPU affinity for the jack client to core 3 only
cpu_set_t cpuset;
CPU_ZERO(&cpuset);
// Our CPU set for the DSP is 0 (where the kernel also lives), 1, and 2. This leaves 4 for the UI application
CPU_SET(0, &cpuset);
CPU_SET(1, &cpuset);
CPU_SET(2, &cpuset);
const jack_native_thread_t threadID = jack_client_thread_id(jack_client);
int result = pthread_setaffinity_np(threadID, sizeof(cpuset), &cpuset);
```
