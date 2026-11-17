# notify.py <terminal> <light|dark>: tell the program in a herdr-core terminal
# that the color scheme changed, as a terminal does for mode 2031 (CSI ? 997 ; 1|2 n).
# hc can't write raw input, so attach at the terminal's own size, type the
# report, and detach (ctrl-\).
import fcntl, json, os, pty, select, struct, subprocess, sys, termios, time

terminal, mode = sys.argv[1], sys.argv[2]
report = b"\x1b[?997;1n" if mode == "dark" else b"\x1b[?997;2n"
info = json.loads(subprocess.check_output(["hc", "get", terminal, "--json"]))

pid, fd = pty.fork()
if pid == 0:
    os.execvp("hc", ["hc", "attach", terminal])
fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", info["rows"], info["cols"], 0, 0))

def drain(seconds):
    end = time.time() + seconds
    while time.time() < end:
        if select.select([fd], [], [], 0.1)[0]:
            try:
                os.read(fd, 65536)
            except OSError:
                return

drain(1.0)
os.write(fd, report)
drain(0.3)
os.write(fd, b"\x1c")
drain(1.0)
os.waitpid(pid, 0)
