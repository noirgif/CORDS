import curses
import subprocess
import threading


def execute_command(win, cmd):
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    while True:
        line = proc.stdout.readline()
        if not line:
            break
        win.addstr(line)
        win.refresh()

def create_window(index, title):
    max_y, max_x = curses.LINES, curses.COLS
    window_height = max_y // 2

    win = curses.newwin(window_height, max_x, index * window_height, 0)
    win.scrollok(True)
    win.addstr(0, 0, f"{title}\n")
    win.refresh()
    return win

def run_in_curses(cmd_list_1, cmd_list_2):
    def wrapper(stdscr):
        curses.curs_set(0)
        win1 = create_window(0, " ".join(cmd_list_1))
        win2 = create_window(1, " ".join(cmd_list_2))

        t1 = threading.Thread(target=execute_command, args=(win1, cmd_list_1))
        t2 = threading.Thread(target=execute_command, args=(win2, cmd_list_2))
        t1.start()
        t2.start()

        t1.join()
        t2.join()

        stdscr.getch()

    curses.wrapper(wrapper)
