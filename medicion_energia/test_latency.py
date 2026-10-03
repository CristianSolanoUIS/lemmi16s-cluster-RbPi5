import time, subprocess, sys

print("Testing latency on host:", subprocess.check_output(["hostname"]).decode().strip())
for mode in ["single_sleep", "micro_sleep"]:
    print(f"\n--- Testing mode: {mode} ---")
    for i in range(5):
        t0 = time.monotonic()
        if mode == "single_sleep":
            time.sleep(1.0)
        else:
            for _ in range(10):
                time.sleep(0.1)
        t_sleep = time.monotonic() - t0
        
        t1 = time.monotonic()
        try:
            out = subprocess.check_output(["vcgencmd", "pmic_read_adc"], timeout=3.0).decode()
            status = "OK"
        except Exception as e:
            status = type(e).__name__
        t_vc = time.monotonic() - t1
        
        tot = time.monotonic() - t0
        print(f"[{i:02d}] tot={tot:.3f}s (sleep={t_sleep:.3f}s, vc={t_vc:.3f}s, status={status})")
