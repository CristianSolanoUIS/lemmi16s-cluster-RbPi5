import subprocess, time, csv, sys
from datetime import datetime
from pathlib import Path

out_csv = Path('/tmp/test_diag.csv')
f = open(out_csv, 'w')
w = csv.writer(f)
w.writerow(['ts', 'p'])

print('Running diagnostic loop for 20s...')
t_end = time.time() + 20
while time.time() < t_end:
    t0 = time.time()
    time.sleep(1.0)
    t_sleep = time.time() - t0
    
    t1 = time.time()
    try:
        out = subprocess.check_output(['vcgencmd', 'pmic_read_adc'], timeout=3.0).decode()
    except Exception as e:
        out = ''
    t_vc = time.time() - t1
    
    t2 = time.time()
    w.writerow([datetime.now().isoformat(), '2.5'])
    f.flush()
    t_flush = time.time() - t2
    
    print(f'sleep={t_sleep:.3f}s, vc={t_vc:.3f}s, flush={t_flush:.3f}s, total={time.time()-t0:.3f}s')

f.close()
