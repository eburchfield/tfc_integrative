import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
import numpy as np, os, csv
crops=['CORN','SOY','WHEAT','SORGHUM','HAY','OATS','FRUITVEG']
rows=[]
for c in crops:
    f=f'{OUT}/bridge/nat_{c}.npz'
    if not os.path.exists(f): continue
    d=np.load(f); H,W=d['shape']; ok=d['ok']
    lat=49.375-(np.arange(H*W)//W+0.5)/24; w=np.cos(np.radians(lat))
    m=lambda k: np.average(d[k][ok],weights=w[ok])*100
    B=m('B'); r={'crop':c,'scope':'national','today':B,'weather':m('N')-B,'panel_rel':m('PAN')-B,'bridge':m('BR')-B,'LR':m('D')-B}
    rows.append(r)
    g=f'{OUT}/bridge/oh_{c}.npz'
    if os.path.exists(g):
        o=np.load(g); okw=o['ok']; latw=41.958333333-(np.arange(85*104)//104+0.5)/24; ww=np.cos(np.radians(latw))
        mm=lambda k: np.average(o[k][okw],weights=ww[okw])*100
        Bo=mm('B'); rows.append({'crop':c,'scope':'Ohio','today':Bo,'weather':np.nan,'panel_rel':mm('PANOH')-Bo,'bridge':mm('BROH')-Bo,'LR':np.nan})
print(f"{'crop':9s}{'scope':10s}{'today':>7s}{'weather':>9s}{'panel':>8s}{'bridge':>8s}{'LR':>8s}")
for r in rows: print(f"{r['crop']:9s}{r['scope']:10s}{r['today']:7.1f}{r['weather']:+9.2f}{r['panel_rel']:+8.2f}{r['bridge']:+8.2f}{r['LR']:+8.2f}")
os.makedirs(RES, exist_ok=True)
with open(f'{RES}/partial_bridge_results.csv','w',newline='') as fh:
    wr=csv.DictWriter(fh,fieldnames=list(rows[0])); wr.writeheader(); wr.writerows(rows)
