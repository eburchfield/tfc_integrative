"""Fig. 2: SHAP shares by predictor category for the seven main crops."""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.join(_os.path.dirname(_os.path.dirname(_os.path.abspath(__file__))), "src"))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
import pandas as pd, numpy as np, matplotlib
matplotlib.use('Agg'); import matplotlib.pyplot as plt
from matplotlib.patches import Patch
g=pd.read_csv(f'{FIGDATA}/fig2_county_group_abs_shap.csv')   # LR's county SHAP, |SHAP| summed by group
s=g.groupby(['crop','group']).abs_shap.mean().unstack(); s=s.div(s.sum(axis=1),axis=0)
s['Human']=1-s[['Climate','Soil','Topography']].sum(axis=1); s=s.reset_index(); s=s[~s.crop.isin(['OATS','FRUITVEG'])].set_index('crop')*100
order=s.sort_values('Human',ascending=False).index
names={'CORN':'Corn','SOY':'Soybeans','HAY':'Hay','COTTON':'Cotton','PEANUTS':'Peanuts','WHEAT':'Wheat','SORGHUM':'Sorghum'}
bio=['Climate','Soil','Topography']; hum=['Irrigation','Management','Inputs','Economics','Demographics','Infrastructure']
cols=dict(Climate='#8C5A2B',Soil='#C49A6C',Topography='#E6D2B5',Irrigation='#2C7FB8',Management='#4DAF4A',Inputs='#7B3294',Economics='#E7298A',Demographics='#1B9E9E',Infrastructure='#F2C14E')
plt.rcParams.update({'font.family':'DejaVu Sans','font.size':11})
fig,ax=plt.subplots(figsize=(7.4,4.6))
x=np.arange(len(order))
for i,c in enumerate(order):
    b=0
    for g in bio+hum:
        v=s.loc[c,g]; ax.bar(i,v,bottom=b,width=0.72,color=cols[g],edgecolor='white',linewidth=0.6); b+=v
    ax.text(i,101.5,f"{s.loc[c,'Human']:.0f}%",ha='center',va='bottom',fontweight='bold',fontsize=10.5)
ax.text(-0.55,109,'Human-controlled share',fontsize=10)
ax.set_ylim(0,114); ax.set_yticks(range(0,101,20)); ax.set_xticks(x); ax.set_xticklabels([names[c] for c in order],rotation=35,ha='right')
ax.set_ylabel('Share of total absolute SHAP (%)')
for sp in ['top','right']: ax.spines[sp].set_visible(False)
h1=[Patch(color=cols[g],label=g) for g in reversed(hum)]; h2=[Patch(color=cols[g],label=g) for g in reversed(bio)]
l1=ax.legend(handles=h1,title='Human-controlled',loc='upper left',bbox_to_anchor=(1.01,1.0),frameon=False,alignment='left')
ax.add_artist(l1); ax.legend(handles=h2,title='Biophysical',loc='lower left',bbox_to_anchor=(1.01,0.0),frameon=False,alignment='left')
fig.savefig(f'{FIGS}/fig2_shap_group_shares.png',dpi=300,bbox_inches='tight',facecolor='white')
