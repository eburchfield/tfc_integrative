import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
import numpy as np, glob, pandas as pd
rows=[]
for f in sorted(glob.glob(f'{OUT}/projections/*.npz')):
  e=np.load(f); ok=e['ok']; c=f.split('/')[-1][:-4]
  H,W=e['shape']; lat=49.375-(np.arange(H)+.5)/24; w=np.repeat(np.cos(np.deg2rad(lat)),W)
  B,N,D,I=e['B'],e['N'],e['D'],e['INS']
  for nm,dl in (('delphi_asrun',D-N),('delphi_insurance_only_corrected',I-N)):
    rows.append(dict(crop=c,contrast=nm,mean_abs=np.mean(np.abs(dl[ok])),wa_all_pct=100*np.sum(w[ok]*dl[ok])/np.sum(w[ok]*B[ok])))
d=pd.DataFrame(rows); d.to_csv(f'{RES}/stats_insurance.csv',index=False)
print(d.pivot(index='crop',columns='contrast',values=['mean_abs','wa_all_pct']).round(4))
