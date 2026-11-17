import os as _os, sys as _sys; _sys.path.insert(0, _os.path.join(_os.path.dirname(_os.path.dirname(_os.path.abspath(__file__))), "src"))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
import geo, numpy as np, csv, matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap
P=f'{FOREB}/out/model2_R/'
crops=['SOY','CORN','HAY','COTTON','PEANUTS','WHEAT','SORGHUM']   # Fig. 2 order (human share)
names={'CORN':'Corn','SOY':'Soybeans','HAY':'Hay','FRUITVEG':'Fruit & veg.','COTTON':'Cotton','PEANUTS':'Peanuts','WHEAT':'Wheat','SORGHUM':'Sorghum','OATS':'Oats'}
recs=geo.read_dbf(f'{FOREB}/data/states.dbf'); shp=geo.read_shp(f'{FOREB}/data/states.shp')
import sys; D={}; BAR={}; HATCH={}
import os; AOA=os.environ.get('AOA')=='1'   # AOA=1: hatch pixels outside the area of applicability (needs aoa.py output)
for c in crops:
    z=np.load(f'{OUT}/projections/{c}.npz'); H,W=z['shape']; ok=z['ok']
    B,N,P=z['B'],z['N'],z['PAN']
    keep=ok&((B>0.3)|(N>0.3)|(P>0.3)); D[c]=np.where(keep,P-B,np.nan).reshape(H,W)
    if AOA:
        A=np.load(f'{RES}/aoa/aoa_{c}.npz'); HATCH[c]=(keep&(A['PAN']>A['thr95'])).reshape(H,W)
    lat=49.375-(np.arange(H)+.5)/24; w=np.repeat(np.cos(np.deg2rad(lat)),W)
    f=lambda x: 100*np.sum(w[ok]*x[ok])/np.sum(w[ok]*B[ok])
    BAR[c]=(f(N-B),f(P-N),f(P-B))
e=(-106.6667,-106.6667+W/24,49.375-H/24,49.375)
ext=e; lim=0.1
_b=plt.get_cmap('BrBG'); CENTER=(0.89,0.87,0.80,1)
cmap=LinearSegmentedColormap.from_list('brbg_c',[_b(x) for x in np.linspace(0,0.42,64)]+[CENTER]*8+[_b(x) for x in np.linspace(0.58,1,64)])
plt.rcParams.update({'font.family':'DejaVu Sans','font.size':10})
fig=plt.figure(figsize=(15,13.2))
gs=fig.add_gridspec(4,4,height_ratios=[1,1,0.34,2.0],hspace=0.08,wspace=0.02)
for i,c in enumerate(crops):
    ax=fig.add_subplot(gs[i//4,i%4]); d=D[c]
    rgb=cmap((np.clip(d/lim,-1,1)+1)/2); rgb[np.abs(d)<0.01]=CENTER; rgb[np.isnan(d)]=(1,1,1,1)
    ax.imshow(rgb,extent=ext,interpolation='nearest')
    if AOA and HATCH[c].any():
        xs=np.linspace(ext[0],ext[1],W); ys=np.linspace(ext[3],ext[2],H)
        ax.contourf(xs,ys,HATCH[c].astype(float),levels=[0.5,1.5],colors='none',hatches=['//////'])
        ax.text(0.98,0.03,f"{100*HATCH[c].sum()/np.isfinite(D[c]).sum():.0f}% outside AOA",transform=ax.transAxes,ha='right',va='bottom',fontsize=8,color='#444')
    for rec,parts in zip(recs,shp):
        if rec['STATE_ABBR'] in ('HI','AK'): continue
        for pt in parts: ax.plot(pt[:,0],pt[:,1],color='#9a9a9a',lw=0.3)
    ax.set_xlim(ext[0],ext[1]); ax.set_ylim(ext[2],ext[3]); ax.set_aspect(1.25); ax.set_xticks([]); ax.set_yticks([])
    for sp in ax.spines.values(): sp.set_visible(False)
    ax.text(0.02,0.97,names[c],transform=ax.transAxes,fontsize=12,fontweight='bold',va='top',ha='left',bbox=dict(facecolor='white',edgecolor='none',alpha=0.85,pad=1.5))
fig.text(0.11,0.9,'a',fontweight='bold',fontsize=15)
fig.text(0.13,0.9,'Stakeholder-informed projection (revised model + national Delphi expectations, SSP2-4.5, 2041–2060) minus baseline (2021–2040 climate, human-controlled predictors at 2009–2018 values)',fontsize=9.5,va='center')
# colorbar row
row=fig.add_subplot(gs[2,:]); row.axis('off'); cax=row.inset_axes([0.25,0.70,0.36,0.16])
cb=fig.colorbar(plt.cm.ScalarMappable(cmap=cmap,norm=plt.Normalize(-lim,lim)),cax=cax,orientation='horizontal',extend='both')
cb.set_ticks([-0.1,-0.05,0,0.05,0.1]); cb.ax.tick_params(labelsize=9)
cb.set_label('Change in likelihood, 2050 minus baseline',fontsize=9.5)
cax.text(-0.07,0.5,'Lower\nlikelihood',transform=cax.transAxes,ha='right',va='center',fontsize=9,color='#8C5A2B',fontweight='bold')
cax.text(1.07,0.5,'Higher\nlikelihood',transform=cax.transAxes,ha='left',va='center',fontsize=9,color='#01665E',fontweight='bold')
row.text(0.74,0.80,'■',color='#e3ddcc',fontsize=12,transform=row.transAxes); row.text(0.76,0.82,'near-zero (|Δ| < 0.01)',fontsize=8.5,transform=row.transAxes)
row.text(0.74,0.58,'□',color='#999',fontsize=12,transform=row.transAxes); row.text(0.76,0.60,'likelihood < 0.3 in all scenarios',fontsize=8.5,transform=row.transAxes)
# panel b: climate vs expected human change, likelihood-weighted area
bx=fig.add_subplot(gs[3,:])
y=1.25*np.arange(len(crops))[::-1]
for j,c in enumerate(crops):
    cl,hu,to=BAR[c]; yy=y[j]
    for off,v,fc,ec in ((0.33,cl,'#C9A27E','#8C5A2B'),(0,hu,'#01665E','#01665E'),(-0.33,to,'#4D4D4D','#4D4D4D')):
        bx.barh(yy+off,v,height=0.28,color=fc,edgecolor=ec,lw=0.8)
        bx.text(v+(0.15 if v>=0 else -0.15),yy+off,f'{v:+.1f}',va='center',ha='left' if v>=0 else 'right',fontsize=9,color='#333',bbox=dict(facecolor='white',edgecolor='none',pad=0.4,alpha=0.9))
bx.axvline(0,color='#555',lw=0.8)
bx.set_yticks(y); bx.set_yticklabels([names[c] for c in crops],fontsize=11); bx.set_ylim(y.min()-0.7,y.max()+0.7); xl=bx.get_xlim(); bx.set_xlim(xl[0]-0.8,xl[1]+1.2)
bx.set_xlabel('Change in likelihood-weighted area, 2041–2060 vs 2021–2040 baseline (% of baseline)')
for sp in ['top','right']: bx.spines[sp].set_visible(False)
from matplotlib.patches import Patch
from matplotlib.lines import Line2D
bx.legend(handles=[Patch(facecolor='#C9A27E',edgecolor='#8C5A2B',label='Climate change (climate-only projection)'),
                   Patch(facecolor='#01665E',label='Expected human change (national Delphi)'),
                   Patch(facecolor='#4D4D4D',label='Combined (stakeholder-informed projection)')],
          loc='upper right',frameon=True,framealpha=1,edgecolor='white',fontsize=10)
p=bx.get_position(); fig.text(0.1,p.y1+0.02,'b',fontweight='bold',fontsize=15)
fig.savefig(f'{FIGS}/'+('si_fig6_change_maps_aoa' if AOA else 'fig4_change_maps')+'.png',dpi=250,bbox_inches='tight',facecolor='white')
