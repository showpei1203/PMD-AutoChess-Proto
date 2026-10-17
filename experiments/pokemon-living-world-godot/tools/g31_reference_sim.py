#!/usr/bin/env python3
"""Independent, OFFLINE Python reference for G3.1 stance policy.

This reference is illustrative regression coverage, not Godot runtime proof.
"""
from __future__ import annotations
from dataclasses import dataclass
from math import hypot
import json
import argparse

SEEDS=(20261017,20365746,31415926,42,777,2025,99991,8008135)
ORDERS=('FREE','AGGRESSIVE','KEEP_DISTANCE','DEFENSIVE')
ZONE_MIN=118.
ZONE_MAX=160.
ZONE_REACH=169.
ZONE_POWER=8
ZONE_COOLDOWN=17
ZONE_WINDUP=5
GUARD_RECHARGE=25
LIMIT=600

@dataclass
class Fighter:
    i:int
    hp:int
    max_hp:int
    power:int
    speed:float
    reach:float
    cooldown_ticks:int
    windup_ticks:int
    x:float
    y:float
    cooldown:int=0
    strike_at:int=-1
    dodge_ready:int=0
    guard_until:int=0
    guard_ready:int=0
    strike_range:float=0
    strike_power:int=0
    guard_count:int=0
    retreat_steps:int=0
    strafe_steps:int=0
    zone_strikes:int=0


def simulate(seed:int,order:str):
    if order not in ORDERS:raise ValueError(order)
    rnd=seed&2147483647 or 1
    starts=[]
    for _ in range(2):
        rnd=(rnd*1103515245+12345)&2147483647
        starts.append(264.+rnd%59-29)
    u=[Fighter(0,85,85,12,57,78,11,3,250,starts[0],strike_range=78,strike_power=12),
       Fighter(1,94,94,11,43,85,13,4,710,starts[1],strike_range=85,strike_power=11)]
    hit=miss=0; digest=7; winners={}
    trace_actions={a:0 for a in ['APPROACH','RETREAT','STRAFE','DODGE','GUARD','ATTACK','CIRCLE','WINDUP']}
    for tick in range(1,LIMIT+1):
        for me in u:me.cooldown=max(0,me.cooldown-1)
        intents=[]
        for i,me in enumerate(u):
            foe=u[1-i]
            if me.strike_at>=0:
                intents.append('WINDUP');continue
            dist=hypot(me.x-foe.x,me.y-foe.y)
            tele=foe.strike_at>=tick
            ready=me.cooldown<=0
            scores=dict(APPROACH=-100.,RETREAT=-100.,STRAFE=-100.,ATTACK=-100.,GUARD=-100.,DODGE=-100.,CIRCLE=10.)
            if i==0 and order=='KEEP_DISTANCE':
                if dist<ZONE_MIN:
                    scores['RETREAT']=122. if dist<95. else 116.
                    if tele and tick>=me.dodge_ready and dist<foe.reach+20:scores['DODGE']=128.
                elif dist>ZONE_MAX:
                    scores['APPROACH']=96.
                else:
                    scores['STRAFE']=48.
                    if ready and dist<=ZONE_REACH:scores['ATTACK']=113.
            else:
                if dist>me.reach-6:scores['APPROACH']=80.+min(8.,dist/95.)
                elif ready:scores['ATTACK']=110.
                else:scores['CIRCLE']=30.
                if tele and dist<foe.reach+12:
                    if tick>=me.dodge_ready and me.hp*2<me.max_hp:scores['DODGE']=115.
                    elif me.guard_until<tick and tick>=me.guard_ready and (i==1 or order=='DEFENSIVE'):
                        scores['GUARD']=107. if i==1 else 118.
                if i==0:
                    if order=='AGGRESSIVE':
                        scores['ATTACK']+=15. if ready and scores['ATTACK']>0 else 0.
                        scores['GUARD']=-100.
                    elif order=='DEFENSIVE' and scores['GUARD']>0:scores['GUARD']+=5.
            priority=['DODGE','RETREAT','ATTACK','GUARD','APPROACH','STRAFE','CIRCLE']
            intents.append(max(priority,key=lambda a:scores[a]))
        for i,me in enumerate(u):
            foe=u[1-i];a=intents[i];trace_actions[a]+=1
            dx,dy=foe.x-me.x,foe.y-me.y
            dist=hypot(dx,dy);dx,dy=(dx/dist,dy/dist) if dist>.001 else (1.,0.)
            if a=='APPROACH':me.x+=dx*me.speed*.1;me.y+=dy*me.speed*.1
            elif a=='RETREAT':
                nx=max(85.,min(875.,me.x-dx*me.speed*.1*1.05))
                ny=max(145.,min(373.,me.y-dy*me.speed*.1*1.05))
                if hypot(nx-me.x,ny-me.y)<.5:nx=me.x-dy*me.speed*.1;ny=me.y+dx*me.speed*.1
                me.x=nx;me.y=ny;me.retreat_steps+=1
            elif a=='STRAFE':
                sign=1 if (tick//35)%2==0 else -1
                me.x-=dy*sign*me.speed*.1*.65;me.y+=dx*sign*me.speed*.1*.65;me.strafe_steps+=1
            elif a=='DODGE':
                me.x-=dx*me.speed*.1*2.1;me.y-=dy*me.speed*.1*2.1;me.dodge_ready=tick+22
            elif a=='GUARD':
                me.guard_until=tick+4;me.guard_ready=tick+GUARD_RECHARGE;me.guard_count+=1
            elif a=='CIRCLE':me.x-=dy*me.speed*.1*.12;me.y+=dx*me.speed*.1*.12
            elif a=='ATTACK':
                zone=i==0 and order=='KEEP_DISTANCE'
                me.strike_range=ZONE_REACH if zone else me.reach
                me.strike_power=ZONE_POWER if zone else me.power
                me.strike_at=tick+(ZONE_WINDUP if zone else me.windup_ticks)
                me.cooldown=ZONE_COOLDOWN if zone else (max(5,me.cooldown_ticks-2) if i==0 and order=='AGGRESSIVE' else me.cooldown_ticks)
                if zone:me.zone_strikes+=1
            me.x=min(max(me.x,85.),875.);me.y=min(max(me.y,145.),373.)
        planned=[]
        for i,me in enumerate(u):
            if me.strike_at!=tick:continue
            foe=u[1-i]
            d=hypot(me.x-foe.x,me.y-foe.y)
            guarded=foe.guard_until>=tick
            dmg=max(1,me.strike_power//2) if guarded else me.strike_power
            planned.append((i,1-i,d<=me.strike_range+12,dmg))
            me.strike_at=-1
        for i,j,landed,dmg in planned:
            if landed:u[j].hp=max(0,u[j].hp-dmg);hit+=1
            else:miss+=1
        stamp=tick
        for f in u:stamp+=f.hp*103+int(f.x*10)*11+int(f.y*10)*7
        digest=(digest*31+stamp)%2147483647
        a,b=u[0].hp,u[1].hp
        if a<=0 or b<=0 or tick>=LIMIT:
            if a<=0 and b<=0:win=2
            elif a<=0:win=1
            elif b<=0:win=0
            elif abs(a/85-b/94)<1e-4:win=2
            else:win=0 if a/85>b/94 else 1
            break
    return dict(seed=seed,order=order,winner=win,tick=tick,hp=[u[0].hp,u[1].hp],hits=hit,misses=miss,digest=digest,
                retreat=u[0].retreat_steps,strafe=u[0].strafe_steps,ranged=u[0].zone_strikes,guards=u[0].guard_count,actions=trace_actions)

if __name__=='__main__':
    a=argparse.ArgumentParser();a.add_argument('--seed',type=int,default=20261017);a.add_argument('--order',choices=ORDERS,default='KEEP_DISTANCE');o=a.parse_args()
    print(json.dumps(simulate(o.seed,o.order),indent=2))
