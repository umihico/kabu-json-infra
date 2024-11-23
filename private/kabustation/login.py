# 以下のコマンドでコピーして、ゴールデンイメージを作成する
# scp private/kabustation/login.py kabu-json-windows:"C:/Users/Administrator/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/login.py"

import pyautogui
import time

for attempt in range(0, 1000):
    print(f"Attempt {attempt}")
    apps = pyautogui.getWindowsWithTitle("ログイン")
    if len(apps) == 0:
        time.sleep(1)
        continue
    apps[0].activate()
    time.sleep(3)
    pyautogui.press("enter")
    break
