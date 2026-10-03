import time, subprocess

for i in range(15):
    t0 = time.time()
    try:
        out = subprocess.check_output(["vcgencmd", "pmic_read_adc"], timeout=3.0).decode()
        status = f"OK (len={len(out)})"
    except Exception as e:
        status = type(e).__name__
    t_call = time.time() - t0
    print(f"Iter {i:02d}: call={t_call:.3f}s, status={status}", flush=True)
    time.sleep(1.0)
