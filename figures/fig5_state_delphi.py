import os as _os, sys as _sys; _sys.path.insert(0, _os.path.join(_os.path.dirname(_os.path.dirname(_os.path.abspath(__file__))), "src"))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
import csv, numpy as np, matplotlib, sys
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Patch
st=sys.argv[1]   # GA, NE or OH (one panel of Fig. 5 each)
out=sys.argv[2] if len(sys.argv)>2 else f'{FIGS}/fig5_state_delphi_{st}.png'
names={'GA':'Georgia','NE':'Nebraska','OH':'Ohio'}
rows=[r for r in csv.DictReader(open(f'{FIGDATA}/fig5a_state_delphi_round2.csv')) if r['state']==st]
d={}
for r in rows:
    k=r['item']; d.setdefault(k,{'present':float(r['present_value']),'est':[],'group':r['group']})['est'].append(float(r['estimate_2050']))
for k,v in d.items():
    e=np.array(v['est']); v['pc']=100*(e-v['present'])/v['present']; v['med']=float(np.median(e)); v['cov']=float(e.std(ddof=1)/e.mean()); v['medpc']=float(np.median(v['pc']))
col={'Irrigation':'#2C7FB8','Management':'#4DAF4A','Inputs':'#7B3294','Emerging crop':'#7f7f7f'}
items=sorted(d,key=lambda k:d[k]['medpc'])
plt.rcParams.update({'font.family':'DejaVu Sans','font.size':10})
fig,ax=plt.subplots(figsize=(8.6,5.4)); lo,hi=-100,200; rng=np.random.default_rng(1)
for i,k in enumerate(items):
    v=d[k]['pc']; c=col[d[k]['group']]; cons=d[k]['cov']<0.3
    ax.boxplot(np.clip(v,lo,hi),positions=[i],orientation='horizontal',widths=0.6,patch_artist=True,showfliers=False,
        medianprops=dict(color='black',lw=1.6),whiskerprops=dict(color=c,lw=1.2),capprops=dict(color=c,lw=1.2),
        boxprops=dict(facecolor=c if cons else 'white',edgecolor=c,lw=1.6,alpha=0.85 if cons else 1))
    vv=v[(v>=lo)&(v<=hi)]; ax.scatter(vv,i+rng.uniform(-0.18,0.18,len(vv)),s=11,color='#333',alpha=0.55,zorder=3,lw=0)
    over=v[v>hi]
    if len(over): ax.annotate(f"→ {len(over)} above {hi}% (max {over.max():.0f}%)",(hi,i),xytext=(-4,9),textcoords='offset points',ha='right',fontsize=7.5,color='#555')
    ax.text(hi+8,i,f"{d[k]['present']:g} → {d[k]['med']:g}",va='center',fontsize=8.5)
ax.text(hi+8,len(items)-0.2,'Today → panel\nmedian, 2050',va='bottom',fontsize=8.5,fontweight='bold')
ax.axvline(0,color='#888',lw=1,ls='--',zorder=0)
ax.set_yticks(range(len(items))); ax.set_yticklabels(items); ax.set_xlim(lo-5,hi+3); ax.set_ylim(-0.7,len(items)-0.3)
ax.set_xlabel('Change from present value expected by 2050 (%)')
ax.set_title(f'{names[st]} Delphi panel (n = {max(len(v["est"]) for v in d.values())})',loc='left',fontsize=10.5)
for sp in ['top','right']: ax.spines[sp].set_visible(False)
grps=[g for g in col if any(d[k]['group']==g for k in d)]
h=[Patch(facecolor=col[g],edgecolor=col[g],label=g) for g in grps]+[Patch(facecolor='#999',edgecolor='#999',label='Filled: consensus (CoV < 0.3)'),Patch(facecolor='white',edgecolor='#999',label='Open: no consensus')]
ax.legend(handles=h,loc='upper center',bbox_to_anchor=(0.5,-0.12),ncol=3,frameon=False,fontsize=8.5)
fig.savefig(out,dpi=300,bbox_inches='tight',facecolor='white')
