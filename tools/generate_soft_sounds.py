from pathlib import Path
import math,wave,array
rate=44100;out=Path(__file__).resolve().parents[1]/'assets/sounds'
patterns={'tap':[(0,587.33,.07,.7)],'correct':[(0,523.25,.21,.7),(.10,659.25,.24,.7),(.21,783.99,.30,.7)],'incorrect':[(0,349.23,.22,.6),(.15,329.63,.28,.5)],'complete':[(0,440,.24,.6),(.13,554.37,.27,.6),(.26,659.25,.30,.65),(.40,880,.40,.6)],'achievement':[(0,523.25,.25,.6),(.11,659.25,.26,.6),(.23,783.99,.30,.6),(.37,1046.5,.42,.55),(.52,783.99,.35,.35)]}
for name,notes in patterns.items():
 length=max(t+d for t,f,d,g in notes)+.20;data=[0.0]*int(rate*length)
 for start,freq,duration,gain in notes:
  for i in range(int(rate*duration)):
   t=i/rate;u=t/duration
   env=(1-math.exp(-t/0.008))*math.exp(-4.2*u)*(1-u)**1.2
   tone=math.sin(2*math.pi*freq*t)+.18*math.exp(-12*u)*math.sin(2*math.pi*freq*2*t)+.06*math.exp(-18*u)*math.sin(2*math.pi*freq*3*t)
   value=gain*env*tone;index=int(start*rate)+i
   data[index]+=value
   for delay,amount in [(0.075,.10),(.135,.055)]:
    j=index+int(delay*rate)
    if j<len(data):data[j]+=value*amount
 peak=max(map(abs,data)) or 1;target=.32 if name=='tap' else .36 if name=='incorrect' else .52
 samples=array.array('h',(int(max(-1,min(1,x/peak*target))*32767) for x in data))
 with wave.open(str(out/(name+'.wav')),'wb') as f:f.setparams((1,2,rate,len(samples),'NONE','not compressed'));f.writeframes(samples.tobytes())
 print(name,round(length,2),'seconds')
