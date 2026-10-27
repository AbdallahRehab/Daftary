import numpy as np, wave
SR=44100; DUR=20.0; N=int(SR*DUR)
BPM=120; BEAT=60/BPM; BAR=4*BEAT
L=np.zeros(N); R=np.zeros(N)
rng=np.random.default_rng(7)
def f(m): return 440*2**((m-69)/12)
def add(sig,t,gain=1.0,pan=0.0):
    i=int(round(t*SR));
    if i>=N: return
    s=sig[:N-i]*gain
    L[i:i+len(s)]+=s*np.sqrt((1-pan)/2)
    R[i:i+len(s)]+=s*np.sqrt((1+pan)/2)
def lp(x,a):  # one-pole lowpass, a in (0,1)
    from scipy.signal import lfilter
    return lfilter([a],[1,-(1-a)],x)
def env(n,att,rel_tau):
    t=np.arange(n)/SR; e=np.minimum(1,t/max(att,1e-4))*np.exp(-t/rel_tau); return e
# chords (MIDI) per bar: D A Bm G D A Bm G A D
D=[50,54,57,62]; A=[45,52,57,61]; Bm=[47,54,59,62]; G=[43,50,55,59]
prog=[D,A,Bm,G,D,A,Bm,G,A,D]
roots=[38,33,35,31,38,33,35,31,33,38]
# --- pad (all bars), soft detuned saws, lowpassed
for b,ch in enumerate(prog):
    t0=b*BAR; n=int(BAR*SR)+int(0.4*SR)
    if b==9: n=int((DUR-t0)*SR)
    tt=np.arange(n)/SR; s=np.zeros(n)
    for m in ch:
        for det in (-0.08,0.08):
            fr=f(m+12)*(1+det/100*3)
            s+=2*((tt*fr)%1)-1
    a=np.minimum(1,tt/0.35)*np.minimum(1,np.maximum(0,(n/SR-tt)/0.4))
    s=lp(s*a,0.035)
    g=0.07 if t0<3 else 0.028
    add(s,t0,g,0)
# --- pluck arpeggio 8ths from 3.0 to 19.0
def pluck(fr,dur=0.45,bright=0.5):
    n=int(dur*SR); tt=np.arange(n)/SR
    s=np.sin(2*np.pi*fr*tt)+0.35*np.sin(2*np.pi*2*fr*tt)*np.exp(-tt/0.08)+0.15*np.sin(2*np.pi*3*fr*tt)*np.exp(-tt/0.05)
    return s*env(n,0.003,0.16)
k=0
t=3.0
while t<19.0-1e-6:
    b=int(t//BAR); ch=prog[b]
    pat=[0,2,3,1,2,3,1,2]
    m=ch[pat[k%8]]+12
    add(pluck(f(m)),t,0.10 if k%2==0 else 0.075,(-0.35 if k%2==0 else 0.35))
    k+=1; t+=BEAT/2
# --- bass: root on beats 1, "and of 2", 3 (from 3.0)
def bass(fr,dur):
    n=int(dur*SR); tt=np.arange(n)/SR
    s=np.tanh(1.6*(np.sin(2*np.pi*fr*tt)+0.25*np.sin(2*np.pi*2*fr*tt)))
    return s*np.minimum(1,tt/0.005)*np.exp(-tt/0.5)*np.minimum(1,np.maximum(0,(dur-tt)/0.03))
for b in range(10):
    for off,d in ((0,0.7),(1.5*BEAT,0.45),(2*BEAT,0.9)):
        t=b*BAR+off
        if 3.0-1e-6<=t<19.0: add(bass(f(roots[b]),d),t,0.20,0)
# --- drums from 3.0 to 19.0
def kick():
    n=int(0.35*SR); tt=np.arange(n)/SR
    ph=2*np.pi*np.cumsum(48+90*np.exp(-tt/0.035))/SR
    return np.sin(ph)*np.exp(-tt/0.12)
def clap():
    n=int(0.25*SR); tt=np.arange(n)/SR; x=rng.standard_normal(n)
    x=x-lp(x,0.12); x=lp(x,0.5)
    return x*np.exp(-tt/0.07)
def hat():
    n=int(0.06*SR); tt=np.arange(n)/SR; x=rng.standard_normal(n); x=x-lp(x,0.6)
    return x*np.exp(-tt/0.018)
t=3.0
while t<19.0-1e-6:
    beat=int(round(t/BEAT))
    add(kick(),t,0.55)
    if beat%2==1: add(clap(),t,0.13,0.05)
    add(hat(),t+BEAT/2,0.05,0.25)
    t+=BEAT
# --- SFX, all on the grid and in key
def bell(fr,dur=1.2,g=1):
    n=int(dur*SR); tt=np.arange(n)/SR
    s=np.sin(2*np.pi*fr*tt)*np.exp(-tt/0.5)+0.4*np.sin(2*np.pi*2.0*fr*tt)*np.exp(-tt/0.25)+0.2*np.sin(2*np.pi*3.01*fr*tt)*np.exp(-tt/0.12)
    return s*np.minimum(1,tt/0.002)*g
def scratch(dur=0.32):
    n=int(dur*SR); tt=np.arange(n)/SR; x=rng.standard_normal(n)
    x=x-lp(x,0.25); x=lp(x,0.45)
    am=0.6+0.4*np.sin(2*np.pi*18*tt)
    return x*am*np.minimum(1,tt/0.02)*np.minimum(1,(dur-tt)/0.06)
def swoosh(dur=0.5):
    n=int(dur*SR); tt=np.arange(n)/SR; x=rng.standard_normal(n)
    a=0.02+0.25*(tt/dur)**2; y=np.empty(n); acc=0
    for k2 in range(n): acc+=a[k2]*(x[k2]-acc); y[k2]=acc
    return y*(tt/dur)**1.5*np.minimum(1,(dur-tt)/0.03)
for t0 in (0.25,0.5,0.75):  add(scratch(0.22),t0,0.18,-0.2)   # writing Ahmed
add(scratch(0.25),1.0,0.22,0.1)                                 # strike
for t0 in (1.25,1.75,2.0): add(scratch(0.2),t0,0.15,-0.1)
add(bell(f(81),1.4),2.5,0.10,0.2)                               # coin lands (A5)
add(swoosh(1.0),2.0,0.22)                                       # riser into drop
add(kick(),3.0,0.3); add(bell(f(74),2.0),3.0,0.08,-0.1)         # drop + D5 bell
for tc in (6.0,10.0,13.5):
    add(swoosh(0.5),tc-0.5,0.16)
add(swoosh(0.5),16.5,0.18)
add(bell(f(86),0.6),7.0,0.06,0.3)                               # tap (D6)
for t0,m in ((8.0,78),(8.25,81),(8.5,86)): add(bell(f(m),0.8),t0,0.07,0.2)  # chips F#5 A5 D6
add(bell(f(85),0.6),11.0,0.05,-0.2)                             # language toggle (C#6)
add(bell(f(81),1.0),15.0,0.09,0.25); add(bell(f(86),1.0),15.25,0.06,0.25)  # SMS lands
add(kick(),17.0,0.3); add(bell(f(74),3.0),17.0,0.10); add(bell(f(78),3.0),17.25,0.06); add(bell(f(81),3.0),17.5,0.06)
# final ring: D chord sustain beyond drums
n=int(1.0*SR); tt=np.arange(n)/SR
for m in (50,57,62,66): add(np.sin(2*np.pi*f(m)*tt)*np.exp(-tt/0.6),19.0,0.05)
# --- master: gentle glue, fades
mix=np.stack([L,R])
fade=np.ones(N); fi=int(0.02*SR); fade[:fi]=np.linspace(0,1,fi)
fo=int(0.6*SR); fade[-fo:]=np.linspace(1,0,fo)**1.5
mix*=fade
mix=mix/np.max(np.abs(mix))*1.3
mix=np.tanh(mix)*0.89
out=(mix.T*32767).astype(np.int16)
with wave.open('music.wav','wb') as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes(out.tobytes())
print('ok', out.shape)
