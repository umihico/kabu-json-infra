# 以下のコマンドでコピーして、ゴールデンイメージを作成する
# scp private/kabustation/login.py kabu-json-windows:"C:/Users/Administrator/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/login.py"

import pyautogui
import time

pyautogui.FAILSAFE = False  # PyAutoGUI fail-safe triggered from mouse moving to a corner of the screen. To disable this fail-safe, set pyautogui.FAILSAFE to False. DISABLING FAIL-SAFE IS NOT RECOMMENDED. 防止

# たまに何故かエンター押しても入れないことあるので、exitせずログイン窓がある限り1000秒間試行する
for attempt in range(0, 1000):
    try:
        time.sleep(1)
        print(f"試行{attempt}")
        apps = pyautogui.getWindowsWithTitle("ログイン")
        if len(apps) == 0:
            print("ログインが見つからない")
            continue
        apps[0].activate()
        time.sleep(1)
        pyautogui.press("enter")
        print("エンター押下")
    except Exception as e:
        print(e)

# 実行ログを残すようにプロンプトを出して起動しっぱなしにする
input()
