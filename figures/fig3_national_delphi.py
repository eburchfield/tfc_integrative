import os as _os, sys as _sys; _sys.path.insert(0, _os.path.join(_os.path.dirname(_os.path.dirname(_os.path.abspath(__file__))), "src"))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
import csv, json, numpy as np, matplotlib
matplotlib.use('Agg'); import matplotlib.pyplot as plt
from matplotlib.patches import Patch
from matplotlib.lines import Line2D
rows=list(csv.DictReader(open(f'{FIGDATA}/fig3_national_delphi_round2.csv')))
d={}
for r in rows:
    k=r['item']; d.setdefault(k,{'present':float(r['present_value']),'est':[],'group':r['model_group']})['est'].append(float(r['estimate_2050']))
for k,v in d.items():
    e=np.array(v['est']); v['pc']=100*(e-v['present'])/v['present']; v['med']=float(np.median(e)); v['cov']=float(e.std(ddof=1)/e.mean()); v['medpc']=float(np.median(v['pc']))
SHOW_TREND=False  # trend comparison moved to Supplementary Fig. (si_input_comparison.py)
tp=json.load(open(f'{RES}/trend_pct.json'))
trend={'Cropland in CRP':tp['CRP_ACRE'],'N rate on corn':tp['N_fert_kg'],'P rate on corn':tp['P_fert_kg'],
       'Farmland operated by small farms':tp['no_ops_sales_lt_10k'],'Farm sales by large farms':tp['sales_usd_gt_500k'],
       'Farmland operated by renters':tp['rented_fract'],'Socially disadvantaged operators':tp['Producer_nonwhite'],'Hired farmworkers':tp['labor_number']}
col={'Economics':'#E7298A','Management':'#4DAF4A','Infrastructure':'#F2C14E','Inputs':'#7B3294','Demographics':'#1B9E9E'}
items=sorted(d,key=lambda k:d[k]['medpc'])
plt.rcParams.update({'font.family':'DejaVu Sans','font.size':10})
fig,ax=plt.subplots(figsize=(9.2,6.2)); lo,hi=-100,160; rng=np.random.default_rng(1)
for i,k in enumerate(items):
    v=d[k]['pc']; c=col[d[k]['group']]; cons=d[k]['cov']<0.3
    ax.boxplot(np.clip(v,lo,hi),positions=[i],orientation='horizontal',widths=0.6,patch_artist=True,showfliers=False,
        medianprops=dict(color='black',lw=1.6),whiskerprops=dict(color=c,lw=1.2),capprops=dict(color=c,lw=1.2),
        boxprops=dict(facecolor=c if cons else 'white',edgecolor=c,lw=1.6,alpha=0.85 if cons else 1))
    vv=v[(v>=lo)&(v<=hi)]; ax.scatter(vv,i+rng.uniform(-0.18,0.18,len(vv)),s=11,color='#333',alpha=0.5,zorder=3,lw=0)
    over=v[v>hi]
    if len(over): ax.annotate(f"→ {len(over)} above {hi}% (max {over.max():.0f}%)",(hi,i),xytext=(-4,9),textcoords='offset points',ha='right',fontsize=7.5,color='#555')
    if SHOW_TREND and k in trend:
        t=max(min(trend[k],hi),lo)
        ax.plot(t,i,marker='D',ms=8,mfc='white',mec='#D9822B',mew=2.2,zorder=5)
    ax.text(hi+8,i,f"{d[k]['present']:g} → {d[k]['med']:g}",va='center',fontsize=8.5)
ax.text(hi+8,len(items)-0.2,'Today → panel\nmedian, 2050',va='bottom',fontsize=8.5,fontweight='bold')
ax.axvline(0,color='#888',lw=1,ls='--',zorder=0)
LBL={'N rate on corn':'Nitrogen rate on corn','P rate on corn':'Phosphorus rate on corn'}
ax.set_yticks(range(len(items))); ax.set_yticklabels([LBL.get(k,k) for k in items]); ax.set_xlim(lo-5,hi+3); ax.set_ylim(-0.7,len(items)-0.3)
ax.set_xlabel('Change from present value expected by 2050 (%)')
for sp in ['top','right']: ax.spines[sp].set_visible(False)
grps=[g for g in col if any(d[k]['group']==g for k in d)]
h=[Patch(facecolor=col[g],edgecolor=col[g],label=g) for g in grps]+[Patch(facecolor='#999',edgecolor='#999',label='Filled: consensus (CoV < 0.3)'),Patch(facecolor='white',edgecolor='#999',label='Open: no consensus')]
if SHOW_TREND: h.append(Line2D([],[],marker='D',ls='',mfc='white',mec='#D9822B',mew=2.2,ms=8,label='Linear census trend extended to 2050'))
ax.legend(handles=h,loc='upper center',bbox_to_anchor=(0.5,-0.1),ncol=3,frameon=False,fontsize=8.5)
fig.savefig(f'{FIGS}/fig3_national_delphi.png',dpi=300,bbox_inches='tight',facecolor='white')
