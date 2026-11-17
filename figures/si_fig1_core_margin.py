import os as _os, sys as _sys; _sys.path.insert(0, _os.path.join(_os.path.dirname(_os.path.dirname(_os.path.abspath(__file__))), "src"))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
import numpy as np, pandas as pd, matplotlib
matplotlib.use('Agg'); import matplotlib.pyplot as plt
crops=['SOY','CORN','HAY','COTTON','PEANUTS','WHEAT','SORGHUM']
names={'CORN':'Corn','SOY':'Soybeans','HAY':'Hay','COTTON':'Cotton','PEANUTS':'Peanuts','WHEAT':'Wheat','SORGHUM':'Sorghum'}
rows=[]
for c in crops:
    z=np.load(f'{OUT}/projections/{c}.npz'); H,W=z['shape']; ok=z['ok']; B,N,P=z['B'],z['N'],z['PAN']
    lat=49.375-(np.arange(H)+.5)/24; w=np.repeat(np.cos(np.deg2rad(lat)),W); km2=w*(111.32/24)**2
    r={'crop':names[c]}
    for zn,m in {'core':ok&(B>.3),'margin':ok&(B>.1)&(B<=.3),'outside':ok&(B<=.1)}.items():
        den=np.sum(w[m]*B[m])
        r[f'{zn}_climate_only_pct']=100*np.sum(w[m]*(N-B)[m])/den; r[f'{zn}_stakeholder_pct']=100*np.sum(w[m]*(P-B)[m])/den
    for k,X in (('baseline',B),('climate_only',N),('stakeholder',P)):
        r[f'area_gt075_{k}_thousand_km2']=np.sum(km2[ok&(X>0.75)])/1000
    rows.append(r)
df=pd.DataFrame(rows); df.round(1).to_csv(f'{RES}/si_fig1_core_margin.csv',index=False)
print(df.round(1).to_string())
fig,axs=plt.subplots(1,2,figsize=(11,3.8)); x=np.arange(len(crops))
for ax,(zn,t) in zip(axs,[('core','Core (baseline likelihood > 0.3)'),('margin','Margin (baseline likelihood 0.1–0.3)')]):
    a=df[f'{zn}_climate_only_pct']; b=df[f'{zn}_stakeholder_pct']
    for i in x: ax.annotate('',xy=(i,b[i]),xytext=(i,a[i]),arrowprops=dict(arrowstyle='->',color='#999',lw=1.2))
    ax.scatter(x,a,s=42,facecolor='white',edgecolor='#8C5A2B',lw=1.6,zorder=3,label='Climate-only projection')
    ax.scatter(x,b,s=42,color='#01665E',zorder=3,label='Stakeholder-informed projection')
    ax.axhline(0,color='#555',ls='--',lw=0.8); ax.set_xticks(x); ax.set_xticklabels(df.crop,rotation=35,ha='right'); ax.set_title(t,loc='left',fontsize=10)
    for sp in ['top','right']: ax.spines[sp].set_visible(False)
axs[0].set_ylabel('Change in likelihood-weighted\narea, % of baseline'); axs[1].legend(frameon=False,fontsize=9)
fig.tight_layout(); fig.savefig(f'{FIGS}/si_fig1_core_margin.png',dpi=250,facecolor='white')
