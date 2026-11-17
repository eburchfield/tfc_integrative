/* Exact path-dependent TreeSHAP (Lundberg et al. 2020, Algorithm 2) for sklearn-style trees.
   phi (n x p) accumulates scale * SHAP values of one tree. */
#include <stdlib.h>
#include <string.h>
typedef struct { int f; double z, o, w; } PE;
static void extend(PE *u, int d, double z, double o, int f){
  u[d].f=f; u[d].z=z; u[d].o=o; u[d].w=(d==0)?1.0:0.0;
  for(int i=d-1;i>=0;i--){ u[i+1].w += o*u[i].w*(i+1)/(double)(d+1); u[i].w = z*u[i].w*(d-i)/(double)(d+1); }
}
static void unwind(PE *u, int d, int pi){
  double o=u[pi].o, z=u[pi].z, n=u[d].w, t;
  for(int i=d-1;i>=0;i--){
    if(o!=0){ t=u[i].w; u[i].w=n*(d+1)/((i+1)*o); n=t-u[i].w*z*(d-i)/(double)(d+1); }
    else u[i].w=u[i].w*(d+1)/(z*(d-i));
  }
  for(int i=pi;i<d;i++){ u[i].f=u[i+1].f; u[i].z=u[i+1].z; u[i].o=u[i+1].o; }
}
static double unwound_sum(PE *u, int d, int pi){
  double o=u[pi].o, z=u[pi].z, n=u[d].w, tot=0, t;
  for(int i=d-1;i>=0;i--){
    if(o!=0){ t=n*(d+1)/((i+1)*o); tot+=t; n=u[i].w-t*z*((d-i)/(double)(d+1)); }
    else tot+=(u[i].w/z)/((d-i)/(double)(d+1));
  }
  return tot;
}
static const int *L,*R,*F; static const double *T,*V,*C;
static void rec(int node, double *phi, const double *x, PE *pu, int d, double pz, double po, int pf, double scale){
  PE *u = pu + d + 1;
  memcpy(u, pu, sizeof(PE)*(d+1));
  extend(u, d, pz, po, pf);
  if(L[node] < 0){
    for(int i=1;i<=d;i++){ double w=unwound_sum(u,d,i); phi[u[i].f] += scale*w*(u[i].o-u[i].z)*V[node]; }
    return;
  }
  int f=F[node]; int hot = (x[f] <= T[node]) ? L[node] : R[node]; int cold = (hot==L[node]) ? R[node] : L[node];
  double w=C[node], hz=C[hot]/w, cz=C[cold]/w, iz=1, io=1;
  int pi=0; for(;pi<=d;pi++) if(u[pi].f==f) break;
  if(pi!=d+1){ iz=u[pi].z; io=u[pi].o; unwind(u,d,pi); d-=1; }
  rec(hot, phi, x, u, d+1, hz*iz, io, f, scale);
  rec(cold, phi, x, u, d+1, cz*iz, 0, f, scale);
}
void tree_shap(int maxd, const int *left, const int *right, const int *feat, const double *thr,
               const double *val, const double *cover, const double *X, int n, int p, double *phi, double scale){
  L=left; R=right; F=feat; T=thr; V=val; C=cover;
  int sz=(maxd+2)*(maxd+3)/2; PE *buf=(PE*)malloc(sizeof(PE)*sz*2);
  for(int r=0;r<n;r++) rec(0, phi + (long)r*p, X + (long)r*p, buf, 0, 1.0, 1.0, -1, scale);
  free(buf);
}
